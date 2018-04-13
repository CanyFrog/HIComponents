//
//  HQDownloader.swift
//  HQDownload
//
//  Created by Magee Huang on 4/10/18.
//  Copyright © 2018 com.personal.HQ. All rights reserved.
//

import HQCache

public class HQDownloader {
    static let downloader = HQDownloader()
    
    public private(set) var directoryUrl: URL!
    
    private var scheduler: HQDownloadScheduler!
    private var cache: HQDiskCache!
    
    
    public init(_ directory: URL = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!).appendingPathComponent("downloader", isDirectory: true)) {
        directoryUrl = directory
        scheduler = HQDownloadScheduler(directory)
        cache = HQDiskCache(directory)
    }
    
    public func download(_ source: URL, _ start: HQDownloadOperation.startClosure? = nil, _ finished: HQDownloadOperation.finishedClosure? = nil) {
        guard cache.exist(forKey: source.absoluteString), let obj: HQdownloadProgress = cache.query(objectForKey: source.absoluteString) else {
            scheduler.download(source).start(start).finished(finished)
            return
        }
        
        if obj.fractionCompleted >= 1.0, let file = obj.fileURL {
            start?(source, file, obj.totalUnitCount)
            finished?(nil)
            return
        }
        
        
        if let request = HQDownloadRequest(obj) {
            scheduler.download(request).start(start).finished(finished)
            return
        }
        
        scheduler.download(source).start(start).finished(finished)
    }
    
    public func download(_ source: URL) -> HQdownloadProgress {
        guard cache.exist(forKey: source.absoluteString), let obj: HQdownloadProgress = cache.query(objectForKey: source.absoluteString) else { return scheduler.download(source).progress }
        
        if obj.fractionCompleted >= 1.0 {
            return obj
        }
        
        if let request = HQDownloadRequest(obj) {
            return scheduler.download(request).progress
        }
        
        return scheduler.download(source).progress
    }
    
//    public func download(_ sources: [URL]) -> [URL: HQdownloadProgress] {
//
//    }
}
