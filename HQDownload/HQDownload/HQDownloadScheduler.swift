//
//  HQDownloadScheduler.swift
//  HQDownload
//
//  Created by qihuang on 2018/3/28.
//  Copyright © 2018年 com.personal.HQ. All rights reserved.
//

import HQFoundation

public class HQDownloadScheduler: NSObject {
    
    public static let scheduler: HQDownloadScheduler = HQDownloadScheduler(URLSessionConfiguration.default)
    
    // MARK: - Execution order
    public enum ExecutionOrder {
        case FIFO // first in first out
        case LIFO // last in first out
    }
    
    public var executionOrder: ExecutionOrder = .FIFO
    
    
    // MARK: - Download queue
    /// max concurrent downloaders, default is 6
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
    
    private var downloadQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "com.scheduler.download.personal.HQ" + UUID().uuidString
        queue.maxConcurrentOperationCount = 6
        return queue
    }()
    
    // MARK: - Session
    public var sessionConfig: URLSessionConfiguration? {
        return ownSession?.configuration
    }
    
    private var ownSession: URLSession!
    
    // MARK: - Operation
    private weak var lastedOperation: Operation?
    public private(set) var operationsDict = [URL: HQDownloadOperation]()
    private var operationsLock = DispatchSemaphore(value: 1)
    
    // private var cache:
    public private(set) var path: String!

    public private(set) var progress: Progress = {
        let pro = Progress()
        pro.isCancellable = true
        pro.isPausable = true
        return pro
    }()
    
    init(_ sessionConfig: URLSessionConfiguration = .default, _ name: String? = nil) {
        super.init()
        sessionConfig.timeoutIntervalForRequest = 15
        ownSession = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
        path = "\(NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!)/\(name ?? "download")"
    }
    
    deinit {
        downloadQueue.cancelAllOperations()
        ownSession?.invalidateAndCancel()
        progress.cancel()
        ownSession = nil
    }
}


// MARK: - Public functions

public extension HQDownloadScheduler {
    func download(_ url: URL) {
        let operation = HQDownloadOperation(request: HQDownloadRequest(url), targetPath: "\(path)/\(url.lastPathComponent)", session: ownSession)
        addOperation(operation, forUrl: url)
    }
    
    func download(_ request: HQDownloadRequest) {
        let operation = HQDownloadOperation(request: request, targetPath: "\(path)/\(request.fileName)", session: ownSession)
        addOperation(operation, forUrl: request.request.url!)
    }
    
    /// if url associate operation is exists, will remove all task and change it
    public func addOperation(_ operation: HQDownloadOperation, forUrl url: URL) {
        // if exists, return
        guard HQDispatchLock.semaphore(operationsLock, closure: { !operationsDict.keys.contains(url) }) else { return }
        
        // add to queue asynchronously execute, so this will not cause deadlock
        operation.completionBlock = operationCompletionBlock(url)
        
        // add or replace operation
        HQDispatchLock.semaphore(operationsLock) {
            self.operationsDict[url] = operation
        }
        
        // start operation
        downloadQueue.addOperation(operation)
        if executionOrder == .LIFO {
            lastedOperation?.addDependency(operation)
            lastedOperation = operation
        }
    }
    
    /// Invalidates the managed session, optionally canceling pending operations.
    /// - Note If you use custom downloader instead of the shared downloader, you need call this method when you do not use it to avoid memory leak
    /// - Note Calling this method on the shared downloader has no effect.
    /// - Parameter cancelPendingOperations: cancelPendingOperations Whether or not to cancel pending operations.
    public func invalidateAndCancelSession(cancelPendingOperations: Bool = true) {
        if self == HQDownloadScheduler.scheduler { return }
        if cancelPendingOperations {
            ownSession?.invalidateAndCancel()
        }
        else {
            ownSession?.finishTasksAndInvalidate()
        }
    }
    
    /**
     * Sets the download queue suspension state
     */
    public func suspended(_ isSuspended: Bool = true) {
        downloadQueue.isSuspended = isSuspended
    }
    
    public func cancelAllDownloaders() {
        downloadQueue.cancelAllOperations()
        HQDispatchLock.semaphore(operationsLock) {
            operationsDict.removeAll()
        }
    }
    
    func remove(_ url: URL) {
        HQDispatchLock.semaphore(operationsLock) {
            let operation = operationsDict[url]
            operation?.cancel()
            operationsDict.removeValue(forKey: url)
        }
    }
}


// MARK: - Private functions
private extension HQDownloadScheduler {
    
    func operationCompletionBlock(_ url: URL) -> ()->Void {
        return { [weak self] in
            guard let wself = self else { return }
            HQDispatchLock.semaphore(wself.operationsLock, closure: {
                wself.operationsDict.removeValue(forKey: url)
            })
        }
    }
    
    func operation(task: URLSessionTask) -> HQDownloadOperation? {
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
        
        if let operation = operation(task: dataTask) {
            operation.urlSession(session, dataTask: dataTask, didReceive: response, completionHandler: completionHandler)
        }
        else {
            completionHandler(URLSession.ResponseDisposition.allow)
        }
    }
    
    
    /// request receive data callback
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {

        if let operation = operation(task: dataTask) {
            operation.urlSession(session, dataTask: dataTask, didReceive: data)
        }
    }
    
    
    /// task completed
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
        if let operation = operation(task: task) {
            operation.urlSession(session, task: task, didCompleteWithError: error)
        }

    }
    
    /// task begin and authentication
    public func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let operation = operation(task: task) {
            operation.urlSession(session, task: task, didReceive: challenge, completionHandler: completionHandler)
        }
        else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
    
    /// Handle session cache
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse, completionHandler: @escaping (CachedURLResponse?) -> Void) {
        
        if let operation = operation(task: dataTask) {
            operation.urlSession(session, dataTask: dataTask, willCacheResponse: proposedResponse, completionHandler: completionHandler)
        }
        else {
            completionHandler(proposedResponse)
        }
    }
}
