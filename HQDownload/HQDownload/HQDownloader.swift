//
//  HQDownloader.swift
//  HQDownload
//
//  Created by qihuang on 2018/3/27.
//  Copyright © 2018年 com.personal.HQ. All rights reserved.
//

// TODO: Auto retry
import HQFoundation

public final class HQDownloader: Operation {
    // MARK: - Session & Task
    
    /// This is weak because it is injected by whoever manages this session. If this gets nil-ed out, we won't be able to run the task associated with this operation
    private weak var injectSession: URLSession?
    
    /// This is set if we're using not using an injected NSURLSession. We're responsible of invalidating this one
    private lazy var ownSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = config.taskTimeout
        configuration.timeoutIntervalForResource = config.taskTimeout // From iOS 8, use this porperty, otherwise not call delegate function
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()
    
    private var session: URLSession { return injectSession ?? ownSession }
    
    public private(set) var task: URLSessionTask?
    
    
    // MARK: - Request & Response
    
    /// The request used by the operation's task
    public private(set) var request: URLRequest!
    
    public private(set) var response: URLResponse?
    
    
    // MARK: - Call backs
    public typealias StartedClosure = (URL, Int64) -> Void
    private var startedHandlers = [StartedClosure]()
    private var startedLock = DispatchSemaphore(value: 1)
    
    public typealias FinishedClosure = (URL?, HQDownloadError?) -> Void
    private var finishedHandlers = [FinishedClosure]()
    private var finishedLock = DispatchSemaphore(value: 1)
    
    public typealias ProgressClosure = (Int64, Float) -> Void
    private var progressHandler = [ProgressClosure]()
    private var progressLock = DispatchSemaphore(value: 1)
    
    
    // MARK: - Opertion properties
    
    open override var isConcurrent: Bool { return true }
    open override var isAsynchronous: Bool { return true }
    
    public override var isExecuting: Bool { return _executing }
    private var _executing = false {
        willSet { willChangeValue(forKey: "isExecuting") }
        didSet { didChangeValue(forKey: "isExecuting") }
    }
    
    public override var isFinished: Bool { return _finished }
    private var _finished = false {
        willSet { willChangeValue(forKey: "isFinished") }
        didSet { didChangeValue(forKey: "isFinished") }
    }
    
    
    /// Configuration
    public private(set) var config: HQDownloadConfig!
    
    /// Task error
    public private(set) var error: HQDownloadError?
    
    /// File stream
    private var stream: OutputStream?
    
    /// Background task id
    private var backgroundTaskId: UIBackgroundTaskIdentifier?
    
    
    public init(source: URL, config: HQDownloadConfig = HQDownloadConfig(), session: URLSession? = nil) {
        super.init()
        injectSession = session
        self.config = config
        createRequest(source: source)
    }
    
    
    public override func start() {
        objc_sync_enter(self)
        guard !isCancelled else { _finished = true; return }
        
        // Add background task
        if config.taskInBackground && backgroundTaskId == nil {
            backgroundTaskId = UIApplication.shared.beginBackgroundTask { [weak self] in
                guard let wSelf = self else { return }
                wSelf.cancel()  // Handle background task finish
                UIApplication.shared.endBackgroundTask(wSelf.backgroundTaskId!)
                wSelf.backgroundTaskId = UIBackgroundTaskInvalid
            }
        }
        // Create session task
        task = session.dataTask(with: request)
        _executing = true
        objc_sync_exit(self)
        
        guard let task = task else { done(); return }
        
        // Set task priority, priority is Float, so optional settings
        task.priority = config.priority
        
        // Start task
        task.resume()
        
        // If task finished, remove background task
        if let backgroundTaskId = backgroundTaskId, backgroundTaskId != UIBackgroundTaskInvalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskId)
            self.backgroundTaskId = UIBackgroundTaskInvalid
        }
    }
    
    public override func cancel() {
        if isFinished { return }
        super.cancel()
        if let task = task {
            task.cancel()
            self.task = nil
            // add judge to avoid trigger KVO
            if isExecuting { _executing = false }
            if !isFinished { _finished = true }
        }
    }
    
    public func cancel(resumeData: (Data?)->Void) {
        cancel()
        resumeData(try? JSONEncoder().encode(config))
    }
    
    deinit {
        closeStream()
        if injectSession == nil { ownSession.invalidateAndCancel() }
    }
}


// MARK: - State & Helper function
private extension HQDownloader {
    func done() {
        task = nil
        _finished = true
        _executing = false
    }
    
    func openStream() {
        let directory = config.fileUrl.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: directory.path) {
            do { try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil) }
            catch { cancel(); return }
        }
        stream = OutputStream(url: config.fileUrl, append: true)
        stream?.schedule(in: RunLoop.current, forMode: .defaultRunLoopMode)
        stream?.open()
    }
    
    func closeStream() {
        stream?.remove(from: RunLoop.current, forMode: .defaultRunLoopMode)
        stream?.close()
    }
    
    private func createRequest(source: URL) {
        request = URLRequest(url: source, cachePolicy: config.useUrlCache ? .useProtocolCachePolicy : .reloadIgnoringLocalCacheData, timeoutInterval: config.taskTimeout)
        request.httpShouldUsePipelining = true
        request.httpShouldHandleCookies = config.handleCookies
        if config.fetchFileInfo { request.httpMethod = "HEAD" }
        config.headers.forEach{ request.setValue($1, forHTTPHeaderField: $0) }
        
        guard config.rangeStart * config.rangeEnd * config.completedCount >= 0 else { return }
        let start = max(0, max(config.rangeStart, config.completedCount))
        if config.rangeEnd > 0 {
            request.setValue("bytes=\(start)-\(config.rangeEnd)", forHTTPHeaderField: "Range")
        }
        else {
            request.setValue("bytes=\(start)-", forHTTPHeaderField: "Range")
        }
    }
}


// MARK: - Call backs
public extension HQDownloader {
    @discardableResult public func started(callback: @escaping StartedClosure) -> Self {
        HQDispatchLock.semaphore(startedLock) { startedHandlers.append(callback) }
        return self
    }
    private func invokeStarted(_ total: Int64) {
        config.execptedCount = total
        HQDispatchLock.semaphore(startedLock) {
            startedHandlers.forEach { [weak self] (call) in
                guard let wself = self else { return }
                call(wself.config.fileUrl, total)
            }
        }
    }
    
    @discardableResult public func progress(_ callback: @escaping ProgressClosure) -> Self {
        HQDispatchLock.semaphore(progressLock) { progressHandler.append(callback) }
        return self
    }
    private func invokeProgress(_ received: Int64) {
        config.completedCount += received
        HQDispatchLock.semaphore(progressLock) {
            progressHandler.forEach { [weak self] (call) in
                guard let wself = self else { return }
                call(wself.config.completedCount, wself.config.progressPercent)
            }
        }
    }
    
    @discardableResult public func finished(_ callback: @escaping FinishedClosure) -> Self {
        HQDispatchLock.semaphore(finishedLock) { finishedHandlers.append(callback) }
        return self
    }
    private func invokeFinished(_ taskError: HQDownloadError? = nil) {
        error = taskError
        HQDispatchLock.semaphore(finishedLock) {
            finishedHandlers.forEach { [weak self] (call) in
                guard let wself = self else { return }
                call(wself.config.fileUrl, wself.error)
            }
        }
    }
}


// MARK: - URLSessionDataDelegate
extension HQDownloader: URLSessionDataDelegate {
    /// datatask first receive response
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        
        var disposition = URLSession.ResponseDisposition.allow
        self.response = response
        
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 200
        var valid = statusCode < 400
        
        //'304 Not Modified' is an exceptional one. It should be treated as cancelled if no cache data  
        //URLSession current behavior will return 200 status code when the server respond 304 and URLCache hit. But this is not a standard behavior and we just add a check
        var urlCache: URLCache! = session.configuration.urlCache
        if urlCache == nil { urlCache = URLCache.shared }
        
        if (statusCode == 304 && urlCache.cachedResponse(for: request)?.data == nil) {
            valid = false
        }
        
        if valid {
            config.fileName = response.suggestedFilename ?? request.url!.lastPathComponent
            invokeStarted(max(0, max(response.expectedContentLength, config.execptedCount)))
            if !config.fetchFileInfo { openStream() }
        }
        else {
            // if not valid, cancel request. the session will call complete delegate function, so do not need invoke complete callback
            disposition = .cancel
        }
        
        completionHandler(disposition)
    }
    
    
    /// request receive data callback
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if let stream = stream, stream.hasSpaceAvailable {
            stream.write([UInt8](data), maxLength: data.count)
            invokeProgress(Int64(data.count))
        }
        else {
            cancel() // If not enough space, cancel task
        }
    }

    
    /// task completed
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let err = error else { done(); invokeFinished(); return }
        
        if (err as NSError).code == -999 {
            done() // Task cancel, did not retry
            if let stream = stream, !stream.hasSpaceAvailable { invokeFinished(HQDownloadError.notEnoughSpace) } // No enough space cancel
            else { invokeFinished(HQDownloadError.taskError(err)) }
            return
        }
            
        if config.autoRetryCount <= 0 {
            done()
            invokeFinished(HQDownloadError.taskError(err))
        }
        else {
            let source = request.url!
            createRequest(source: source)
            start()
            config.autoRetryCount -= 1
        }
    }
    
    
    /// task begin and authentication
    public func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        var disposition = URLSession.AuthChallengeDisposition.performDefaultHandling
        var inlineCred: URLCredential? = nil
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust { // method is trust server
            if config.allowInvalidSSLCert {
                disposition = .useCredential
                // when authenticationMethod is ServerTrust, must be not nil
                inlineCred = URLCredential(trust: challenge.protectionSpace.serverTrust!)
            }
        }
        else {
            if challenge.previousFailureCount == 0 { // previos never failure
                if let cred = config.urlCredential { // use custom credential
                    inlineCred = cred
                    disposition = .useCredential
                }
                else { // cancel authentication
                    disposition = .cancelAuthenticationChallenge
                }
            }
            else { // previos failure
                disposition = .cancelAuthenticationChallenge
            }
        }
        
        completionHandler(disposition, inlineCred)
    }
    
    /// Handle session cache
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse, completionHandler: @escaping (CachedURLResponse?) -> Void) {
        
        // remove response prevent use cache
        completionHandler(config.useUrlCache ? proposedResponse : nil)
    }
    
    /// If session is invalid, call this function
    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        cancel()
    }
}


// MARK: --



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

// MARK: - Config
public struct HQDownloadConfig {
    // MARK: - Options
    
    /// Task priority
    public var priority: Float  = URLSessionTask.defaultPriority
    
    public var useUrlCache: Bool = false
    
    public var taskInBackground: Bool = false
    
    public var handleCookies: Bool = true
    
    public var allowInvalidSSLCert: Bool = true
    
    public var fetchFileInfo: Bool = false
    
    // MARK: - Connection Authentication
    public var urlCredential: URLCredential?
    
    public var userPassAuth: (String, String)? {
        didSet { if let auth = userPassAuth { urlCredential = URLCredential(user: auth.0, password: auth.1, persistence: .forSession) } }
    }
    
    
    // MARK: - Request
    // Task time out
    public var taskTimeout: TimeInterval = 15
    
    public typealias Header = [String: String?]
    public var headers = Header()
    
    // MARK: - Configure
    public var directory: String = "FileCacheDirectory"
    
    public var fileName: String = "Unknown"
    
    public var fileUrl: URL { return URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!).appendingPathComponent(directory, isDirectory: true).appendingPathComponent(fileName) }
    
    public var autoRetryCount: UInt = 3
    
    public var range: Range<Int64>?
    public var rangeStart: Int64 = -1
    public var rangeEnd: Int64 = -1
    
    public var completedCount: Int64 = 0
    public var execptedCount: Int64 = -1
    public var progressPercent: Float {
        guard execptedCount > 0 else { return 0 }
        return Float(completedCount) / Float(execptedCount)
    }
    
    public var subConfigs: [HQDownloadConfig]?
    
    public init() { }
}

extension HQDownloadConfig: Codable {
    enum ConfigKeys: String, CodingKey {
        case urlCredential
        case taskInBackground
        case headers
        case directory
        case rangeStart
        case rangeEnd
        case completedCount
        case execptedCount
        case fileName
    }
    
    public init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: ConfigKeys.self)
        let urlCredData = try container.decode(Data.self, forKey: .urlCredential)
        urlCredential = NSKeyedUnarchiver.unarchiveObject(with: urlCredData) as? URLCredential
        headers = try container.decode(Header.self, forKey: .headers)
        directory = try container.decode(String.self, forKey: .directory)
        taskInBackground = try container.decode(Bool.self, forKey: .taskInBackground)
        rangeStart = try container.decode(Int64.self, forKey: .rangeStart)
        rangeEnd = try container.decode(Int64.self, forKey: .rangeEnd)
        completedCount = try container.decode(Int64.self, forKey: .completedCount)
        execptedCount = try container.decode(Int64.self, forKey: .execptedCount)
        fileName = try container.decode(String.self, forKey: .fileName)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: ConfigKeys.self)
        let urlCredData = NSKeyedArchiver.archivedData(withRootObject: urlCredential as Any)
        try container.encode(urlCredData, forKey: .urlCredential)
        try container.encode(headers, forKey: .headers)
        try container.encode(directory, forKey: .directory)
        try container.encode(taskInBackground, forKey: .taskInBackground)
        try container.encode(rangeStart, forKey: .rangeStart)
        try container.encode(rangeEnd, forKey: .rangeEnd)
        try container.encode(completedCount, forKey: .completedCount)
        try container.encode(execptedCount, forKey: .execptedCount)
        try container.encode(fileName, forKey: .fileName)
    }
}
