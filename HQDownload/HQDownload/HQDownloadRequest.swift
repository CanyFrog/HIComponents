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
        guard let url = request.url else { return "" }
        return "\(url.hashValue).\(url.pathExtension)"
    }
    
    public private(set) var fileUrl: URL?
    
    /// Auto retry count
    public var retryCount: Int = 3
    
    /// Whether or not background continue
    public var background: Bool = true
    
    /// Download range
    public var requestRange: (Int64?, Int64?)?
    @discardableResult public mutating func requestRange(_ range: (Int64?, Int64?)?) -> HQDownloadRequest {
        if range == nil {
            requestRange = nil
            request.setValue(nil, forHTTPHeaderField: "Range")
        }
        else {
            requestRange = range
            let size = range?.0 ?? 0
            if let total = range?.1 {
                request.setValue("bytes=\(size)-\(total)", forHTTPHeaderField: "Range")
            }
            else {
                request.setValue("bytes=\(size)-", forHTTPHeaderField: "Range")
            }
        }
        return self
    }
    
    public enum Method: String {
        case head = "HEAD"
        case get = "GET"
        case post = "POST"
    }
    
    
    public init(_ url: URL, _ directory: URL?, _ method: Method = .get) {
        request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: requestTimeout)
        request.httpShouldUsePipelining = true
        request.httpMethod = method.rawValue
        fileUrl = directory?.appendingPathComponent(fileName)
    }
    
    public init?(_ progress: HQDownloadProgress) {
        guard let url = progress.sourceUrl, let path = progress.fileUrl else { return nil }
        self.init(url, path)
        // Init set porperty can not trigger didSet function
        if progress.completedUnitCount > 0 || progress.totalUnitCount > 0 {
            requestRange((progress.completedUnitCount, progress.totalUnitCount))
        }
    }

    /// Request's function
    public func value(forHTTPHeaderField field: String) -> String? {
        return request.value(forHTTPHeaderField: field)
    }
    
    @discardableResult
    public mutating func headers(_ headers: [String: String?]) -> HQDownloadRequest {
        headers.forEach { self.request.setValue($1, forHTTPHeaderField: $0) }
        return self
    }
}
