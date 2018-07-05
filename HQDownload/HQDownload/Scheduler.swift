//
//  HQDownloadScheduler.swift
//  HQDownload
//
//  Created by qihuang on 2018/3/28.
//  Copyright © 2018年 com.personal.HQ. All rights reserved.
//

import HQFoundation

public class Scheduler {
    var options: OptionsInfo = []

    typealias CallBack = (URL, Event)->Void
    private lazy var callbackMap = InnerKeyMap<CallBack>()
    private lazy var callbackLock = DispatchSemaphore(value: 1)
    
    var operatorMap = [URL: Operator]()
    
    /// Queue
    let queue = OperationQueue()
    
    public var operatorCount: Int { return queue.operationCount }
    
    private weak var lastedOperation: Operation?

    /// Session
    var session: URLSession!
    
    init(options: OptionsInfo) {
        self.options = options
        queue.maxConcurrentOperationCount = options.maxConcurrentTask
        session = URLSession(configuration: .default) // config
    }
    
    deinit {
        queue.cancelAllOperations()
        session.invalidateAndCancel()
        callbackMap.removeAll()
    }
}

extension Scheduler {
    public func cancel(url: URL) {
        guard let op = operatorMap[url] else { return }
        op.cancel()
    }
    
    @discardableResult
    public func download(options: OptionsInfo) -> Operator? {
        guard let url = options.sourceUrl else { return nil }
        if let oldOp = operatorMap[url] { return oldOp }
        
        let op = Operator(options: options, session: session)
        
        // convert to self callback
        op.subscribe(start: { [weak self] (name, size) in
            self?.execute(url: url, event: .start(name, size))
        }, progress: { [weak self] (rate) in
            self?.execute(url: url, event: .progress(rate))
        }, completed: { [weak self] (url) in
            self?.execute(url: url, event: .completed(url))
        }) { [weak self] (error) in
            self?.execute(url: url, event: .error(error))
        }
        
        // add delegate
        
        operatorMap[url] = op
        queue.addOperation(op)
        if options.taskOrder == .LIFO {
            lastedOperation?.addDependency(op)
            lastedOperation = op
        }
        return op
    }
    
    @discardableResult
    public func subscribe(start: ((URL, String, Int64)->Void)? = nil,
                       progress: ((URL, Progress)->Void)? = nil,
                       completed: ((URL, URL)->Void)? = nil,
                       error: ((URL, DownloadError)->Void)? = nil) -> UInt64 {
        let callback = { (url: URL, event: Event) in
            switch event {
            case .start(let name, let size):
                start?(url, name, size)
            case .progress(let rate):
                progress?(url, rate)
            case .completed(let file):
                completed?(url, file)
            case .error(let err):
                error?(url, err)
            default: break
            }
        }
        
        return Lock.semaphore(callbackLock) { () -> UInt64 in
            return callbackMap.insert(callback)
        }
    }
    
    public func unsubscribe(_ key: UInt64) {
        Lock.semaphore(callbackLock) {
            callbackMap.remove(key)
        }
    }
}


extension Scheduler {
    func execute(url: URL, event: Event) {
        Lock.semaphore(callbackLock) {
            callbackMap.forEach{ $0(url, event) }
        }
    }
}
