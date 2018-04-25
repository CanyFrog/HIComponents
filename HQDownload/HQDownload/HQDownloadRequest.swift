//
//  HQDownloadRequest.swift
//  HQDownload
//
//  Created by Magee Huang on 4/10/18.
//  Copyright © 2018 com.personal.HQ. All rights reserved.
//
import HQFoundation


public final class HQDownloadRequest {
    /// Request
    public private(set) var request: URLRequest!
    
//    public var fileName: String {
//        guard let url = request.url else { return "" }
//        return "\(url.hashValue)\(url.absoluteString.hashValue)\(url.pathExtension.hashValue)"
//    }
//
    public var fileUrl: URL { return config.directory.appendingPathComponent(record.fileName) }
    
    /// Record (progress)
    public lazy var record = HQDownloadRecord()
    
    /// Configure
    public private(set) var config: HQDownloadConfig!
    
    
    // MARK: - Callbacks
    public typealias StartedClosure = (URL, HQDownloadRecord) -> Void
    private var startedHandlers = [StartedClosure]()
    private var startedLock = DispatchSemaphore(value: 1)
    
    public typealias FinishedClosure = (URL?, HQDownloadError?) -> Void
    private var finishedHandlers = [FinishedClosure]()
    private var finishedLock = DispatchSemaphore(value: 1)
    
    public typealias ProgressClosure = (URL, HQDownloadRecord) -> Void
    private var progressHandler = [ProgressClosure]()
    private var progressLock = DispatchSemaphore(value: 1)
    
    public private(set) var error: HQDownloadError?
    
    public init(source: URL, config: HQDownloadConfig = HQDownloadConfig()) {
        request = URLRequest(url: source, cachePolicy: config.options.contains(.useUrlCache) ? .useProtocolCachePolicy : .reloadIgnoringLocalCacheData, timeoutInterval: config.taskTimeout)
        if config.options.contains(.fetchFileInfo) { request.httpMethod = "HEAD" }
        request.httpShouldUsePipelining  = true
        request.httpShouldHandleCookies = config.options.contains(.handleCookies)
        config.headers.forEach{ request.setValue($1, forHTTPHeaderField: $0) }
    }
    
    public convenience init(source: URL, record: HQDownloadRecord, config: HQDownloadConfig = HQDownloadConfig()) {
        self.init(source: source, config: config)
        self.record = record
        if let range = record.range {
            request.setValue(range.value, forHTTPHeaderField: range.key)
        }
    }
}


// MARK: - Call back invoke functions
public extension HQDownloadRequest {
    @discardableResult
    public func started(callback: @escaping StartedClosure) -> HQDownloadRequest {
        HQDispatchLock.semaphore(startedLock) { startedHandlers.append(callback) }
        return self
    }
    public func start(_ total: Int64) {
        record.execptedCount = total
        HQDispatchLock.semaphore(startedLock) {
            startedHandlers.forEach { [weak self] (call) in
                guard let wself = self else { return }
                call(wself.fileUrl, wself.record)
            }
        }
    }
    
    @discardableResult
    public func progress(_ callback: @escaping ProgressClosure) -> HQDownloadRequest {
        HQDispatchLock.semaphore(progressLock) { progressHandler.append(callback) }
        return self
    }
    public func progress(_ received: Int64) {
        record.completedCount += received
        HQDispatchLock.semaphore(progressLock) {
            progressHandler.forEach { [weak self] (call) in
                guard let wself = self else { return }
                call(wself.fileUrl, wself.record)
            }
        }
    }
    
    @discardableResult
    public func finished(_ callback: @escaping FinishedClosure) -> HQDownloadRequest {
        HQDispatchLock.semaphore(finishedLock) { finishedHandlers.append(callback) }
        return self
    }
    public func finish(_ taskError: HQDownloadError? = nil) {
        error = taskError
        HQDispatchLock.semaphore(finishedLock) {
            finishedHandlers.forEach { [weak self] (call) in
                guard let wself = self else { return }
                call(wself.fileUrl, wself.error)
            }
        }
    }
    
}




// MARK: - Codable
extension HQDownloadRequest: Codable {
    enum RequestKeys: String, CodingKey {
        case request
        case record
        case config
    }
    
    public convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: RequestKeys.self)
        let url = try container.decode(URL.self, forKey: .request)
        let decodeRecord = try container.decode(HQDownloadRecord.self, forKey: .record)
        let decodeConfig = try container.decode(HQDownloadConfig.self, forKey: .config)
        self.init(source: url, record: decodeRecord, config: decodeConfig)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: RequestKeys.self)
        try container.encode(request.url, forKey: .request)
        try container.encode(record, forKey: .record)
        try container.encode(config, forKey: .config)
    }
}



// MARK: - Error
public enum HQDownloadError: CustomStringConvertible {
    case notEnoughSpace
    case taskError(Error)
    
    public var description: String {
        switch self {
        case .notEnoughSpace:
            return "Not enough disk space save file"
        case .taskError(let err):
            return "URL session task error: \(err.localizedDescription)"
        }
    }
}

// MARK:- Global configure options
public struct HQDownloadOptions: OptionSet {
    /// Default contains priority default, handle cookies, allow ivalid ssl, no use url cache
    public static let `default`: HQDownloadOptions = [.priorityDefault, .handleCookies, .allowInvalidSSLCert]
    
    public let rawValue: UInt
    
    // MARK: - Operation priority
    public static let priorityLow          = HQDownloadOptions(rawValue: 1 << 0)
    
    public static let priorityHigh         = HQDownloadOptions(rawValue: 1 << 1)
    
    /// By default, request prevent the use of NSURLCache. With this flag, NSURLCache is used with default policies.
    public static let useUrlCache          = HQDownloadOptions(rawValue: 1 << 2)
    
    /// Continue the download of the file if the app goes to background
    public static let taskInBackground = HQDownloadOptions(rawValue: 1 << 3)
    
    /// Handles cookies stored in NSHTTPCookieStore by setting
    public static let handleCookies        = HQDownloadOptions(rawValue: 1 << 4)
    
    /// Enable to allow untrusted SSL certificates.
    public static let allowInvalidSSLCert  = HQDownloadOptions(rawValue: 1 << 5)
    
    /// Fetch file info, Http method is HEAD
    public static let fetchFileInfo        = HQDownloadOptions(rawValue: 1 << 6)
    
    public init(rawValue: HQDownloadOptions.RawValue) {
        self.rawValue = rawValue
    }
}

// MARK: - Config
public struct HQDownloadConfig {
    /// Options
    public var options: HQDownloadOptions = .default
    
    // MARK: - Connection Authentication
    public var urlCredential: URLCredential?
    
    public var userPassAuth: (String, String)? {
        didSet { if let auth = userPassAuth { urlCredential = URLCredential(user: auth.0, password: auth.1, persistence: .forSession) } }
    }
    
    // Task time out
    public var taskTimeout: TimeInterval = 15
    
    public typealias Header = [String: String?]
    public var headers = Header()
    
    // MARK: - Configure
    public var directory: URL = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!).appendingPathComponent("DownloadComponent", isDirectory: true)
    
    public var autoRetryCount: UInt = 0
    
    
    public init() { }
}

extension HQDownloadConfig: Codable {
    enum ConfigKeys: String, CodingKey {
        case options
        case urlCredential
        case taskTimeout
        case headers
        case directory
        case autoRetryCount
    }

    public init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: ConfigKeys.self)
        let optionsValue = try container.decode(UInt.self, forKey: .options)
        options = HQDownloadOptions(rawValue: optionsValue)
        let urlCredData = try container.decode(Data.self, forKey: .urlCredential)
        urlCredential = NSKeyedUnarchiver.unarchiveObject(with: urlCredData) as? URLCredential
        taskTimeout = try container.decode(TimeInterval.self, forKey: .taskTimeout)
        headers = try container.decode(Header.self, forKey: .headers)
        directory = try container.decode(URL.self, forKey: .directory)
        autoRetryCount = try container.decode(UInt.self, forKey: .autoRetryCount)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: ConfigKeys.self)
        try container.encode(options.rawValue, forKey: .options)
        let urlCredData = NSKeyedArchiver.archivedData(withRootObject: urlCredential as Any)
        try container.encode(urlCredData, forKey: .urlCredential)
        try container.encode(taskTimeout, forKey: .taskTimeout)
        try container.encode(headers, forKey: .headers)
        try container.encode(directory, forKey: .directory)
        try container.encode(autoRetryCount, forKey: .autoRetryCount)
    }
}



// MARK: - Record || Progress
public final class HQDownloadRecord: Codable {
    public var rangeStart: Int64?
    public var rangeEnd: Int64?
    
    public var completedCount: Int64 = 0
    public var execptedCount: Int64 = 0
    public var taskPercent: Float {
        return Float(completedCount) / Float(execptedCount)
    }
    
    public var fileName: String = "Unknown"
    public lazy var subRecords = [HQDownloadRecord]()

    public var range: (key:String, value:String)? {
        guard rangeStart != nil || rangeEnd != nil else { return nil }
        let start = rangeStart ?? 0
        if let end = rangeEnd {
            return ("Range", "bytes=\(start)-\(end)")
        }
        return ("Range", "bytes=\(start)-")
    }
}
