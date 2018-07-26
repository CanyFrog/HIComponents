//
//  HQDownloadScheduler.swift
//  HQDownload
//
//  Created by HonQi on 2018/3/28.
//  Copyright © 2018年 HonQi Indie. All rights reserved.
//

import HQFoundation

public class Scheduler: Eventable {
    let options: OptionsInfo

    var eventsMap = InnerKeyMap<Eventable.EventWrap>()
    var eventsLock = DispatchSemaphore(value: 1)
    
    /// Queue
    let queue = OperationQueue()
    
    public var operatorCount: Int { return queue.operationCount }
    
    private weak var lastedOperation: Operation?

    /// Session
    var session: URLSession!
    
    /// Delegate
    var sessionDelegate = Delegate()
    
    public init(_ infos: OptionsInfo) {
        options = infos
        queue.maxConcurrentOperationCount = options.maxConcurrentTask
        session = URLSession.hq.create(options, delegate: sessionDelegate)
    }
    
    deinit {
        queue.cancelAllOperations()
        session.invalidateAndCancel()
        eventsMap.removeAll()
    }
}

extension Scheduler {
    public func cancel(url: URL) {
        sessionDelegate.contains(url)?.cancel()
    }
    
    public func download(info: OptionsInfo) {
        guard let url = info.sourceUrl else {
            assertionFailure("Source url can not be empty!!!")
            return
        }
        if let _ = sessionDelegate.contains(url) {
            return
        }
        
        let op = Operator(options + info, session: session)
        op.subscribe(
            .start({ [weak self] (source, name, size) in
                self?.trigger(source, .start(name, size))
            }),
            .data({ [weak self] (source, data) in
                self?.trigger(source, .data(data))
            }),
            .progress({ [weak self] (source, rate) in
                self?.trigger(source, .progress(rate))
            }),
            .completed({ [weak self] (source, file) in
                self?.trigger(source, .completed(file))
            }),
            .error({ [weak self] (source, err) in
                self?.trigger(source, .error(err))
            })
        )
        
        // add delegate
        sessionDelegate.operators.hq.addObject(op)
        queue.addOperation(op)
        if options.taskOrder == .LIFO {
            lastedOperation?.addDependency(op)
            lastedOperation = op
        }
    }
}
