//
//  HQDownloadRequest.swift
//  HQDownload
//
//  Created by Magee Huang on 4/10/18.
//  Copyright © 2018 com.personal.HQ. All rights reserved.
//
import HQFoundation

public enum HQDownloadError: CustomStringConvertible {
    case notEnoughSpace
    case taskCancel
    case taskError(Error)
    
    public var description: String {
        switch self {
        case .notEnoughSpace:
            return "Not enough disk space save file"
        case .taskCancel:
            return "Task was cancelled"
        case .taskError(let err):
            return "System error: \(err.localizedDescription)"
        }
    }
}

public final class HQDownloadRequest {
    // MARK: - Connection Authentication
    /// Allow invalid ssl cert
    public var allowInvalidSSLCert: Bool = true
    
    /// Authentication
    public var urlCredential: URLCredential?
    public var userPassAuth: (String, String)? {
        didSet { if let auth = userPassAuth { urlCredential = URLCredential(user: auth.0, password: auth.1, persistence: .forSession) } }
    }
    
    
    // MARK: - Request
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
    
    /// Request's function
    public func value(forHTTPHeaderField field: String) -> String? {
        return request.value(forHTTPHeaderField: field)
    }
    
    @discardableResult
    public func headers(_ headers: [String: String?]) -> HQDownloadRequest {
        headers.forEach { self.request.setValue($1, forHTTPHeaderField: $0) }
        return self
    }
    
    /// Download range
    public var requestRange: (Int64?, Int64?)?
    @discardableResult public func requestRange(_ range: (Int64?, Int64?)?) -> HQDownloadRequest {
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
    
    
    // MARK: - Progress
    public private(set) var completedUnitCount: Int64 = 0
    public private(set) var totalUnitCount: Int64 = 0
    public var fractionCompleted: Double {
        if totalUnitCount == 0 { return 0 }
        return Double(completedUnitCount) / Double(totalUnitCount)
    }
    
    
    // MARK: - Callbacks
    public typealias StartedClosure = (Int64) -> Void
    private var startedHandlers = [StartedClosure]()
    private var startedLock = DispatchSemaphore(value: 1)
    
    public typealias FinishedClosure = (URL?, HQDownloadError?) -> Void
    private var finishedHandlers = [FinishedClosure]()
    private var finishedLock = DispatchSemaphore(value: 1)
    
    public typealias ProgressClosure = (Int64, Double) -> Void
    private var progressHandler = [ProgressClosure]()
    private var progressLock = DispatchSemaphore(value: 1)
    
    
    // MARK: - Task
    public var fileName: String {
        guard let url = request.url else { return "" }
        return "\(url.hashValue)\(url.absoluteString.hashValue)\(url.pathExtension.hashValue)"
    }
    
    public private(set) var error: HQDownloadError?
    
    public private(set) var fileUrl: URL?
    /// Auto retry count
    public var retryCount: Int = 3
    
    /// Whether or not background continue
    public var background: Bool = true
    
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
}

public extension HQDownloadRequest {
    @discardableResult
    public func download() -> HQDownloadOperation {
        let operation = HQDownloadOperation(self)
        operation.start()
        return operation
    }
}


// MARK: - Call back invoke functions
public extension HQDownloadRequest {
    @discardableResult
    public func started(_ callback: @escaping StartedClosure) -> HQDownloadRequest {
        HQDispatchLock.semaphore(startedLock) { startedHandlers.append(callback) }
        return self
    }
    public func start(_ total: Int64) {
        totalUnitCount = total
        HQDispatchLock.semaphore(startedLock) {
            startedHandlers.forEach {(call) in
                call(total)
            }
        }
    }
    
    @discardableResult
    public func finished(_ callback: @escaping FinishedClosure) -> HQDownloadRequest {
        HQDispatchLock.semaphore(finishedLock) { finishedHandlers.append(callback) }
        return self
    }
    public func finish(_ error: HQDownloadError? = nil) {
        self.error = error
        HQDispatchLock.semaphore(finishedLock) {
            let url = fileUrl
            finishedHandlers.forEach { (call) in
                call(url, error)
            }
        }
    }
    
    @discardableResult
    public func progress(_ callback: @escaping ProgressClosure) -> HQDownloadRequest {
        HQDispatchLock.semaphore(progressLock) { progressHandler.append(callback) }
        return self
    }
    public func progress(_ received: Int64) {
        completedUnitCount += received
        HQDispatchLock.semaphore(progressLock) {
            let completed = completedUnitCount
            let fraction = fractionCompleted
            progressHandler.forEach { (call) in
                call(completed, fraction)
            }
        }
    }
}

// MARK: - Codable
extension HQDownloadRequest: Codable {
    enum CodingKeys: String, CodingKey {
//        case urlCredential
        case sourceUrl
        case fileUrl
//        case rangeStart
//        case rangeEnd
        case completedUnitCount
        case totalUnitCount
        case retryCount
        case background
    }
    
    public convenience init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let file = try values.decode(URL.self, forKey: .fileUrl)
        let source = try values.decode(URL.self, forKey: .sourceUrl)
        self.init(source, file.deletingLastPathComponent())
//        urlCredential = try values.decode(URLCredential.self, forKey: .urlCredential)
        if let completed = try? values.decode(Int64.self, forKey: .completedUnitCount), let total = try? values.decode(Int64.self, forKey: .totalUnitCount) {
            completedUnitCount = completed
            totalUnitCount = total
            requestRange((completedUnitCount, totalUnitCount))
        }
        
        if let retry = try? values.decode(Int.self, forKey: .retryCount) {
            retryCount = retry
        }
        
        if let back = try? values.decode(Bool.self, forKey: .background) {
            background = back
        }
//        let rangeStart = try? values.decode(Int64.self, forKey: .rangeStart)
//        let rangeEnd = try? values.decode(Int64.self, forKey: .rangeEnd)
//        requestRange((rangeStart, rangeEnd))
    }
    
    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(fileUrl, forKey: .fileUrl)
        try values.encode(request.url, forKey: .sourceUrl)
        try values.encode(completedUnitCount, forKey: .completedUnitCount)
        try values.encode(totalUnitCount, forKey: .totalUnitCount)
        try values.encode(retryCount, forKey: .retryCount)
        try values.encode(background, forKey: .background)
    }
}

