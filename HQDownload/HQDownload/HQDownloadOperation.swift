//
//  HQDownloadOperation.swift
//  HQDownload
//
//  Created by qihuang on 2018/3/27.
//  Copyright © 2018年 com.personal.HQ. All rights reserved.
//

import HQFoundation


public final class HQDownloadOperation: Operation {
    // MARK: - network relevant
    
    /// The credential used for authentication challenges in `-URLSession:task:didReceiveChallenge:completionHandler:`.
    /// This will be overridden by any shared credentials that exist for the username or password of the request URL, if present.
    public var credential: URLCredential?
    
    public var sessionConfig: URLSessionConfiguration {
        return session.configuration
    }
    
    /// The request used by the operation's task
    public private(set) var request: URLRequest!
    
    public private(set) var dataTask: URLSessionTask?
    
    public private(set) var response: URLResponse?
    
    public private(set) var options: HQDownloadOptions!
    
    public private(set) var progress: Progress = {
        let progress = Progress()
        progress.isPausable = true
        progress.isCancellable = true
        
        return progress
    }()
    
    /// callback dictionary list
    public private(set) var callbackLists = [CFAbsoluteTime: HQDownloadCallback]()
    
    // MARK: - opertion property
    
    open override var isConcurrent: Bool { return true }
    
    open override var isAsynchronous: Bool { return true }
    
    
    // MARK: - private
    
    private var _executing = false {
        willSet {
            willChangeValue(forKey: "isExecuting")
        }
        didSet {
            didChangeValue(forKey: "isExecuting")
        }
    }
    private var _finished = false {
        willSet {
            willChangeValue(forKey: "isFinished")
        }
        didSet {
            didChangeValue(forKey: "isFinished")
        }
    }
    
    /// This is weak because it is injected by whoever manages this session. If this gets nil-ed out, we won't be able to run the task associated with this operation
    private weak var injectSession: URLSession?
    
    /// This is set if we're using not using an injected NSURLSession. We're responsible of invalidating this one
    private lazy var taskSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15.0
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()
    
    private var session: URLSession { return injectSession ?? taskSession }
    private var callbacksLock = DispatchSemaphore(value: 1)
    private var backgroundTaskId: UIBackgroundTaskIdentifier?
    
    
    private var targetPath: String!
    private var stream: OutputStream!
    
    /// Init download operation
    ///
    /// - Parameters:
    ///   - request: download request
    ///   - path: Stored download data file or directory
    ///           if is breadpoint continue download, set file path
    ///           if is new download, set save directory
    public init(request: URLRequest, options: HQDownloadOptions, path: String, session: URLSession? = nil) {
        super.init()
        
        self.request = request
        configRequest(obtainTargetPath(path))
        openStream()
        self.options = options
        self.injectSession = session
    }
}

// MARK: - Override function
public extension HQDownloadOperation {
    public override func cancel() {
        if isFinished { return }
        super.cancel()
        if let task = dataTask {
            task.cancel()
            // add judge to avoid trigger KVO
            if isExecuting { _executing = false }
            if !isFinished { _finished = true }
        }
        reset()
    }
    
    public override func start() {

        objc_sync_enter(self)
        
        if isCancelled {
            _finished = true
            reset()
            return
        }
        
        // background task
        addBackgroundTask()
        
        // add task
        dataTask = session.dataTask(with: request!)
        _executing = true
        
        objc_sync_exit(self)
        
        configTask()
        
        // if task finished, remove background task
        removeBackgroundTask()
    }
}

// MARK: - Public function
extension HQDownloadOperation {
    public func addCallback(_ callback: @escaping HQDownloadCallback) -> Any {
        return HQDispatchLock.semaphore(callbacksLock) { () -> CFAbsoluteTime in
            let time = CFAbsoluteTimeGetCurrent()
            callbackLists[time] = callback
            return time
        }
    }
    
    public func remove(_ token: Any){
        guard let time = token as? CFAbsoluteTime, callbackLists.keys.contains(time) else { return }
        HQDispatchLock.semaphore(callbacksLock) {
            callbackLists.removeValue(forKey: time)
            if callbackLists.isEmpty { cancel() }
        }
    }
}


// MARK: - Operation task step
private extension HQDownloadOperation {
    func addBackgroundTask() {
        if !options.contains(.continueInBackground) { return }
        backgroundTaskId = UIApplication.shared.beginBackgroundTask { [weak self] in
            if let wSelf = self {
                wSelf.cancel()
                UIApplication.shared.endBackgroundTask(wSelf.backgroundTaskId!)
                wSelf.backgroundTaskId = UIBackgroundTaskInvalid
            }
        }
    }
    
    func removeBackgroundTask() {
        // set end background task
        if let backgroundTaskId = backgroundTaskId, backgroundTaskId != UIBackgroundTaskInvalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskId)
            self.backgroundTaskId = UIBackgroundTaskInvalid
        }
    }
    
    func configTask() {
        guard let task = dataTask else { fatalError("URLSessionTask not initialize success") }
        
        if task.responds(to: #selector(setter: URLSessionTask.priority)) {
            if options.contains(.highPriority) {
                task.priority = URLSessionTask.highPriority
            }
            else if options.contains(.lowPriority) {
                task.priority = URLSessionTask.lowPriority
            }
        }
        
        task.resume()
        invokeCallbackClosure()
    }
    
    
    /// If file is existed, return file current size, othrewise return 0
    func obtainTargetPath(_ path: String) -> Int64 {
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory), !isDirectory.boolValue {
            targetPath = path
            let attr = try? FileManager.default.attributesOfItem(atPath: path)
            let size = (attr?[.size] as? Int64) ?? 0
            return size
        }
        
        let name = request.url!.lastPathComponent.utf8
        targetPath = path.last == "/" ? "\(path)\(name)" : "\(path)/\(name)"
        return 0
    }
    
    func configRequest(_ size: Int64) {
        request.addValue(String(format: "bytes=%llu-", size), forHTTPHeaderField: "Range")
    }
    
    func openStream() {
        stream = OutputStream(toFileAtPath: targetPath, append: true)
        stream.schedule(in: RunLoop.current, forMode: .defaultRunLoopMode)
        stream.open()
    }
    
    func closeStream() {
        stream.close()
        stream.remove(from: RunLoop.current, forMode: .defaultRunLoopMode)
    }
}


// MARK: - State & Helper function
private extension HQDownloadOperation {
    func invokeCallbackClosure(_ error: Error? = nil, _ finished: Bool = false) {
        let _ = callbackLists.values.compactMap { (callback) -> Void in
//            (_ url: URL, _ progress: Progress, _ dataPath: String?, _ error: Error, _ finished: Bool) -> Void
            if let url = request.url {
                callback(url, progress, targetPath, error, finished)
            }
        }
    }
    
    func reset() {
        HQDispatchLock.semaphore(callbacksLock) {
            callbackLists.removeAll()
            callbacksLock.signal()
        }
        dataTask = nil
        session.invalidateAndCancel()
        closeStream()
    }
    
    func done() {
        _finished = true
        _executing = false
        reset()
    }
}


// MARK: - HQDownloadOperationProtocol
extension HQDownloadOperation: URLSessionDataDelegate {
    
    /// datatask first receive response
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        
        var disposition = URLSession.ResponseDisposition.allow
        self.response = response
        
        var statusCode = 200
        if let rp = response as? HTTPURLResponse {
            statusCode = rp.statusCode
        }
        
        var valid = statusCode < 400
        
        //'304 Not Modified' is an exceptional one. It should be treated as cancelled if no cache data  
        //URLSession current behavior will return 200 status code when the server respond 304 and URLCache hit. But this is not a standard behavior and we just add a check
        var urlCache: URLCache! = session.configuration.urlCache
        if urlCache == nil { urlCache = URLCache.shared }
        
        if (statusCode == 304 && urlCache.cachedResponse(for: request)?.data == nil) {
            valid = false
        }
        
        if valid {
            progress.completedUnitCount = 0
            progress.totalUnitCount = response.expectedContentLength
            invokeCallbackClosure()
        }
        else {
            // if not valid, cancel request. the session will call complete delegate function, so do not need invoke complete callback
            disposition = .cancel
        }
        
        completionHandler(disposition)
    }
    
    
    /// request receive data callback
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        stream.write([UInt8](data), maxLength: data.count)
        
        progress.completedUnitCount += Int64(data.count)
        invokeCallbackClosure()
    }

    
    /// task completed
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        objc_sync_enter(self)
        dataTask = nil
        objc_sync_exit(self)
        
        /// error is nil means task complete, otherwise is error interrupt request
        invokeCallbackClosure(error, true)
        done()
    }
    
    
    /// task begin and authentication
    public func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        var disposition = URLSession.AuthChallengeDisposition.performDefaultHandling
        var inlineCred: URLCredential? = nil
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust { // method is trust server
            if options.contains(.allowInvalidSSLCert) {
                disposition = .useCredential
                // when authenticationMethod is ServerTrust, must be not nil
                inlineCred = URLCredential(trust: challenge.protectionSpace.serverTrust!)
            }
        }
        else {
            if challenge.previousFailureCount == 0 { // previos never failure
                if let cred = self.credential { // use custom credential
                    inlineCred = cred
                    disposition = .useCredential
                }
                else { // cancel authentication
                    disposition = .cancelAuthenticationChallenge
                }
            }
            else { // previos failure
                disposition = .cancelAuthenticationChallenge
            }
        }
        
        completionHandler(disposition, inlineCred)
    }
    
    /// Handle session cache
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse, completionHandler: @escaping (CachedURLResponse?) -> Void) {
        
        // remove response prevent use cache
        completionHandler(options.contains(.useUrlCache) ? proposedResponse : nil)
    }
}
