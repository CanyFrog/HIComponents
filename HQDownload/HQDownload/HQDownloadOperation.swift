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
    public private(set) var dataTask: URLSessionTask?
    
    public private(set) var response: URLResponse?
    
    
    /// The request used by the operation's task
    public private(set) var request: HQDownloadRequest!
    
    
    // MARK: - Opertion property
    
    open override var isConcurrent: Bool { return true }
    
    open override var isAsynchronous: Bool { return true }
    
    public override var isExecuting: Bool { return _executing }
    
    private var _executing = false {
        willSet {
            willChangeValue(forKey: "isExecuting")
        }
        didSet {
            didChangeValue(forKey: "isExecuting")
        }
    }
    
    public override var isFinished: Bool { return _finished }

    private var _finished = false {
        willSet {
            willChangeValue(forKey: "isFinished")
        }
        didSet {
            didChangeValue(forKey: "isFinished")
        }
    }
    
    
    // MARK: - Private
    
    /// This is weak because it is injected by whoever manages this session. If this gets nil-ed out, we won't be able to run the task associated with this operation
    private weak var injectSession: URLSession?
    
    /// This is set if we're using not using an injected NSURLSession. We're responsible of invalidating this one
    private var ownSession: URLSession?
    
    private var backgroundTaskId: UIBackgroundTaskIdentifier?
    
    private var stream: OutputStream?

    public init(request: HQDownloadRequest, session: URLSession? = nil) {
        super.init()
        injectSession = session
        self.request = request
    }
}

// MARK: - Override function
public extension HQDownloadOperation {
    public override func start() {
        
        HQObjectLock.synchronized(self) {
            guard !isCancelled else {
                _finished = true
                reset()
                return
            }
            
            // Add background task
            if request.config.options.contains(.taskInBackground) {
                backgroundTaskId = UIApplication.shared.beginBackgroundTask { [weak self] in
                    guard let wSelf = self else { return }
                    wSelf.cancel()  // Handle background task finish
                    UIApplication.shared.endBackgroundTask(wSelf.backgroundTaskId!)
                    wSelf.backgroundTaskId = UIBackgroundTaskInvalid
                }
            }
            
            // Start session task
            var session = injectSession
            if session == nil {
                let config = URLSessionConfiguration.default
                config.timeoutIntervalForRequest = request.config.taskTimeout
                session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
                ownSession = session
            }
            dataTask = session!.dataTask(with: request.request)
            _executing = true
        }
        
        
        guard let task = dataTask else {
            done()
            return
        }
        
        // Set task priority, priority is Float, so optional settings
        if request.config.options.contains(.priorityHigh) {
            task.priority = URLSessionTask.highPriority
        }
        else if request.config.options.contains(.priorityLow) {
            task.priority = URLSessionTask.lowPriority
        }
        
        // Start task
        task.resume()

        // If task finished, remove background task
        if let backgroundTaskId = backgroundTaskId, backgroundTaskId != UIBackgroundTaskInvalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskId)
            self.backgroundTaskId = UIBackgroundTaskInvalid
        }
    }
    
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
}

// MARK: - State & Helper function
private extension HQDownloadOperation {
    func reset() {
        closeStream()
        dataTask = nil
        if ownSession != nil {
            ownSession?.invalidateAndCancel()
            ownSession = nil
        }
    }
    
    func done() {
        _finished = true
        _executing = false
        reset()
    }
    
    func openStream() {
        stream = OutputStream(url: request.fileUrl, append: true)
        stream?.schedule(in: RunLoop.current, forMode: .defaultRunLoopMode)
        stream?.open()
    }
    
    func closeStream() {
        stream?.remove(from: RunLoop.current, forMode: .defaultRunLoopMode)
        stream?.close()
    }
}


// MARK: - HQDownloadOperationProtocol
extension HQDownloadOperation: URLSessionDataDelegate {
    /// datatask first receive response
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        
        var disposition = URLSession.ResponseDisposition.allow
        self.response = response
        
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 200
        var valid = statusCode < 400
        
        //'304 Not Modified' is an exceptional one. It should be treated as cancelled if no cache data  
        //URLSession current behavior will return 200 status code when the server respond 304 and URLCache hit. But this is not a standard behavior and we just add a check
        var urlCache: URLCache! = session.configuration.urlCache
        if urlCache == nil { urlCache = URLCache.shared }
        
        if (statusCode == 304 && urlCache.cachedResponse(for: request.request)?.data == nil) {
            valid = false
        }
        
        if valid {
            request.start(max(0, response.expectedContentLength))
        }
        else {
            // if not valid, cancel request. the session will call complete delegate function, so do not need invoke complete callback
            disposition = .cancel
        }
        
        completionHandler(disposition)
    }
    
    
    /// request receive data callback
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if let stream = stream, stream.hasSpaceAvailable {
            stream.write([UInt8](data), maxLength: data.count)
            ownRequest.progress(Int64(data.count))
        }
        else {
            ownRequest.finish(.notEnoughSpace)
            done()
        }
    }

    
    /// task completed
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        dataTask = nil
        done()
        if let err = error as NSError? {
            if err.code != -999 && ownRequest.retryCount > 0 { // Code -999 is cancelled
//                ownRequest.download()
                ownRequest.retryCount -= 1
            }
            else {
               ownRequest.finish(HQDownloadError.taskError(err))
            }
        }
        else {
            ownRequest.finish()
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
    
    /// If session is invalid, call this function
    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        cancel()
    }
}
