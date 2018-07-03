//
//  HQDownloadScheduler.swift
//  HQDownload
//
//  Created by qihuang on 2018/3/28.
//  Copyright © 2018年 com.personal.HQ. All rights reserved.
//

import HQFoundation

class Scheduler {
    var options: OptionsInfo = []
    let order: OptionItem.TaskOrder = .FIFO
    
//    let queue: OperationQueue
    
    init(options: OptionsInfo) {
        self.options = options
    }
}
//public class HQDownloadScheduler: NSObject {
//    public static let scheduler = HQDownloadScheduler()
//    
//    // MARK: - Execution order
//    public enum ExecutionOrder {
//        case FIFO // first in first out
//        case LIFO // last in first out
//    }
//
//    public var executionOrder: ExecutionOrder = .FIFO
//
//    // MARK: - Download queue
//    private var downloadQueue: OperationQueue = {
//        let queue = OperationQueue()
//        queue.name = "com.scheduler.download.personal.HQ" + UUID().uuidString
//        queue.maxConcurrentOperationCount = 6
//        return queue
//    }()
//
//    /// max concurrent downloaders, default is 6
//    public var maxConcurrentDownloaders: Int {
//        set {
//            downloadQueue.maxConcurrentOperationCount = newValue
//        }
//        get {
//            return downloadQueue.maxConcurrentOperationCount
//        }
//    }
//
//    public var currentDownloaders: Int {
//        return downloadQueue.operationCount
//    }
//    
//    private var downloadCache: CacheManager!
//
//    private var config: HQDownloadConfig!
//
//    // MARK: - Session
//    public var sessionConfig: URLSessionConfiguration { return downloadSession.configuration }
//
//    private var downloadSession: URLSession!
//
//    // MARK: - Operation
//    private weak var lastedOperation: Operation?
//
//    public init(config: HQDownloadConfig = HQDownloadConfig(), sessionConfig: URLSessionConfiguration = .default) {
//        super.init()
//        self.config = config
//        sessionConfig.timeoutIntervalForRequest = config.taskTimeout
//        sessionConfig.timeoutIntervalForResource = config.taskTimeout
//        downloadSession = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
//        downloadCache = HQCacheManager(config.directory)
//        downloadCache.memoryCache.countLimit = 5
//    }
//
//    deinit {
//        downloadQueue.cancelAllOperations()
//        downloadSession?.invalidateAndCancel()
//        downloadSession = nil
//    }
//}
//
//
//// MARK: - Public functions
//
//public extension HQDownloadScheduler {
//    public func download(source: URL, callback: @escaping (URL?, HQDownloader?)->Void) {
//        downloadCache.exist(forKey: source.absoluteString) {[weak self] (key, exist) in
//            guard let wself = self else { return }
//            if exist, let config: HQDownloadConfig = wself.downloadCache.query(objectForKey: key) {
//                if config.progressPercent >= 1.0 { // download completed
//                    callback(config.fileUrl, nil)
//                }
//                else {
//                    let downloader = HQDownloader(config: config, session: wself.downloadSession)
//                    wself.addOperation(downloader, source: source)
//                    callback(nil, downloader)
//                }
//            }
//            else {
//                var c = wself.config
//                c?.sourceUrl = source
//                let downloader = HQDownloader(config: c!, session: wself.downloadSession)
//                wself.addOperation(downloader, source: source)
//                callback(nil, downloader)
//            }
//        }
//    }
//
//    public func cancel(source: URL, resumeData: (Data?)->Void) {
//        if let downloader = operation(url: source) {
//            downloader.cancel { (data) in
//                resumeData(data)
//            }
//        }
//        else {
//            resumeData(nil)
//        }
//    }
//    
//    /// Once a session is invalidated, new tasks cannot be created in the session, but existing tasks continue until completion.
//    /// use to change session
//    public func invalidateAndCancelSession(_ cancelPendingOperations: Bool = true) {
//        guard self != HQDownloadScheduler.scheduler else { return }
//        if cancelPendingOperations {
//            downloadSession?.invalidateAndCancel()
//        }
//        else {
//            downloadSession?.finishTasksAndInvalidate()
//        }
//    }
//
//    /**
//     * When the value of this property is NO, the queue actively starts operations that are in the queue and ready to execute. Setting this property to YES prevents the queue from starting any queued operations, but already executing operations continue to execute
//     */
//    public func suspended(_ isSuspended: Bool = true) {
//        downloadQueue.isSuspended = isSuspended
//    }
//
//    public func cancelAllDownloaders() {
//        downloadQueue.cancelAllOperations()
//    }
//}
//
//// MARK: - Private functions
//private extension HQDownloadScheduler {
//    func addOperation(_ downloader: HQDownloader, source: URL) {
//        if let prev = operation(url: source) {  prev.cancel() } // If exists, cancel and add new
//        downloader.finished{ [weak self] (_, error) in
//            guard let wself = self else { return }
//            wself.downloadCache.insertOrUpdate(object: downloader.config, forKey: source.absoluteString, inBackThreadCallback: {})
//        }
//        downloadQueue.addOperation(downloader)
//        if executionOrder == .LIFO {
//            lastedOperation?.addDependency(downloader)
//            lastedOperation = downloader
//        }
//    }
//
//    func operation(url: URL) -> HQDownloader? {
//        return downloadQueue.operations.filter { (operation) -> Bool in
//            guard let oper = operation as? HQDownloader else { return false }
//            return oper.request.url! == url && oper.isExecuting
//        }.first as? HQDownloader
//    }
//
//    func operation(task: URLSessionTask) -> HQDownloader? {
//        return downloadQueue.operations.filter({ (operation) -> Bool in
//            if let taskId = (operation as? HQDownloader)?.task?.taskIdentifier {
//                return taskId == task.taskIdentifier
//            }
//            return false
//        }).first as? HQDownloader
//    }
//}
