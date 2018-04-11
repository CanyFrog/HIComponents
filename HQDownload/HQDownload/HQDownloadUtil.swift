//
//  HQDownloadUtil.swift
//  HQDownload
//
//  Created by qihuang on 2018/3/28.
//  Copyright © 2018年 com.personal.HQ. All rights reserved.
//

import Foundation

public typealias HQDownloadCallback = (_ url: URL, _ progress: Progress, _ dataPath: URL, _ error: Error?, _ finished: Bool) -> Void

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
    
    public init(rawValue: HQDownloadOptions.RawValue) {
        self.rawValue = rawValue
    }
}



