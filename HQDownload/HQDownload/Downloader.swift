//
//  Downloader.swift
//  HQDownload
//
//  Created by HonQi on 2018/3/27.
//  Copyright © 2018年 HonQi Indie. All rights reserved.
//

import HQFoundation

public final class Downloader: Operation, Eventable {
    func subscribe(url: URL, _ events: DownloadClosure...) -> UInt64 {
        <#code#>
    }
    
    func unsubscribe(_ key: UInt64) {
        <#code#>
    }
    

    /// Configuator
    private var options: OptionsInfo = [.handleCookies, .useUrlCache]
    private var backgroundTaskId: UIBackgroundTaskIdentifier?
    
    /// Save data to file queue
    private let source: URL
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
    
    
    /// Opertion properties
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
    
    public init(_ infos: OptionsInfo, session: URLSession? = nil) {
        source = infos.sourceUrl!
        super.init()
        options += infos
        outerSession = session
    }
    
    public convenience init(url: URL) {
        self.init([.sourceUrl(url)])
    }
    
    public override func start() {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        guard !isCancelled else {
            trigger(source, .error(.cancel("Operator state is cancelled!")))
            _finished = true
            return
        }
        
        // Register background task
        let app = UIApplication.shared
        if (options.taskInBackground) {
            backgroundTaskId = app.beginBackgroundTask(expirationHandler: { [weak self] in
                guard let wSelf = self else { return }
                wSelf.cancel()
                app.endBackgroundTask(wSelf.backgroundTaskId!)
                wSelf.backgroundTaskId = UIBackgroundTaskIdentifier(rawValue: convertFromUIBackgroundTaskIdentifier(UIBackgroundTaskIdentifier.invalid))
            })
        }
        
        guard let request = URLRequest.hq.create(options) else {
            // completion
            trigger(source, .error(.cancel("Source : \(source) init request failure!")))
            cancel()
            return
        }
        dataTask = session.dataTask(with: request)
        dataTask?.priority = options.priority
        
        dataTask!.resume()
        _executing = true
        
        // Cancel background task
        if let taskId = backgroundTaskId, taskId != UIBackgroundTaskIdentifier.invalid {
            app.endBackgroundTask(taskId)
            backgroundTaskId = UIBackgroundTaskIdentifier(rawValue: convertFromUIBackgroundTaskIdentifier(UIBackgroundTaskIdentifier.invalid))
        }
    }
    
    public override func cancel() {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        if isFinished { return }
        super.cancel()
        closeStream()
        
        if let task = dataTask {
            task.cancel()
            if isExecuting { _executing = false }
            if !isFinished { _finished = true }
        }
    }
    
    deinit {
        closeStream()
        eventsMap.removeAll()
        if outerSession == nil {
            innerSession.invalidateAndCancel()
        }
    }
}

extension Operator {
    private func openStream(fileName: String) {
        guard stream == nil else { return }
        
        let dire = options.cacheDirectory
        if !FileManager.default.fileExists(atPath: dire.path) {
            do {
                try FileManager.default.createDirectory(at: dire, withIntermediateDirectories: true, attributes: nil)
            }
            catch let err {
                trigger(source, .error(.cancel(err.localizedDescription)))
                cancel()
                return
            }
        }
        
        guard let s = OutputStream(url: dire.appendingPathComponent(fileName), append: true) else {
            trigger(source, .error(.cancel("Output stream open failure!")))
            cancel()
            return
        }
        stream = s
        stream?.open()
    }
    
    private func done() {
        _finished = true
        _executing = false
        closeStream()
    }
    
    private func closeStream() {
        stream?.close()
        stream?.remove(from: RunLoop.current, forMode: RunLoop.Mode.default)
        stream = nil
    }
}


// MARK: - Session Delegate callback
extension Operator {
    func receive(response: URLResponse) -> URLSession.ResponseDisposition {
        let statusCode = (response as? HTTPURLResponse)?.statusCode
        guard let code = statusCode,
            (200..<400).contains(code) else {
                trigger(source, .error(.statusCodeInvalid(statusCode ?? 404)))
                return .cancel
        }
        
        if code == 304,
            let request = dataTask?.originalRequest,
            (session.configuration.urlCache ?? URLCache.shared).cachedResponse(for: request)?.data == nil
        {
            // '304 Not Modified' is an exceptional one. It should be treated as cancelled if no cache data
            // URLSession current behavior will return 200 status code when the server respond 304 and URLCache hit. But this is not a standard behavior and we just add a check
            trigger(source, .error(.noCache304))
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
        trigger(source, .start(name, size))
        return .allow
    }
    
    func receive(data: Data) {
        if let stream = stream, stream.hasSpaceAvailable {
            stream.write([UInt8](data), maxLength: data.count)
            progress?.completedUnitCount += Int64(data.count)
            trigger(source, .data(data))
            trigger(source, .progress(progress!))
        }
        else {
            trigger(source, .error(.cancel("Disk no enough space!")))
            cancel()
        }
    }
    
    func complete(error: Error?) {
        guard let err = error else {
            done()
            trigger(source, .completed(options.cacheDirectory.appendingPathComponent(options.fileName!)))
            return
        }
        
        // Task cancel, did not retry
        guard (err as NSError).code != -999 else {
            trigger(source, .error(.cancel("Task is cancelled!")))
            return
        }
        
        if options.retryCount <= 0 {
            trigger(source, .error(.error(err)))
            done()
        }
        else {
            // TODO: retry
            
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
            // TODO: allow trust host
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

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIBackgroundTaskIdentifier(_ input: UIBackgroundTaskIdentifier) -> Int {
	return input.rawValue
}
