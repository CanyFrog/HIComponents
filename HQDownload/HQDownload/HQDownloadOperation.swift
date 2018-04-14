//
//  HQDownloadOperation.swift
//  HQDownload
//
//  Created by qihuang on 2018/3/27.
//  Copyright © 2018年 com.personal.HQ. All rights reserved.
//

// TODO: Auto retry

import HQFoundation

public final class HQDownloadOperation: Operation {
    // MARK: - network relevant
    public var sessionConfig: URLSessionConfiguration {
        return session.configuration
    }
    
    /// The request used by the operation's task
    public private(set) var ownRequest: HQDownloadRequest!
    
    public private(set) var dataTask: URLSessionTask?
    
    public private(set) var response: URLResponse?
    
    public var priority: Float = URLSessionTask.defaultPriority {
        didSet {
            dataTask?.priority = priority
        }
    }
    
    public private(set) var progress: HQDownloadProgress = {
        let progress = HQDownloadProgress()
        progress.isPausable = true
        progress.isCancellable = true
        
        return progress
    }()
    
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
    
    private var backgroundTaskId: UIBackgroundTaskIdentifier?
    
    private var stream: OutputStream!
    
    // MARK: - Call backs
    public typealias BeginClosure = (_ source: URL, _ target: URL, _ exceptSize: Int64) -> Void
    private var beginHandlerLock = DispatchSemaphore(value: 1)
    private var beginHandlers = [BeginClosure?]()
    
    public typealias FinishedClosure = (_ error: Error?)->Void
    private var finishedHandlerLock = DispatchSemaphore(value: 1)
    private var finishedHandlers = [FinishedClosure?]()
    
    public init(_ request: HQDownloadRequest, _ session: URLSession? = nil) {
        super.init()
        injectSession = session
        ownRequest = request
        if let range = ownRequest.downloadRange {
            progress.completedUnitCount = range.0 ?? 0
            progress.totalUnitCount = range.1 ?? Int64.max
        }
        progress.sourceURL = request.request.url
        progress.fileURL = request.fileUrl
        openStream()
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
        if ownRequest.background {
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
        dataTask = session.dataTask(with: ownRequest.request)
        dataTask?.priority = priority
        _executing = true
        
        objc_sync_exit(self)
        
        // start task
        dataTask?.resume()

        // if task finished, remove background task
        if let backgroundTaskId = backgroundTaskId, backgroundTaskId != UIBackgroundTaskInvalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskId)
            self.backgroundTaskId = UIBackgroundTaskInvalid
        }
    }
}

public extension HQDownloadOperation {
    @discardableResult
    public func begin(_ callback: BeginClosure?) -> HQDownloadOperation {
        if let callback = callback {
            HQDispatchLock.semaphore(beginHandlerLock) {
                beginHandlers.append(callback)
            }
        }
        return self
    }
    
    @discardableResult
    public func finished(_ callback: FinishedClosure?) -> HQDownloadOperation {
        if let callback = callback {
            HQDispatchLock.semaphore(finishedHandlerLock) {
                finishedHandlers.append(callback)
            }
        }
        return self
    }
}

// MARK: - State & Helper function
private extension HQDownloadOperation {
    func reset() {
        progress.cancel()
        session.invalidateAndCancel()
        closeStream()
        dataTask = nil
    }
    
    func done() {
        _finished = true
        _executing = false
        reset()
    }
    
    func openStream() {
        stream = OutputStream(url: ownRequest.fileUrl, append: true)
        stream.schedule(in: RunLoop.current, forMode: .defaultRunLoopMode)
        stream.open()
    }
    
    func closeStream() {
        stream.remove(from: RunLoop.current, forMode: .defaultRunLoopMode)
        stream.close()
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
        
        if (statusCode == 304 && urlCache.cachedResponse(for: ownRequest.request)?.data == nil) {
            valid = false
        }
        
        if !valid {
            // if not valid, cancel request. the session will call complete delegate function, so do not need invoke complete callback
            disposition = .cancel
        }
        else {
            if progress.completedUnitCount > 0 {
                progress.resume()
            }
            else {
                progress.start()
            }
            progress.totalUnitCount = response.expectedContentLength + progress.completedUnitCount  // if continue download, need add current download size
            
            beginHandlers.forEach { (obj) in
                if let begin = obj {
                    begin(ownRequest.request.url!, ownRequest.fileUrl, progress.totalUnitCount)
                }
            }
        }

        completionHandler(disposition)
    }
    
    
    /// request receive data callback
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        
        if stream.hasSpaceAvailable {
            stream.write([UInt8](data), maxLength: data.count)
            progress.completedUnitCount += Int64(data.count)
        }
        else {
            done()
            finishedHandlers.forEach { (obj) in
                if let finish = obj {
                    finish(nil)
                }
            }
        }
    }

    
    /// task completed
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        objc_sync_enter(self)
        dataTask = nil
        objc_sync_exit(self)
        
        /// error is nil means task complete, otherwise is error interrupt request
        if error != nil && ownRequest.retryCount > 0 {
            start() // restart
            ownRequest.retryCount -= 1
            progress.pause()
        }
        else {
            done()
            finishedHandlers.forEach { (obj) in
                if let finish = obj {
                    finish(error)
                }
            }
        }
    }
    
    
    /// task begin and authentication
    public func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        var disposition = URLSession.AuthChallengeDisposition.performDefaultHandling
        var inlineCred: URLCredential? = nil
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust { // method is trust server
            if ownRequest.allowInvalidSSLCert {
                disposition = .useCredential
                // when authenticationMethod is ServerTrust, must be not nil
                inlineCred = URLCredential(trust: challenge.protectionSpace.serverTrust!)
            }
        }
        else {
            if challenge.previousFailureCount == 0 { // previos never failure
                if let cred = ownRequest.urlCredential { // use custom credential
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
        completionHandler(ownRequest.useUrlCache ? proposedResponse : nil)
    }
}
