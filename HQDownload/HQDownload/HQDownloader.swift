//
//  HQDownloader.swift
//  HQDownload
//
//  Created by Magee Huang on 4/10/18.
//  Copyright © 2018 com.personal.HQ. All rights reserved.
//

import HQCache

public class HQDownloader {
    private var scheduler: HQDownloadScheduler!
    private var cache: HQDiskCache!
    
    /// name is download directory name, file save to Cache directory
    init(_ name: String = "downloader") {
        scheduler = HQDownloadScheduler(.default, name)
//        cache = HQDiskCache()
    }
}
