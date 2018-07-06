//
//  Downloader.swift
//  HQDownload
//
//  Created by Magee Huang on 5/31/18.
//  Copyright © 2018 com.personal.HQ. All rights reserved.
//

import HQFoundation
import HQCache

public class Downloader: Eventable {
    var eventsMap = InnerKeyMap<Eventable.EventWrap>()
    var eventsLock = DispatchSemaphore(value: 1)
    
    private let options: OptionsInfo
    
    private let cache: CacheManager
    
    private let scheduler: Scheduler
    
    private let backScheduler: Scheduler
    
    init(_ infos: OptionsInfo) {
        options = infos
        
        // If no cache directory, Use default setting
//        if infos.contains{ $0 ~~ .cacheDirectory(URL(string: "")) } {
//            
//        }
        cache = CacheManager(options.cacheDirectory)
        scheduler = Scheduler(options)
        backScheduler = Scheduler(options)
    }
}


extension Downloader {
    public func start(url: URL) {
        //        let options = data // decode
        //        download(options: <#T##OptionsInfo#>)
    }
    
    public func pause(source: String) -> Data? {
        /// return resume data
        return nil
    }
    
    public func cancel() {
        // remove task and delete options
    }
    
    public func allTasks() {
        
    }
    
    public func failureTasks() {
        
    }
    
    public func completedTasks() {
        
    }
    
    public func progressTasks() {
        
    }
    
    @discardableResult
    public func download(source: URL) -> Operator? {
        return download(infos: [.sourceUrl(source)])
    }
    
    @discardableResult
    public func download(source: String) -> Operator? {
        guard let url = URL(string: source) else {
            assertionFailure("Source string: \(source) is empty or can not convert to URL!")
            return nil
        }
        return download(source: url)
    }
    
    @discardableResult
    public func download(infos: OptionsInfo) -> Operator? {
        // TODO: judge cache
        guard let url = infos.sourceUrl else {
            assertionFailure("Source URL can not be empty!")
            return nil
        }
        
        var items = infos
        
        if let cacheInfo: OptionsInfo = cache.query(objectForKey: url.absoluteString),
            let completed = cacheInfo.completedCount,
            let total = cacheInfo.exceptedCount {
            if completed > total {
                trigger(url, .completed(cacheInfo.cacheDirectory.appendingPathComponent(cacheInfo.fileName!)))
                return nil
            }
            else {
                items = cacheInfo + infos
            }
        }
        if items.backgroundSession {
            // TODO: back taks identifier
            return backScheduler.download(info: items)
        }
        else {
            return scheduler.download(info: items)
        }
    }
}
