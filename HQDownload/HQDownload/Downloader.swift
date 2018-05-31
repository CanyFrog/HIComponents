//
//  Downloader.swift
//  HQDownload
//
//  Created by Magee Huang on 5/31/18.
//  Copyright © 2018 com.personal.HQ. All rights reserved.
//

import HQFoundation
import HQCache

public class Downloader {
    private let options: OptionsInfo
    
    private let cache: CacheManager
    
    private let scheduler: Scheduler
    
    init(options: OptionsInfo) {
        self.options = options
        cache = CacheManager(options.cacheDirectory)
        // cache.maxCacheCount/Age
        scheduler = Scheduler(options: options)
    }
    
    public func download(source: URL, options: OptionsInfo) {
        /// download from url
        var newOptions = options
        newOptions.append(OptionItem.sourceUrl(source))
        download(options: newOptions)
    }
    
    public func download(source: String, options: OptionsInfo) {
        guard let url = URL(string: source) else { return }
        download(source: url, options: options)
    }
    
    public func download(options: OptionsInfo) {
        
    }
    
    public func start(data: Data) {
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
}
