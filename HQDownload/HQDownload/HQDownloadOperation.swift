//
//  HQDownloadOperation.swift
//  HQDownload
//
//  Created by qihuang on 2018/3/27.
//  Copyright © 2018年 com.personal.HQ. All rights reserved.
//

import Foundation

public final class HQDownloadOperation: Operation {
    // MARK: Public property

    /// The request used by the operation's task
    public private(set) var request: URLRequest!
   
    public private(set) var dataTask: URLSessionTask?
    
    /// The credential used for authentication challenges in `-URLSession:task:didReceiveChallenge:completionHandler:`.
    /// This will be overridden by any shared credentials that exist for the username or password of the request URL, if present.
    public var credential: URLCredential?
    
    public private(set) var response: URLResponse?
    
    
    public var currentSize: Int = 0
    
    /// The excepted size of data
    public var expectedSize: Int = Int.max
    
    public private(set) var options: HQDownloadOptions!
    
    open override var isConcurrent: Bool {
        return true
    }
    
    open override var isAsynchronous: Bool {
        return true
    }
    
    // MARK: Private property
    private var callbackLists = [HQDownloadCallback]()
    
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
    
    /// This is weak because it is injected by whoever manages this session. If this gets nil-ed out, we won't be able to run; the task associated with this operation
    private weak var unownedSession: URLSession?
    
    /// This is set if we're using not using an injected NSURLSession. We're responsible of invalidating this one
    private var ownedSession: URLSession?
    
    private var callbacksLock = DispatchSemaphore(value: 1)
    
    private var backgroundTaskId: UIBackgroundTaskIdentifier?
    

    
    public init(request: URLRequest, inSession session: URLSession, options: HQDownloadOptions) {
        super.init()
        self.request = request
        self.options = options
        self.unownedSession = session
    }
    
    override open func cancel() {
        objc_sync_enter(self)
        cancelTiming()
        objc_sync_exit(self)
    }
    
    open override func start() {
        objc_sync_enter(self)

        // adjust whether or not cancelled
        if isCancelled {
            _finished = true
            reset()
            return
        }
        
        // background task
        addBackgroundTask()
        
        // get or creat session
        let session = getOrCreateSession()
        
        // add task
        dataTask = session.dataTask(with: request!)
        _executing = true
        
        objc_sync_exit(self)
        
        configTask()
        
        // when task finished, close background task
        endBackgroundTask()
    }
}

// MARK: - Public functions
public extension HQDownloadOperation {
    public func addHandlers(forProgress progress: HQDownloaderProgressClosure?, completed: HQDownloaderCompletedClosure?) -> AnyObject? {
        
        let callback = HQDownloadCallback(progress: progress, completed: completed)

        // lock success
        if callbacksLock.wait(timeout: DispatchTime.distantFuture) == .success {
            callbackLists.append(callback)
            callbacksLock.signal()
            return callback as AnyObject
        }
        return nil
    }

    public func cancel(_ token: AnyObject?) -> Bool {
        guard let dict = token as? HQDownloadCallback else { return false }
        var shouldCancel = false
        if callbacksLock.wait(timeout: .distantFuture) == .success {
            if let index = callbackLists.index(where: { $0 == dict }) {
                callbackLists.remove(at: index)
            }
            shouldCancel = callbackLists.isEmpty
            callbacksLock.signal()
        }
        
        if shouldCancel {
            cancel()
        }
        return shouldCancel
    }
}

// MARK: private functions
private extension HQDownloadOperation {
    func invokeCompletedClosure(error: Error?) {
        let _ = callbackLists.map { (callback) -> Void in
            if let completed = callback.completedClosure {
                completed(error)
            }
        }
    }
    
    func invokeProgressClosure(data: Data?, receivedSize: Int, expectedSize: Int, targetUrl: URL) {
        let _ = callbackLists.map { (callback) -> Void in
            if let progress = callback.progressClosure {
                progress(data, receivedSize, expectedSize, targetUrl)
            }
        }
    }
    
    func reset() {
        if callbacksLock.wait(timeout: .distantFuture) == .success {
            callbackLists.removeAll()
            callbacksLock.signal()
        }
        dataTask = nil
        if ownedSession != nil {
            ownedSession!.invalidateAndCancel()
            ownedSession = nil
        }
    }
    
    func done() {
        _finished = true
        _executing = false
        reset()
    }
    
    func cancelTiming() {
        if isFinished { return }
        super.cancel()
        
        if let task = dataTask {
            task.cancel()
            if isExecuting { _executing = false }
            if !isFinished { _finished = true }
        }
        
        reset()
    }
    
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
    
    func endBackgroundTask() {
        // set end background task
        if let backgroundTaskId = backgroundTaskId, backgroundTaskId != UIBackgroundTaskInvalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskId)
            self.backgroundTaskId = UIBackgroundTaskInvalid
        }
    }
    
    func getOrCreateSession() -> URLSession {
        guard ownedSession == nil else { return ownedSession! }
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 15
        // We send nil as delegate queue so that the session creates a serial operation queue for performing all delegate method calls and completion handler calls.
        ownedSession = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
        return ownedSession!
    }
    
    func configTask() {
        guard let task = dataTask else {
            // TODO: params 2 is error infomation post completed callback
            invokeCompletedClosure(error: nil)
            done()
            return
        }
        
        if task.responds(to: #selector(setter: URLSessionTask.priority)) {
            if options.contains(.highPriority) {
                task.priority = URLSessionTask.highPriority
            }
            else if options.contains(.lowPriority) {
                task.priority = URLSessionTask.lowPriority
            }
        }
        
        task.resume()
        
        invokeProgressClosure(data: nil, receivedSize: 0, expectedSize: expectedSize, targetUrl: request.url!)
    }
}


// MARK: URLSessionDataDelegate
extension HQDownloadOperation: URLSessionDataDelegate {
    /// datatask first receive response
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        var disposition = URLSession.ResponseDisposition.allow
        expectedSize = max(Int(response.expectedContentLength), 0)
        self.response = response
        
        var statusCode = 200
        if let rp = response as? HTTPURLResponse {
            statusCode = rp.statusCode
        }
        
        var valid = statusCode < 400
        
        //'304 Not Modified' is an exceptional one. It should be treated as cancelled if no cache data  如果是 304 并且没有缓存就是失败
        //URLSession current behavior will return 200 status code when the server respond 304 and URLCache hit. But this is not a standard behavior and we just add a check
        var urlCache: URLCache! = session.configuration.urlCache
        if urlCache == nil { urlCache = URLCache.shared }
        
        if (statusCode == 304 && urlCache.cachedResponse(for: request)?.data == nil) {
            valid = false
        }
        
        if valid {
            invokeProgressClosure(data: nil, receivedSize: 0, expectedSize: expectedSize, targetUrl: request.url!)
        }
        else {
            // if not valid, cancel task
            disposition = .cancel
        }
        
        completionHandler(disposition)
    }
    
    /// request callback
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        // insert callback handle data
        currentSize += data.count
        invokeProgressClosure(data: data, receivedSize: currentSize, expectedSize: expectedSize, targetUrl: request.url!)
    }
    
    /// task finish and will cache
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse, completionHandler: @escaping (CachedURLResponse?) -> Void) {
        
        // remove response prevent use cache
        completionHandler(options.contains(.useUrlCache) ? proposedResponse : nil)
        
    }
}


// MARK: - URLSessionTaskDelegate
extension HQDownloadOperation: URLSessionTaskDelegate {
    /// task completed
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        objc_sync_enter(self)
        dataTask = nil
        objc_sync_exit(self)
        
        /// error may be is nil
        invokeCompletedClosure(error: error)
        done()
    }
    
    /// task begin and authentication
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
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
}
