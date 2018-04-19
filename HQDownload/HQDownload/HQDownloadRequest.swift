//
//  HQDownloadRequest.swift
//  HQDownload
//
//  Created by Magee Huang on 4/10/18.
//  Copyright © 2018 com.personal.HQ. All rights reserved.
//

public struct HQDownloadRequest {
    // MARK: - Connection
    
    /// Allow invalid ssl cert
    public var allowInvalidSSLCert: Bool = true
    
    /// Authentication
    public var urlCredential: URLCredential?
    public var userPassAuth: (String, String)? {
        didSet { if let auth = userPassAuth { urlCredential = URLCredential(user: auth.0, password: auth.1, persistence: .forSession) } }
    }
    
    
    // MARK: - Request settings
    
    public private(set) var request: URLRequest!
    
    /// Whether or not use url cache, default is false and use custom cache data
    public var useUrlCache: Bool = false {
        didSet { request.cachePolicy = useUrlCache ? .useProtocolCachePolicy : .reloadIgnoringLocalCacheData }
    }
    
    public var handleCookies: Bool = true {
        didSet { request.httpShouldHandleCookies = handleCookies }
    }
    
    /// Request time out
    public var requestTimeout: TimeInterval = 15 {
        didSet { request.timeoutInterval = requestTimeout }
    }
    
    // MARK: - Task
    
    public var fileName: String {
        return request.url?.lastPathComponent ?? ""
    }
    
    public private(set) var fileUrl: URL?
    
    /// Auto retry count
    public var retryCount: Int = 3
    
    /// Whether or not background continue
    public var background: Bool = true
    
    /// Download range
    public var requestRange: (Int64?, Int64?)?
    @discardableResult public mutating func requestRange(_ start: Int64? = nil, end: Int64? = nil) -> HQDownloadRequest {
        if start == nil && end == nil {
            requestRange = nil
            request.setValue(nil, forHTTPHeaderField: "Range")
        }
        else {
            requestRange = (start, end)
            let size = start ?? 0
            if let total = end {
                request.setValue("bytes=\(size)-\(total)", forHTTPHeaderField: "Range")
            }
            else {
                request.setValue("bytes=\(size)-", forHTTPHeaderField: "Range")
            }
        }
        return self
    }
    
    ///
    public init(_ url: URL, _ file: URL?, _ prefetch: Bool = false) {
        request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: requestTimeout)
        request.httpShouldUsePipelining = true
        if prefetch {
            request.httpMethod = "HEAD"
        }
        fileUrl = file
    }
    
//    public init?(_ progress: HQDownloadProgress) {
//        guard let url = progress.sourceURL, let path = progress.fileURL else { return nil }
//        self.init(url, path)
//        // Init set porperty can not trigger didSet function
//        downloadRange = (progress.completedUnitCount, progress.totalUnitCount)
//        setRange()
//    }

    /// Request's function
    public func value(forHTTPHeaderField field: String) -> String? {
        return request.value(forHTTPHeaderField: field)
    }
    
    
    public mutating func headers(_ headers: [String: String?]) -> HQDownloadRequest {
        headers.forEach { self.request.setValue($1, forHTTPHeaderField: $0) }
        return self
    }
}
