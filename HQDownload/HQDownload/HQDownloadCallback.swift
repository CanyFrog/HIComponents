//
//  HQDownloadCallback.swift
//  HQDownload
//
//  Created by qihuang on 2018/3/30.
//  Copyright © 2018年 com.personal.HQ. All rights reserved.
//

import Foundation


public typealias HQDownloaderProgressClosure = ((_ data: Data?, _ receivedSize: Int, _ expectedSize: Int, _ targetUrl: URL)->Void)
public typealias HQDownloaderCompletedClosure = ((_ error: Error?)->Void)

public class HQDownloadCallback: NSObject {
    
    public var url: URL?
    public weak var operation: HQDownloadOperation?
    public var progressClosure: HQDownloaderProgressClosure?
    public var completedClosure: HQDownloaderCompletedClosure?
    
    private override init() {
        super.init()
    }
    
    public convenience init(url: URL?, operation: HQDownloadOperation?, progress: HQDownloaderProgressClosure?, completed: HQDownloaderCompletedClosure?) {
        self.init()
        self.url = url
        self.operation = operation
        progressClosure = progress
        completedClosure = completed
    }
    
    public func cancel() {
        operation?.cancel(self)
    }
}

// TODO: Stream callback / Save callback / Decoder image callback
class HQDownloadSaveCallback: HQDownloadCallback {
    
}
