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
    public private(set) var tasks = [String]()
    
    private var scheduler: HQDownloadScheduler!
    private var cache: HQDiskCache!
    
    
    public init(_ directory: URL = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!).appendingPathComponent("downloader", isDirectory: true)) {
        directoryUrl = directory
        scheduler = HQDownloadScheduler(directory)
        cache = HQDiskCache(directory)
    }
    
    
    public func download(_ source: URL, _ callback: (URL?, HQDownloadOperation?) -> Void) {
        guard cache.exist(forKey: source.absoluteString), let obj: HQDownloadProgress = cache.query(objectForKey: source.absoluteString) else {
            callback(nil, scheduler.download(source))
            return
        }
        if obj.fractionCompleted >= 1.0, let file = obj.fileUrl {
            callback(file, nil)
            return
        }
        
        if let request = HQDownloadRequest(obj) {
            callback(nil, scheduler.download(request))
            return
        }
        
        callback(nil, scheduler.download(source))
    }
}

extension HQDownloader {
    private func createDownloadTask() {
        
    }
}
