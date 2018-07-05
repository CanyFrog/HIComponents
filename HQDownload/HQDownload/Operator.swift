//
//  Downloader.swift
//  HQDownload
//
//  Created by qihuang on 2018/3/27.
//  Copyright © 2018年 com.personal.HQ. All rights reserved.
//

import HQFoundation
import HQCache

public final class Operator: Operation {
    typealias CallBack = (Event)->Void
    private lazy var callbackMap = InnerKeyMap<CallBack>()
    private lazy var callbackLock = DispatchSemaphore(value: 1)
    
    /// Configuator
    private var options: OptionsInfo = [.handleCookies, .useUrlCache]
    private var backgroundTaskId: UIBackgroundTaskIdentifier?
    
    /// Save data to file queue
    private var stream: OutputStream?
    
    private var progress: Progress?
    
    /// Session
    private weak var outerSession: URLSession?
    private lazy var innerSession: URLSession = {
        let dele = Delegate()
        dele.operators.hq.addObject(self)
        let se = URLSession.hq.create(options, delegate: dele)
        return se
    }()
    private var session: URLSession { return outerSession ?? innerSession }
    var dataTask: URLSessionDataTask?
    
    // MARK: - Opertion properties
    public override var isConcurrent: Bool { return true }
    public override var isAsynchronous: Bool { return true }
    public override var isExecuting: Bool { return _executing }
    private var _executing = false {
        willSet { willChangeValue(forKey: "isExecuting") }
        didSet { didChangeValue(forKey: "isExecuting") }
    }

    public override var isFinished: Bool { return _finished }
    private var _finished = false {
        willSet { willChangeValue(forKey: "isFinished") }
        didSet { didChangeValue(forKey: "isFinished") }
    }
    
    public init(options: OptionsInfo, session: URLSession? = nil) {
        super.init()
        self.options = options
        outerSession = session
    }
    
    public override func start() {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        guard !isCancelled else { _finished = true; return }
        
        // Register background task
        let app = UIApplication.shared
        if (options.taskInBackground) {
            backgroundTaskId = app.beginBackgroundTask(expirationHandler: { [weak self] in
                guard let wSelf = self else { return }
                wSelf.cancel()
                app.endBackgroundTask(wSelf.backgroundTaskId!)
                wSelf.backgroundTaskId = UIBackgroundTaskInvalid
            })
        }
        
        guard let request = URLRequest.hq.create(options) else {
            // completion
            execute(.error(.cancel("Init request failure!")))
            cancel()
            return
        }
        dataTask = session.dataTask(with: request)
        dataTask?.priority = options.priority
        
        dataTask!.resume()
        _executing = true
        
        // Cancel background task
        if let taskId = backgroundTaskId, taskId != UIBackgroundTaskInvalid {
            app.endBackgroundTask(taskId)
            backgroundTaskId = UIBackgroundTaskInvalid
        }
    }
    
    public override func cancel() {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        if isFinished { return }
        super.cancel()
        
        if let task = dataTask {
            task.cancel()
            if isExecuting { _executing = false }
            if !isFinished { _finished = true }
        }
        reset()
    }
    
    deinit {
        Lock.semaphore(callbackLock) { callbackMap.removeAll() }
        if outerSession == nil {
            innerSession.invalidateAndCancel()
        }
    }
}



// MARK: - Public functions
extension Operator {
    @discardableResult
    public func subscribe(start: ((String, Int64)->Void)? = nil,
                       progress: ((Progress)->Void)? = nil,
                       data: ((Data)->Void)? = nil,
                       completed: ((URL)->Void)? = nil,
                       error: ((DownloadError)->Void)? = nil) -> UInt64 {
        let callback = { (_ event: Event) in
            switch event {
            case .start(let value):
                start?(value.0, value.1)
            case .progress(let rate):
                progress?(rate)
            case .newData(let d):
                data?(d)
            case .completed(let url):
                completed?(url)
            case .error(let err):
                error?(err)
            }
        }
        
        return Lock.semaphore(callbackLock) { () -> UInt64 in
            return callbackMap.insert(callback)
        }
    }
    
    public func unsubscribe(_ key: UInt64) {
        Lock.semaphore(callbackLock) {
            callbackMap.remove(key)
        }
        if callbackMap.count == 0 { cancel() }
    }
}

extension Operator {
    private func openStream(fileName: String) {
        guard stream == nil else { return }
        
        let dire = options.cacheDirectory
//        if !FileManager.default.fileExists(atPath: dire.path) {
//            do {
//                try FileManager.default.createDirectory(at: dire, withIntermediateDirectories: true, attributes: nil)
//            }
//            catch let err {
//                execute(.error(.cancel(err.localizedDescription)))
//                cancel()
//                return
//            }
//        }
        
        guard let s = OutputStream(url: dire.appendingPathComponent(fileName), append: true) else {
            execute(.error(.cancel("Output stream open failure!")))
            cancel()
            return
        }
        stream = s
        stream?.open()
    }

    private func execute(_ event: Event) {
//        Lock.semaphore(callbackLock) {
            callbackMap.forEach { $0(event) }
//        }
    }
    
    private func done() {
        _finished = true
        _executing = false
        reset()
    }
    
    private func reset() {
        stream?.close()
        stream?.remove(from: RunLoop.current, forMode: .defaultRunLoopMode)
        stream = nil
        dataTask = nil
    }
}


// MARK: - Session Delegate callback
extension Operator {
    func receive(response: URLResponse) -> URLSession.ResponseDisposition {
        let statusCode = (response as? HTTPURLResponse)?.statusCode
        guard let code = statusCode,
            (200..<400).contains(code) else {
                execute(.error(.statusCodeInvalid(statusCode ?? 404)))
                return .cancel
        }
        
        if code == 304,
            let request = dataTask?.originalRequest,
            (session.configuration.urlCache ?? URLCache.shared).cachedResponse(for: request)?.data == nil
        {
            // '304 Not Modified' is an exceptional one. It should be treated as cancelled if no cache data
            // URLSession current behavior will return 200 status code when the server respond 304 and URLCache hit. But this is not a standard behavior and we just add a check
            execute(.error(.noCache304))
            return .cancel
        }
        
        let size = response.expectedContentLength
        
        var name: String! = options.fileName
        if name == nil {
            name = (response.suggestedFilename ?? dataTask?.originalRequest?.url?.lastPathComponent) ?? UUID().uuidString
            options.append(.fileName(name))
        }
        
        openStream(fileName: name)
        progress = Progress(totalUnitCount: size)
        execute(.start(name, size))
        return .allow
    }
    
    func receive(data: Data) {
        if let stream = stream, stream.hasSpaceAvailable {
            stream.write([UInt8](data), maxLength: data.count)
            progress?.completedUnitCount += Int64(data.count)
            execute(.newData(data))
            execute(.progress(progress!))
        }
        else {
            execute(.error(.cancel("Disk no enough space!")))
            cancel() // If not enough space, cancel task
        }
    }
    
    func complete(error: Error?) {
        guard let err = error else {
            done()
            execute(.completed(options.cacheDirectory.appendingPathComponent(options.fileName!)))
            return
        }
        
        // Task cancel, did not retry
        guard (err as NSError).code != -999 else { return }
        
        if options.retryCount <= 0 {
            execute(.error(.error(err)))
            done()
        }
        else {
            // retry
            let count = options.retryCount
            options = options.removeAllMatchesIgnoringAssociatedValue(.retryCount(0))
            options.append(.retryCount(count-1))
        }
    }
    
    func receive(challenge: URLAuthenticationChallenge) -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust { // method is trust server
            if options.allowInvalidSSLCert {
                // when authenticationMethod is ServerTrust, must be not nil
                return (.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
            }
            // or trust host
        }
        
        if let cred = options.urlCredential, challenge.previousFailureCount == 0 { // previos never failure
            return (.useCredential, cred)
        }
        
        return (.performDefaultHandling, nil)
    }
    
    func cachedResponse() -> Bool {
        return options.useUrlCache
    }
}
