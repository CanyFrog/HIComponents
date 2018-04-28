////
////  HQDownloader.swift
////  HQDownload
////
////  Created by Magee Huang on 4/10/18.
////  Copyright © 2018 com.personal.HQ. All rights reserved.
////
//
//import HQCache
//
//public class HQDownloader {
//    public static let Downloader = HQDownloader()
//
//    public private(set) var directoryUrl: URL!
//    public private(set) var tasks = [String]()
//
//    private var scheduler: HQDownloadScheduler!
//    private var cache: HQDiskCache!
//
//
//    public init(_ directory: URL = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!).appendingPathComponent("downloader", isDirectory: true)) {
//        directoryUrl = directory
//        scheduler = HQDownloadScheduler(directory)
//        cache = HQDiskCache(directory)
//    }
//
//
//    public func download(_ source: URL, _ callback: @escaping (URL?, HQDownloadOperation?) -> Void) {
//        cache.exist(forKey: source.absoluteString) { [weak self] (_, exist) in
//            guard let wself = self else { return }
//            if exist, let obj: HQDownloadRequest = wself.cache.query(objectForKey: source.absoluteString) {
//                if obj.fractionCompleted >= 1.0, let file = obj.fileUrl?.lastPathComponent {
//                    callback(wself.directoryUrl.appendingPathComponent(file), nil)
//                }
//                else {
//                    obj.finished { (_, _) in
//                        wself.cache.insertOrUpdate(object: obj, forKey: source.absoluteString)
//                    }
//                    callback(nil, obj.download())
//                }
//            }
//            else {
//                let op = wself.scheduler.download(source)
//                op.finished { (_, _) in
//                    wself.cache.insertOrUpdate(object: op.ownRequest, forKey: source.absoluteString)
//                }
//                callback(nil, op)
//            }
//        }
//    }
//}
//
