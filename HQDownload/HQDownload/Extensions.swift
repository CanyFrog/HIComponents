//
//  Extensions.swift
//  HQDownload
//
//  Created by Magee Huang on 6/12/18.
//  Copyright © 2018 com.personal.HQ. All rights reserved.
//

import HQFoundation

extension Namespace where T: URLSession {
    static func create(_ options: OptionsInfo) -> T {
        return T(configuration: .default)
    }
}



extension URLRequest: Namespaceable {}
extension Namespace where T == URLRequest {
    static func create(_ options: OptionsInfo) -> T? {
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
        return request
    }
}
