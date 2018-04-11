//
//  HQDownloadOperation.swift
//  HQDownload
//
//  Created by qihuang on 2018/3/27.
//  Copyright © 2018年 com.personal.HQ. All rights reserved.
//

// TODO: Auto retry

import HQFoundation

public typealias HQDownloadCallback = (_ url: URL, _ progress: Progress, _ dataPath: URL, _ error: Error?, _ finished: Bool) -> Void

public final class HQDownloadOperation: Operation {
    // MARK: - network relevant
    public var sessionConfig: URLSessionConfiguration {
        return session.configuration
    }
    
    /// The request used by the operation's task
    public private(set) var requestWrapper: HQDownloadRequest!
    
    public private(set) var dataTask: URLSessionTask?
    
    public private(set) var response: URLResponse?
    
    public var priority: Float = URLSessionTask.defaultPriority
    
    public private(set) var progress: Progress = {
        let progress = Progress()
        progress.isPausable = true
        progress.isCancellable = true
        
        return progress
    }()
    
    /// callback dictionary list
    private var callbackLists = [CFAbsoluteTime: HQDownloadCallback]()
    
    // MARK: - Opertion property
    
    open override var isConcurrent: Bool { return true }
    
    open override var isAsynchronous: Bool { return true }
    
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
            completionBlock?()
        }
    }
    
    // MARK: - Private
    
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
    
    private var backgroundTask: Bool = true
    private var backgroundTaskId: UIBackgroundTaskIdentifier?
    
    
    private var destinationPath: URL!
    private var stream: OutputStream!
    
    public init(request: HQDownloadRequest, targetPath: String, session: URLSession? = nil, background: Bool = true) {
        super.init()
        
        requestWrapper = request
        if let range = requestWrapper.downloadRange {
            progress.completedUnitCount = range.0 ?? 0
            progress.totalUnitCount = range.1 ?? Int64.max
        }
        destinationPath = URL(fileURLWithPath: targetPath)
        openStream()
        injectSession = session
        backgroundTask = background
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
        
        // register background task
        if backgroundTask {
            backgroundTaskId = UIApplication.shared.beginBackgroundTask { [weak self] in
                // task finished block
                if let wSelf = self {
                    wSelf.cancel()
                    UIApplication.shared.endBackgroundTask(wSelf.backgroundTaskId!)
                    wSelf.backgroundTaskId = UIBackgroundTaskInvalid
                }
            }
        }
        
        // add task
        dataTask = session.dataTask(with: requestWrapper.request)
        dataTask?.priority = priority
        _executing = true
        
        objc_sync_exit(self)
        
        // start task
        dataTask?.resume()
//        invokeCallbackClosure()
        
        // if task finished, remove background task
        if let backgroundTaskId = backgroundTaskId, backgroundTaskId != UIBackgroundTaskInvalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskId)
            self.backgroundTaskId = UIBackgroundTaskInvalid
        }
    }
}

// MARK: - Public function
extension HQDownloadOperation {
    @discardableResult
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
//            if callbackLists.isEmpty { cancel() }
        }
    }
}


// MARK: - State & Helper function
private extension HQDownloadOperation {
    func invokeCallbackClosure(_ error: Error? = nil, _ finished: Bool = false) {
        callbackLists.values.forEach { (callback) in
//            (_ url: URL, _ progress: Progress, _ dataPath: String?, _ error: Error, _ finished: Bool) -> Void
            if let url = requestWrapper.request.url {
                callback(url, progress, destinationPath, error, finished)
            }
        }
    }
    
    func reset() {
        HQDispatchLock.semaphore(callbacksLock) {
            callbackLists.removeAll()
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
    
    func openStream() {
        stream = OutputStream(url: destinationPath, append: true)
        stream.schedule(in: RunLoop.current, forMode: .defaultRunLoopMode)
        stream.open()
    }
    
    func closeStream() {
        stream.close()
        stream.remove(from: RunLoop.current, forMode: .defaultRunLoopMode)
    }
}


// MARK: - HQDownloadOperationProtocol
extension HQDownloadOperation: URLSessionDataDelegate {
    
    /// datatask first receive response
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        
        progress.totalUnitCount = response.expectedContentLength + progress.completedUnitCount  // if continue download, need add current download size
        
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
        
        if (statusCode == 304 && urlCache.cachedResponse(for: requestWrapper.request)?.data == nil) {
            valid = false
        }
        
        if valid {
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
        
        if stream.hasSpaceAvailable {
            stream.write([UInt8](data), maxLength: data.count)
            progress.completedUnitCount += Int64(data.count)
            invokeCallbackClosure()
        }
        else {
            invokeCallbackClosure(NSError(domain: "Download operation not has available space", code: -999, userInfo: nil), true)
            done()
        }
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
            if requestWrapper.allowInvalidSSLCert {
                disposition = .useCredential
                // when authenticationMethod is ServerTrust, must be not nil
                inlineCred = URLCredential(trust: challenge.protectionSpace.serverTrust!)
            }
        }
        else {
            if challenge.previousFailureCount == 0 { // previos never failure
                if let cred = requestWrapper.urlCredential { // use custom credential
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
        completionHandler(requestWrapper.useUrlCache ? proposedResponse : nil)
    }
}
