//
//  HQDownloadScheduler.swift
//  HQDownload
//
//  Created by qihuang on 2018/3/28.
//  Copyright © 2018年 com.personal.HQ. All rights reserved.
//

import Foundation

public class HQDownloadScheduler: NSObject {
    
    public static let scheduler: HQDownloadScheduler = HQDownloadScheduler(sessionConfig: URLSessionConfiguration.default)
    
    public enum ExecutionOrder {
        case FIFO // first in first out
        case LIFO // last in first out
    }
    
    public var executionOrder: ExecutionOrder = .FIFO
    
    public var maxConcurrentDownloaders: Int {
        set {
            downloadQueue.maxConcurrentOperationCount = maxConcurrentDownloaders
        }
        get {
            return downloadQueue.maxConcurrentOperationCount
        }
    }
    
    public var currentDownloaders: Int {
        return downloadQueue.operationCount
    }
    
    public var downloadTimeout: TimeInterval = 15
    
    public var sessionConfig: URLSessionConfiguration? {
        return ownSession?.configuration
    }
    
    public var headersFilter: ((_ url: URL, _ headers: [String: String]?)-> [String: String])?
    
    // MARK: - authentication
    public var urlCredential: URLCredential?
    public var username: String?
    public var password: String?
    
    init(sessionConfig: URLSessionConfiguration) {
        super.init()
        downloadQueue.name = "com.scheduler.download.personal.HQ"
        downloadQueue.maxConcurrentOperationCount = 6
        changeSession(config: sessionConfig)
    }
    
    deinit {
        downloadQueue.cancelAllOperations()
        ownSession?.invalidateAndCancel()
        ownSession = nil
    }
    
    
    // MARK: - private property
    
    private var downloadQueue = OperationQueue()
    private var operationsDict = [URL: HQDownloadOperation]()
    private var operationsLock = DispatchSemaphore(value: 1)
    private var headersLock = DispatchSemaphore(value: 1)
    private var ownSession: URLSession!
    private var headers = [String: String]()
    private weak var lastedOperation: Operation?
    
}


// MARK: - Public functions
public extension HQDownloadScheduler {

    public func download(url: URL, options: HQDownloadOptions, progress: HQDownloaderProgressClosure?, completed: HQDownloaderCompletedClosure?) -> HQDownloadCallback? {
        let _ = operationsLock.wait(timeout: .distantFuture)
        var operation = operationsDict[url]
        operationsLock.signal()
        
        guard operation == nil else { return operation?.addCallback(progress: progress, completed: completed) }
        operation = createOperation(url: url, options: options)
        addCustomOperation(url: url, operation: operation!)
        return operation!.addCallback(progress: progress, completed: completed)
    }
    
    /// return callback token, if failure return nil
    /// if url associate operation is exists, will not change
    public func addCustomOperation(url: URL, operation: HQDownloadOperation) {
        let _ = operationsLock.wait()
        defer { operationsLock.signal() }
        guard operationsDict[url] == nil else { return }
        // add to queue asynchronously execute, so this will not cause deadlock
        operation.completionBlock = { [weak self] in
            let _ = self?.operationsLock.wait()
            self?.operationsDict.removeValue(forKey: url)
            self?.operationsLock.signal()
        }
        operationsDict[url] = operation
        downloadQueue.addOperation(operation)
    }
    
    public func addCallbacks(url: URL, callbacks: [HQDownloadCallback]) {
        let _ = operationsLock.wait()
        defer { operationsLock.signal() }
        
        if let operation = operationsDict[url] {
            operation.addCallbacks(callbacks)
        }
        else {
            fatalError("The url \(url.description) associate operation is not found")
        }
    }
    
    public func addCallback(url: URL, callback: HQDownloadCallback) {
        let _ = operationsLock.wait()
        defer { operationsLock.signal() }
        
        if let operation = operationsDict[url] {
            operation.addCallback(callback)
        }
        else {
            fatalError("The url \(url.description) associate operation is not found")
        }
    }
    
    
    public func addCallback(url: URL, progress: HQDownloaderProgressClosure?, completed: HQDownloaderCompletedClosure?) -> HQDownloadCallback? {
        let _ = operationsLock.wait()
        defer { operationsLock.signal() }
        
        if let operation = operationsDict[url] {
            return operation.addCallback(progress: progress, completed: completed)
        }
        else {
            fatalError("The url \(url.description) associate operation is not found")
        }
    }
    
    /**
     * Forces Downloader to create and use a new NSURLSession that is
     * initialized with the given configuration.
     * @note All existing download operations in the queue will be cancelled.
     * @note `timeoutIntervalForRequest` is going to be overwritten.
     *
     * @param sessionConfiguration The configuration to use for the new NSURLSession
     */
    public func changeSession(config: URLSessionConfiguration) {
        cancelAllDownloaders()
        if let session = ownSession { session.invalidateAndCancel() }
        config.timeoutIntervalForRequest = downloadTimeout
        ownSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    /**
     * Invalidates the managed session, optionally canceling pending operations.
     * @note If you use custom downloader instead of the shared downloader, you need call this method when you do not use it to avoid memory leak
     * @param cancelPendingOperations Whether or not to cancel pending operations.
     * @note Calling this method on the shared downloader has no effect.
     */
    public func invalidateAndCancelSession(cancelPendingOperations: Bool = true) {
        if self == HQDownloadScheduler.scheduler { return }
        if cancelPendingOperations {
            ownSession?.invalidateAndCancel()
        }
        else {
            ownSession?.finishTasksAndInvalidate()
        }
    }
    
    public func setHeader(value: String?, field: String) {
        if headersLock.wait(timeout: .distantFuture) == .success {
            if let v = value {
                headers[field] = v
            }
            else {
                headers.removeValue(forKey: field)
            }
            headersLock.signal()
        }
    }
    
    public func getHeader(field: String) -> String? {
        let _ = headersLock.wait(timeout: .distantFuture)
        defer {
            headersLock.signal()
        }
        return headers[field]
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
    
    func cancel(_ token: HQDownloadCallback) {
        guard let url = token.url else { return }
        let _ = operationsLock.wait(timeout: .distantFuture)
        if let operation = operationsDict[url], operation.cancel(token) {
            operationsDict.removeValue(forKey: url)
        }
        operationsLock.signal()
    }
}


// MARK: - Private functions
private extension HQDownloadScheduler {
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
        
        let operation = HQDownloadOperation(request: request, options: options, session: ownSession)
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
    
    
    func getOperation(task: URLSessionTask) -> HQDownloadOperation? {
        return downloadQueue.operations.filter({ (operation) -> Bool in
            if let taskId = (operation as? HQDownloadOperation)?.dataTask?.taskIdentifier {
                return taskId == task.taskIdentifier
            }
            return false
        }).first as? HQDownloadOperation
    }
}


// MARK: - URLSessionDataDelegate, own session delegate, needs to pass to operation
extension HQDownloadScheduler: URLSessionDataDelegate {
    /// datatask first receive response
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        
        if let operation = getOperation(task: dataTask) {
            operation.urlSession(session, dataTask: dataTask, didReceive: response, completionHandler: completionHandler)
        }
        else {
            completionHandler(URLSession.ResponseDisposition.allow)
        }
    }
    
    
    /// request receive data callback
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {

        if let operation = getOperation(task: dataTask) {
            operation.urlSession(session, dataTask: dataTask, didReceive: data)
        }
    }
    
    
    /// task completed
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
        if let operation = getOperation(task: task) {
            operation.urlSession(session, task: task, didCompleteWithError: error)
        }

    }
    
    /// task begin and authentication
    public func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let operation = getOperation(task: task) {
            operation.urlSession(session, task: task, didReceive: challenge, completionHandler: completionHandler)
        }
        else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
    
    /// Handle session cache
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse, completionHandler: @escaping (CachedURLResponse?) -> Void) {
        
        if let operation = getOperation(task: dataTask) {
            operation.urlSession(session, dataTask: dataTask, willCacheResponse: proposedResponse, completionHandler: completionHandler)
        }
        else {
            completionHandler(proposedResponse)
        }
    }
}
