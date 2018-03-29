//
//  HQDownloadUtil.swift
//  HQDownload
//
//  Created by qihuang on 2018/3/28.
//  Copyright © 2018年 com.personal.HQ. All rights reserved.
//

import Foundation

public struct HQDownloadOptions: OptionSet {
    public let rawValue: UInt
    
    /// Put the download in the low queue priority and task priority.
    public static let lowPriority          = HQDownloadOptions(rawValue: 1 << 0)
    
    /// By default, request prevent the use of NSURLCache. With this flag, used custom cache.
    public static let useUrlCache          = HQDownloadOptions(rawValue: 1 << 1)
    
    /// continue the download of the data if the app goes to background.
    public static let continueInBackground = HQDownloadOptions(rawValue: 1 << 2)
    
    /// Handles cookies stored in NSHTTPCookieStore by setting NSMutableURLRequest.HTTPShouldHandleCookies = YES;
    public static let handleCookies        = HQDownloadOptions(rawValue: 1 << 3)
    
    /// Enable to allow untrusted SSL certificates
    public static let allowInvalidSSLCert  = HQDownloadOptions(rawValue: 1 << 4)
    
    public static let highPriority         = HQDownloadOptions(rawValue: 1 << 5)
    
    /// Save while downloading
    public static let streamDownload       = HQDownloadOptions(rawValue: 1 << 6)
    
    /// Save cache, can offline continue
    public static let offLineContinue      = HQDownloadOptions(rawValue: 1 << 7)
    
    public init(rawValue: HQDownloadOptions.RawValue) {
        self.rawValue = rawValue
    }
}

public typealias HQDownloaderProgressClosure = ((_ data: Data?, _ receivedSize: Int, _ expectedSize: Int, _ targetUrl: URL)->Void)
public typealias HQDownloaderCompletedClosure = ((_ error: Error?)->Void)


public class HQDownloadCallback: Equatable {
    var progressClosure: HQDownloaderProgressClosure?
    var completedClosure: HQDownloaderCompletedClosure?
    
    init(progress: HQDownloaderProgressClosure?, completed: HQDownloaderCompletedClosure?) {
        progressClosure = progress
        completedClosure = completed
    }
    
    private static func getPointer(_ obj: HQDownloadCallback?) -> UnsafeRawPointer? {
        guard let obj = obj else { return nil }
        return UnsafeRawPointer(Unmanaged.passUnretained(obj).toOpaque())
    }
    
    public static func ==(lhs: HQDownloadCallback, rhs: HQDownloadCallback) -> Bool {
        let lp = getPointer(lhs)
        let rp = getPointer(rhs)
        return lp == rp && rp == lp
    }
}

public struct HQDownloadToken {
    var url: URL
    var operationToken: AnyObject?
    weak var operation: HQDownloadOperation?
    
    func cancel() {
        if let operation = operation {
            let _ = operation.cancel(operationToken)
        }
    }
}


public enum HQDownloadError: Error, CustomStringConvertible {
    case taskInitFailure(String, Int)
    
    public var description: String {
        switch self {
        case .taskInitFailure(let file, let line):
            return "Task initialize failure in file (\(file)) and lines \(line)!"
        }
    }
}
