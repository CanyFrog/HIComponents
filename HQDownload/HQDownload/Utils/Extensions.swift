//
//  Utils.swift
//  HQDownload
//
//  Created by HonQi on 6/12/18.
//  Copyright © 2018 HonQi Indie. All rights reserved.
//

import HQFoundation

// MARK: - Extension
extension Namespace where T: URLSession {
    internal static func create(_ options: OptionsInfo, delegate: URLSessionDelegate) -> T {
        var config: URLSessionConfiguration! = nil
        if options.backgroundSession {
            config = URLSessionConfiguration.background(withIdentifier: UUID().uuidString)
            // TODO: Pass identifier to other object
        }
        else {
            config = URLSessionConfiguration.default
        }
        
        config.allowsCellularAccess = !options.onlyWifiAccess
        //        config.timeoutIntervalForRequest = options.taskTimeout
        //        config.timeoutIntervalForResource = options.taskTimeout
        return T(configuration: config, delegate: delegate, delegateQueue: nil)
    }
}

extension URLRequest: Namespaceable {}
extension Namespace where T == URLRequest {
    internal static func create(_ options: OptionsInfo) -> T? {
        guard let url = options.sourceUrl else {
            return nil
        }
        var request = URLRequest(url: url,
                                 cachePolicy: options.useUrlCache ? .useProtocolCachePolicy : .reloadIgnoringLocalCacheData,
                                 timeoutInterval: options.taskTimeout)
        //        request.httpShouldUsePipelining = true // 不必等到response， 就可以再次请求。但是取决于服务器响应的顺序和客户端请求顺序一致，否则容易出问题
        request.httpShouldHandleCookies = options.handleCookies
        
        let rangeStart = options.completedCount
        let rangeEnd = options.exceptedCount
        
        if let start = rangeStart, let end = rangeEnd {
            request.setValue("bytes=\(start)-\(end)", forHTTPHeaderField: "Range")
        }
        else if let start = rangeStart {
            request.setValue("bytes=\(start)-", forHTTPHeaderField: "Range")
        }
        else if let end = rangeEnd {
            request.setValue("bytes=0-\(end)", forHTTPHeaderField: "Range")
        }
        return request
    }
}
