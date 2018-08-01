//
//  Downloader.swift
//  HQDownload
//
//  Created by HonQi on 5/31/18.
//  Copyright © 2018 HonQi Indie. All rights reserved.
//

import HQFoundation
import HQCache

struct Item: Codable {
    enum State: Codable, Int { case wait, download, failure, completed }
    var name: String = ""
    var completed: Int64 = 0
    var excepted: Int64 = 0
    var state: State = .wait
    
    func toOptions() -> OptionsInfo {
        return [.fileName(name), .completedCount(completed), .exceptedCount(excepted)]
    }
}

typealias Items = [URL: Item]

public class Downloader: Eventable {
    static public let `default` = Downloader([.cacheDirectory(URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!).appendingPathComponent("me.HonQi.Downloader", isDirectory: true))])
    
    var eventsMap = InnerKeyMap<Eventable.EventWrap>()
    var eventsLock = DispatchSemaphore(value: 1)
    
    private let name: String
    private var items: Items
    private let options: OptionsInfo
    private let cache: Cache
    private let scheduler: Scheduler
    
//    private let backScheduler: Scheduler
    
    public init(_ infos: OptionsInfo) {
        guard let item = infos.lastMatchIgnoringAssociatedValue(.cacheDirectory(holderUrl)),
            case .cacheDirectory(let directory) = item else {
            fatalError("Must be setting data storage directory!")
        }
        
        options = infos
        name = directory.lastPathComponent

        cache = Cache(options.cacheDirectory)
        items = cache.object(forKey: name) ?? Items()
        scheduler = Scheduler(options)
        schedulerSubscribe(scheduler)
        
//        backScheduler = Scheduler(options)
    }
    
    deinit {
        cache.setObject(items, forKey: name)
        eventsMap.removeAll()
    }
}


extension Downloader {
    public func start(source: URL) {
//        let options = data // decode
//        download(options: <#T##OptionsInfo#>)
    }
    
    public func pause(source: URL) {
        /// return resume data
        
    }
    
    public func cancel(source: URL) {
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
    
    public func download(source: URL) -> Downloader? {
        return download(infos: [.sourceUrl(source)])
    }
    
    public func download(source: String) -> Downloader? {
        guard let url = URL(string: source) else {
            assertionFailure("Source string: \(source) is empty or can not convert to URL!")
            return nil
        }
        return download(source: url)
    }
    
    public func download(infos: OptionsInfo) -> Downloader? {
        guard let url = infos.sourceUrl else {
            assertionFailure("Source URL can not be empty!")
            return nil
        }
        
        var options = infos
        
        if let cacheInfo: OptionsInfo = cache.object(forKey: url.absoluteString),
            let completed = cacheInfo.completedCount,
            let total = cacheInfo.exceptedCount {
            if completed >= total {
                trigger(url, .completed(options.cacheDirectory.appendingPathComponent(cacheInfo.fileName!)))
                return self
            }
            else {
                options = cacheInfo + infos
            }
        }
        
        var item = items[url]
        if item == nil {
            item = Item()
        }
        item?.state = .wait
        items[url] = item
        
        
//        if items.backgroundSession {
//            // TODO: back taks identifier
//            backScheduler.download(info: items)
//        }
//        else {
            scheduler.download(info: options)
//        }
        
        return self
    }
}


extension Downloader {
    private func schedulerSubscribe(_ scheduler: Scheduler){
        scheduler.subscribe(
            .start({ [weak self] (source, name, size) in
                self?.trigger(source, .start(name, size))
                
                var item = self?.items[source]
                item?.name = name
                item?.excepted = size
                item?.completed = 0
                item?.state = .download
                self?.items[source] = item
            }),
            .progress({ [weak self] (source, rate) in
                self?.trigger(source, .progress(rate))
                
                var item = self?.items[source]
                item?.completed = rate.completedUnitCount
                self?.items[source] = item
            }),
            .data({ [weak self] (source, data) in
                self?.trigger(source, .data(data))
            }),
            .completed({ [weak self] (source, file) in
                self?.trigger(source, .completed(file))
                if let item = self?.items[source] {
                    self?.cache.setObject(item.toOptions(), forKey: source.absoluteString)
                }
            }),
            .error({ [weak self] (source, err) in
                self?.trigger(source, .error(err))
                if let item = self?.items[source] {
                    self?.cache.setObject(item.toOptions(), forKey: source.absoluteString)
                }
            })
        )
    }
}
