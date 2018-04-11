//
//  HQDownloadRequest.swift
//  HQDownload
//
//  Created by Magee Huang on 4/10/18.
//  Copyright © 2018 com.personal.HQ. All rights reserved.
//

public struct HQDownloadRequest {

    // MARK: - Request
    public private(set) var request: URLRequest!
    
    public var fileName: String {
        return request.url?.lastPathComponent ?? "\(CFAbsoluteTimeGetCurrent())"
    }
    
    /// Request time out
    public var downloadTimeout: TimeInterval = 15 {
        didSet { request.timeoutInterval = downloadTimeout }
    }
    
    /// Allow invalid ssl cert
    public var allowInvalidSSLCert: Bool = true
    
    /// Whether or not use url cache, default is false and use custom cache data
    public var useUrlCache: Bool = false {
        didSet { request.cachePolicy = useUrlCache ? .useProtocolCachePolicy : .reloadIgnoringLocalCacheData }
    }
    
    public var handleCookies: Bool = true {
        didSet { request.httpShouldHandleCookies = handleCookies }
    }
    
    /// Download range
    public var downloadRange: (Int64?, Int64?)? {
        didSet {
            guard let range = downloadRange else {
                setValue(nil, forHTTPHeaderField: "Range")
                return
            }
            // Can add multi range
            let size = range.0 ?? 0
            if let total = range.1 {
                addValue("bytes=\(size)-\(total)", forHTTPHeaderField: "Range")
            }
            else {
                addValue("bytes=\(size)-", forHTTPHeaderField: "Range")
            }
        }
    }
    
    // MARK: - Authentication
    public var urlCredential: URLCredential?
    public var userPassAuth: (String, String)? {
        didSet {
            if let auth = userPassAuth {
                urlCredential = URLCredential(user: auth.0, password: auth.1, persistence: .forSession)
            }
        }
    }

    public init(_ url: URL, _ headers: [String: String]? = nil) {
        request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: downloadTimeout)
        request.httpShouldUsePipelining = true
        headers?.forEach { (k, v) in addValue(v, forHTTPHeaderField: k) }
    }
    
    /// Request's function
    public func value(forHTTPHeaderField field: String) -> String? {
        return request.value(forHTTPHeaderField: field)
    }
    
    public mutating func setValue(_ value: String?, forHTTPHeaderField field: String) {
        request.setValue(value, forHTTPHeaderField: field)
    }
    
    public mutating func addValue(_ value: String, forHTTPHeaderField field: String) {
        request.addValue(value, forHTTPHeaderField: field)
    }
}
