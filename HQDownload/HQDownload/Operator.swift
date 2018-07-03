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
    typealias CallBack = (OperatorEvent)->Void
    private lazy var callbacks = InnerKeyMap<CallBack>()
    private lazy var callbackLock = DispatchSemaphore(value: 1)
    
    /// Configuator
    private var options: OptionsInfo = [.handleCookies, .useUrlCache]
    private var backgroundTaskId: UIBackgroundTaskIdentifier?
    
    /// Save data to file queue
    private lazy var queue: DispatchQueue = DispatchQueue(label: "personal.download.OutputStreamQueue")
    private var stream: OutputStream?
    
    /// Session
    private weak var outerSession: URLSession?
    private lazy var innerSession: URLSession = URLSession(configuration: .default)
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
        outerSession = session
        self.options = options
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
    
    private func done() {
        _finished = true
        _executing = false
        reset()
    }
    
    private func reset() {
        Lock.semaphore(callbackLock) { callbacks.removeAll() }
        stream?.remove(from: RunLoop.current, forMode: .defaultRunLoopMode)
        stream = nil
        dataTask = nil
    }
    
    deinit {
        if outerSession == nil {
            innerSession.invalidateAndCancel()
        }
    }
}

extension Operator {
    func receive(response: URLResponse) -> URLSession.ResponseDisposition {
        guard let code = (response as? HTTPURLResponse)?.statusCode,
            (200..<400).contains(code) else {
            return .cancel
        }
        
        if code == 304,
            let request = dataTask?.originalRequest,
            (session.configuration.urlCache ?? URLCache.shared).cachedResponse(for: request)?.data == nil
            {
            //'304 Not Modified' is an exceptional one. It should be treated as cancelled if no cache data
            //URLSession current behavior will return 200 status code when the server respond 304 and URLCache hit. But this is not a standard behavior and we just add a check
            return .cancel
        }
        
        let size = response.expectedContentLength
        let name = options.fileName ?? response.suggestedFilename!
        openStream(fileName: name)
        execute(.start((name, size)))
//        execute(.progress(<#T##Progress#>))
        return .allow
    }
    
    func receive(data: Data) {
        if let stream = stream, stream.hasSpaceAvailable {
            queue.async {
                stream.write([UInt8](data), maxLength: data.count)
            }
            execute(.newData(data))
//            execute(.progress(<#T##Progress#>))
        }
        else {
            cancel() // If not enough space, cancel task
//            execute(.error(<#T##Error#>))
        }
    }
    
    func complete(error: Error?) {
        guard let err = error else {
//            execute(.completed(<#T##URL#>))
            return
        }
        
//        if (err as NSError).code == -999 {
//            done() // Task cancel, did not retry
//            if let stream = stream, !stream.hasSpaceAvailable { invokeFinished(HQDownloadError.notEnoughSpace) } // No enough space cancel
//            else { invokeFinished(HQDownloadError.taskError(err)) }
//            return
//        }
//
//        if config.autoRetryCount <= 0 {
//            done()
//            invokeFinished(HQDownloadError.taskError(err))
//        }
//        else {
//            initializeRequest()
//            start()
//            config.autoRetryCount -= 1
//        }
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


extension Operator {
    func openStream(fileName: String) {
        guard stream == nil else { return }
        
        let directory = options.cacheDirectory
        if !FileManager.default.fileExists(atPath: directory.path) {
            do {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
            }
            catch {
                cancel()
                return
            }
        }
        if let stream = OutputStream(url: directory.appendingPathComponent(fileName), append: true) {
            stream.schedule(in: RunLoop.current, forMode: .defaultRunLoopMode)
        }
        // error
    }
    
    public func listen(start: ((String, Int64)->Void)? = nil,
                       progress: ((Progress)->Void)? = nil,
                       data: ((Data)->Void)? = nil,
                       completed: ((URL)->Void)? = nil,
                       error: ((Error)->Void)? = nil) -> UInt64 {
        let callback = { (_ event: OperatorEvent) in
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
            return callbacks.insert(callback)
        }
    }
}

extension Operator: Executable {
    public func execute(_ event: OperatorEvent) {
        Lock.semaphore(callbackLock) {
            callbacks.forEach { $0(event) }
        }
    }
}
