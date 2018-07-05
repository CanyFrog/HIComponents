//
//  Extensions.swift
//  HQDownload
//
//  Created by Magee Huang on 6/12/18.
//  Copyright © 2018 com.personal.HQ. All rights reserved.
//

import HQFoundation

public enum DownloadError: Error, CustomStringConvertible {
    case statusCodeInvalid(Int)
    case noCache304
    case error(Error)
    case cancel(String)
    
    public var description: String {
        switch self {
        case .statusCodeInvalid(let code):
            return "Response status code \(code) is invalid!"
        case .noCache304:
            return "URLSession current behavior will return 200 status code when the server respond 304 and URLCache hit. But this is not cache."
        case .cancel(let reason):
            return "Task be canceled, because \(reason)"
        case .error(let err):
            return "Task is error, \(err.localizedDescription)"
        }
    }
}


enum Event {
    case start(String, Int64) // start Name and size
    case progress(Progress)
    case newData(Data)
    case completed(URL) // completion file url
    case error(DownloadError)
}


extension Namespace where T: URLSession {
    static func create(_ options: OptionsInfo, delegate: URLSessionDelegate) -> T {
        let config = URLSessionConfiguration.default
//        config.allowsCellularAccess = true
//        config.timeoutIntervalForRequest = options.taskTimeout
//        config.timeoutIntervalForResource = options.taskTimeout
        
        return T(configuration: config, delegate: delegate, delegateQueue: nil)
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
