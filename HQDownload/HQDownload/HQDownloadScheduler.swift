//
//  HQDownloadScheduler.swift
//  HQDownload
//
//  Created by qihuang on 2018/3/28.
//  Copyright © 2018年 com.personal.HQ. All rights reserved.
//

import HQFoundation

public class HQDownloadScheduler: NSObject {
    // MARK: - Execution order
    public enum ExecutionOrder {
        case FIFO // first in first out
        case LIFO // last in first out
    }
    
    public var executionOrder: ExecutionOrder = .FIFO
    
    // MARK: - Download queue
    private var downloadQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "com.scheduler.download.personal.HQ" + UUID().uuidString
        queue.maxConcurrentOperationCount = 6
        return queue
    }()
    
    /// max concurrent downloaders, default is 6
    public var maxConcurrentDownloaders: Int {
        set {
            downloadQueue.maxConcurrentOperationCount = newValue
        }
        get {
            return downloadQueue.maxConcurrentOperationCount
        }
    }
    
    public var currentDownloaders: Int {
        return downloadQueue.operationCount
    }
    
    
    // MARK: - Session
    public var sessionConfig: URLSessionConfiguration? {
        return ownSession?.configuration
    }
    
    private var ownSession: URLSession!
    
    // MARK: - Operation
    private weak var lastedOperation: Operation?
    
    // private var cache:
    public private(set) var directory: URL!
    
    // TODO: progress tree
    public private(set) var progress: HQDownloadProgress = {
        let pro = HQDownloadProgress()
        pro.isCancellable = true
        pro.isPausable = true
        return pro
    }()
    
    init(_ directory: URL, _ sessionConfig: URLSessionConfiguration = .default) {
        super.init()
        sessionConfig.timeoutIntervalForRequest = 15
        ownSession = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
        self.directory = directory
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
    @discardableResult
    public func download(_ url: URL, _ headers: [String: String]? = nil) -> HQDownloadOperation {
        if let existedOp = operation(url: url) { return existedOp }
        let newOp = HQDownloadOperation(HQDownloadRequest(url, directory.appendingPathComponent(url.lastPathComponent), headers), ownSession)
        setOperation(newOp)
        return newOp
    }
    
    @discardableResult
    public func download(_ request: HQDownloadRequest) -> HQDownloadOperation {
        if let existedOp = operation(url: request.request.url!) { return existedOp }
        let newOp = HQDownloadOperation(request, ownSession)
        setOperation(newOp)
        return newOp
    }
    
    /// Once a session is invalidated, new tasks cannot be created in the session, but existing tasks continue until completion.
    /// use to change session
//    public func invalidateAndCancelSession(_ cancelPendingOperations: Bool = true) {
//        progress.cancel()
//        if cancelPendingOperations {
//            ownSession?.invalidateAndCancel()
//        }
//        else {
//            ownSession?.finishTasksAndInvalidate()
//        }
//    }
    
    /**
     * When the value of this property is NO, the queue actively starts operations that are in the queue and ready to execute. Setting this property to YES prevents the queue from starting any queued operations, but already executing operations continue to execute
     */
    public func suspended(_ isSuspended: Bool = true) {
        downloadQueue.isSuspended = isSuspended
        if isSuspended {
            progress.pause()
        }
        else {
            progress.resume()
        }
    }
    
    public func cancelAllDownloaders() {
        downloadQueue.cancelAllOperations()
        progress.cancel()
    }
}

// MARK: - Private functions
private extension HQDownloadScheduler {
    func setOperation(_ operation: HQDownloadOperation) {
        operation.begin { [weak self] (_, _, size) in
            self?.progress.addChild(operation.progress, withPendingUnitCount: size)
        }
        
        downloadQueue.addOperation(operation)
        if executionOrder == .LIFO {
            lastedOperation?.addDependency(operation)
            lastedOperation = operation
        }
    }
    
    func operation(url: URL) -> HQDownloadOperation? {
        return downloadQueue.operations.filter { (operation) -> Bool in
            guard let oper = operation as? HQDownloadOperation else { return false }
            return oper.ownRequest.request.url == url
        }.first as? HQDownloadOperation
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
    
    /// If session is invalid, call this function
    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
    }
}
