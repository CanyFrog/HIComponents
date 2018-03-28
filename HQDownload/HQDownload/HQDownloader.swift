//
//  HQDownloader.swift
//  HQDownload
//
//  Created by qihuang on 2018/3/28.
//  Copyright © 2018年 com.personal.HQ. All rights reserved.
//

import Foundation

class HQDownloader: NSObject {
    enum ExecutionOrder {
        case FIFO // first in first out
        case LIFO // last in first out
    }
    
    var executionOrder: ExecutionOrder = .FIFO
    
    static let downloader: HQDownloader = HQDownloader(sessionConfig: URLSessionConfiguration.default)
    
    var maxConcurrentDownloaders: Int {
        set {
            downloadQueue.maxConcurrentOperationCount = maxConcurrentDownloaders
        }
        get {
            return downloadQueue.maxConcurrentOperationCount
        }
    }
    
    var currentDownloaders: Int {
        return downloadQueue.operationCount
    }
    
    var downloadTimeout: TimeInterval = 15
    
    var sessionConfig: URLSessionConfiguration? {
        return ownSession?.configuration
    }
    
    var headersFilter: ((_ url: URL, _ headers: [String: String]?)-> [String: String])?
    
    /// authentication
    var urlCredential: URLCredential?
    var username: String?
    var password: String?
    
    init(sessionConfig: URLSessionConfiguration) {
        super.init()
        downloadQueue.name = "com.download.personal.HQ"
        downloadQueue.maxConcurrentOperationCount = 6
        changeSession(withConfig: sessionConfig)
    }
    
    deinit {
        ownSession?.invalidateAndCancel()
        ownSession = nil
        downloadQueue.cancelAllOperations()
    }
    
    // MARK: - private property
    var downloadQueue = OperationQueue()
    var operationsDict = [URL: HQDownloadOperation]()
    var operationsLock = DispatchSemaphore(value: 1)
    var headersLock = DispatchSemaphore(value: 1)
    var ownSession: URLSession!
    var headers = [String: String]()
    weak var lastedOperation: Operation?
    
}

extension HQDownloader {
    
    public func download(url: URL, options: HQDownloadOptions, progress: @escaping HQDownloaderProgressClosure, completed: @escaping HQDownloaderCompletedClosure) -> HQDownloadToken {
        let _ = operationsLock.wait(timeout: .distantFuture)
        var operation = operationsDict[url]
        if operation == nil {
            operation = createOperation(url: url, options: options)
        }
        
        operation?.completionBlock = { [weak self] in
            guard let wSelf = self else { return }
            if wSelf.operationsLock.wait(timeout: .distantFuture) == .success {
                wSelf.operationsDict.removeValue(forKey: url)
                wSelf.operationsLock.signal()
            }
        }
        
        operationsDict[url] = operation
        // add to queue asynchronously execute, so this will not cause deadlock
        downloadQueue.addOperation(operation!)
        operationsLock.signal()
        
        let token = operation?.addHandlers(forProgress: progress, completed: completed)
        let downloadToken = HQDownloadToken(url: url, operationToken: token, operation: operation)
        return downloadToken
    }
    
    /**
     * Forces SDWebImageDownloader to create and use a new NSURLSession that is
     * initialized with the given configuration.
     * @note All existing download operations in the queue will be cancelled.
     * @note `timeoutIntervalForRequest` is going to be overwritten.
     *
     * @param sessionConfiguration The configuration to use for the new NSURLSession
     */
    public func changeSession(withConfig config: URLSessionConfiguration) {
        cancelAllDownloaders()
        
        if let session = ownSession {
            session.invalidateAndCancel()
        }
        
        ownSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        ownSession?.configuration.timeoutIntervalForRequest = downloadTimeout
    }
    
    /**
     * Invalidates the managed session, optionally canceling pending operations.
     * @note If you use custom downloader instead of the shared downloader, you need call this method when you do not use it to avoid memory leak
     * @param cancelPendingOperations Whether or not to cancel pending operations.
     * @note Calling this method on the shared downloader has no effect.
     */
    public func invalidateAndCancelSession(cancelPendingOperations: Bool = true) {
//        if self == HQDownloader.downloader { return }
        if cancelPendingOperations {
            ownSession?.invalidateAndCancel()
        }
        else {
            ownSession?.finishTasksAndInvalidate()
        }
    }
    
    public func setHeader(value: String?, filed: String) {
        if headersLock.wait(timeout: .distantFuture) == .success {
            if let v = value {
                headers[filed] = v
            }
            else {
                headers.removeValue(forKey: filed)
            }
            headersLock.signal()
        }
    }
    
    public func getHeader(valueFor filed: String) -> String? {
        let _ = headersLock.wait(timeout: .distantFuture)
        defer {
            headersLock.signal()
        }
        return headers[filed]
    }
    
    /**
     * Sets the download queue suspension state
     */
    public func suspended(_ isSuspended: Bool = true) {
        downloadQueue.isSuspended = isSuspended
    }
    
    public func cancelAllDownloaders() {
        downloadQueue.cancelAllOperations()
    }
    
    func cancel(_ token: HQDownloadToken) {
        let url = token.url
        if operationsLock.wait(timeout: .distantFuture) == .success {
            if let operation = operationsDict[url], operation.cancel(token.operationToken) {
                operationsDict.removeValue(forKey: url)
            }
            operationsLock.signal()
        }
    }
    
//    func appointOperation(operCls: AnyClass) {
//    }
}


private extension HQDownloader {
    func createOperation(url: URL, options: HQDownloadOptions) -> HQDownloadOperation {
        let timeout = downloadTimeout == 0 ? 15 : downloadTimeout
        
        // In order to prevent from potential duplicate caching (NSURLCache + custom cache) we disable the cache for image requests if told otherwise
        let cachePolicy: URLRequest.CachePolicy = options.contains(.useUrlCache) ? .useProtocolCachePolicy : .reloadIgnoringLocalCacheData
        
        var request = URLRequest(url: url, cachePolicy: cachePolicy, timeoutInterval: timeout)
        request.httpShouldHandleCookies = options.contains(.handleCookies)
        request.httpShouldUsePipelining = true
        if let filter = headersFilter {
            request.allHTTPHeaderFields = filter(url, headers)
        }
        else {
            request.allHTTPHeaderFields = headers
        }
        
        let operation = HQDownloadOperation(request: request, inSession: ownSession, options: options)
        if let cred = urlCredential {
            operation.credential = cred
        }
        else if let user = username, let pass = password {
            operation.credential = URLCredential(user: user, password: pass, persistence: URLCredential.Persistence.forSession)
        }
        
        if options.contains(.highPriority) {
            operation.queuePriority = .high
        }
        else if options.contains(.lowPriority) {
            operation.queuePriority = .low
        }
        
        if executionOrder == .LIFO {
            lastedOperation?.addDependency(operation)
            lastedOperation = operation
        }
        
        return operation
    }
    
    func getOperation(task: URLSessionTask) -> HQDownloadOperation {
        return downloadQueue.operations.filter({ (operation) -> Bool in
            return (operation as! HQDownloadOperation).dataTask!.taskIdentifier == task.taskIdentifier
        }).first! as! HQDownloadOperation
    }
}

// MARK: - URLSessionDataDelegate & URLSessionTaskDelegate
extension HQDownloader: URLSessionDataDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        let dataOperation = getOperation(task: dataTask)
        if dataOperation.responds(to: #selector(HQDownloadOperation.urlSession(_:dataTask:didReceive:completionHandler:))) {
            dataOperation.urlSession(session, dataTask: dataTask, didReceive: response, completionHandler: completionHandler)
        }
        else {
            completionHandler(URLSession.ResponseDisposition.allow)
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        let dataOperation = getOperation(task: dataTask)
        if dataOperation.responds(to: #selector(HQDownloadOperation.urlSession(_:dataTask:didReceive:))) {
            dataOperation.urlSession(session, dataTask: dataTask, didReceive: data)
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse, completionHandler: @escaping (CachedURLResponse?) -> Void) {
        let dataOperation = getOperation(task: dataTask)
        if dataOperation.responds(to: #selector(HQDownloadOperation.urlSession(_:dataTask:willCacheResponse:completionHandler:))) {
            dataOperation.urlSession(session, dataTask: dataTask, willCacheResponse: proposedResponse, completionHandler: completionHandler)
        }
        else {
            completionHandler(proposedResponse)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let dataOperation = getOperation(task: task)
        if dataOperation.responds(to: #selector(HQDownloadOperation.urlSession(_:task:didCompleteWithError:))) {
            dataOperation.urlSession(session, task: task, didCompleteWithError: error)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        let dataOperation = getOperation(task: task)
        if dataOperation.responds(to: #selector(urlSession(_:task:willPerformHTTPRedirection:newRequest:completionHandler:))) {
//            dataOperation.urlSession(session, task: task, willPerformHTTPRedirection: response, newRequest: request, completionHandler: completionHandler)
        }
        else {
            completionHandler(request)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let dataOperation = getOperation(task: task)
        if dataOperation.responds(to: #selector(HQDownloadOperation.urlSession(_:didReceive:completionHandler:))) {
            dataOperation.urlSession(session, didReceive: challenge, completionHandler: completionHandler)
        }
        else {
            completionHandler(URLSession.AuthChallengeDisposition.performDefaultHandling, nil)
        }
    }
}


