//
//  HQDownloadProgress.swift
//  HQDownload
//
//  Created by qihuang on 2018/4/12.
//  Copyright © 2018年 com.personal.HQ. All rights reserved.
//

import HQFoundation

public final class HQDownloadProgress {
    public enum HQDownloadError {
        case notEnoughSpace
        case taskError(Error)
    }
    public var taskError: HQDownloadError?
    
    // If is big file download, set this value
    public var taskRange: (Int64?, Int64?)?
    
    /// Progress
    public var completedUnitCount: Int64 = -1 
    public var totalUnitCount: Int64 = -1
    public var fractionCompleted: Double {
        return Double(completedUnitCount) / Double(totalUnitCount)
    }
    
    // Source link
    public var fileUrl: URL?
    public var sourceUrl: URL?
    
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
    
    // MARK: - Child
    private var childs = [HQDownloadProgress]()
    private var childLock = DispatchSemaphore(value: 1)
    
    public init() {}
    
    public convenience init(source: URL?, file: URL?, range: (Int64?, Int64?)? = nil) {
        self.init()
        sourceUrl = source
        fileUrl = file
        taskRange = range
    }
    
}


// MARK: - Call backs
extension HQDownloadProgress {
    @discardableResult
    public func started(_ callback: @escaping StartedClosure) -> HQDownloadProgress {
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
    public func finished(_ callback: @escaping FinishedClosure) -> HQDownloadProgress {
        HQDispatchLock.semaphore(finishedLock) { finishedHandlers.append(callback) }
        return self
    }
    public func finish(_ error: HQDownloadError? = nil) {
        taskError = error
        HQDispatchLock.semaphore(finishedLock) {
            let url = fileUrl
            finishedHandlers.forEach { (call) in
                call(url, error)
            }
        }
    }
    
    @discardableResult
    public func progress(_ callback: @escaping ProgressClosure) -> HQDownloadProgress {
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

extension HQDownloadProgress {
    public func addChild(_ progress: HQDownloadProgress) {
        HQDispatchLock.semaphore(childLock) {
            childs.append(progress)
        }
        progress.started { [weak self] (total) in
            self?.totalUnitCount += total
        }
        
        progress.progress { [weak self] (count, _) in
            self?.completedUnitCount += count
        }
    }
}

extension HQDownloadProgress: Codable {
    enum CodingKeys: String, CodingKey {
        case sourceUrl
        case fileUrl
        case completedUnitCount
        case totalUnitCount
        case rangeStart
        case rangeEnd
        case childs
    }

    public convenience init(from decoder: Decoder) throws {
        self.init()
        let values = try decoder.container(keyedBy: CodingKeys.self)
        fileUrl = try values.decode(URL.self, forKey: .fileUrl)
        sourceUrl = try values.decode(URL.self, forKey: .sourceUrl)
        completedUnitCount = try values.decode(Int64.self, forKey: .completedUnitCount)
        totalUnitCount = try values.decode(Int64.self, forKey: .totalUnitCount)
        childs = try values.decode(Array.self, forKey: .childs)
        let rangeStart = try? values.decode(Int64.self, forKey: .rangeStart)
        let rangeEnd = try? values.decode(Int64.self, forKey: .rangeEnd)
        if rangeStart != nil || rangeEnd != nil {
            taskRange = (rangeStart, rangeEnd)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(fileUrl, forKey: .fileUrl)
        try values.encode(sourceUrl, forKey: .sourceUrl)
        try values.encode(completedUnitCount, forKey: .completedUnitCount)
        try values.encode(totalUnitCount, forKey: .totalUnitCount)
        try values.encode(childs, forKey: .childs)
        if let r = taskRange {
            try values.encode(r.0, forKey: .rangeStart)
            try values.encode(r.1, forKey: .rangeEnd)
        }
    }
}
