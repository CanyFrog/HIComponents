//
//  HQDownloadProgress.swift
//  HQDownload
//
//  Created by qihuang on 2018/4/12.
//  Copyright © 2018年 com.personal.HQ. All rights reserved.
//

public final class HQDownloadProgress: Progress {
    public override var completedUnitCount: Int64 {
        didSet {
            progressHandler?(completedUnitCount)
            if totalUnitCount > 0 && completedUnitCount >= totalUnitCount {
                finishedHandler?()
            }
        }
    }
    
    public override var fileURL: URL? {
        get {
            return userInfo[.init("fileURL")] as? URL
        }
        set {
            setUserInfoObject(newValue, forKey: .init("fileURL"))
        }
    }
    
    public var sourceURL: URL? {
        get {
            return userInfo[.init("sourceURL")] as? URL
        }
        set {
            setUserInfoObject(newValue, forKey: .init("sourceURL"))
        }
    }
    
    public var startHandler: (() -> Void)?
    
    /// if response no exception size(-1), never execute
    public var finishedHandler: (() -> Void)?
    
    public var progressHandler: ((Int64) -> Void)?
    
    public func start() {
        startHandler?()
    }

    public convenience init() {
        self.init(parent: nil, userInfo: nil)
    }
}

extension HQDownloadProgress: Codable {
    enum CodingKeys: String, CodingKey {
        case sourceUrl
        case fileUrl
        case completedUnitCount
        case totalUnitCount
//        case userInfo  ???
    }
    
    public convenience init(from decoder: Decoder) throws {
        self.init(parent: nil, userInfo: nil)
        let values = try decoder.container(keyedBy: CodingKeys.self)
        fileURL = try values.decode(URL.self, forKey: CodingKeys.fileUrl)
        sourceURL = try values.decode(URL.self, forKey: CodingKeys.sourceUrl)
        completedUnitCount = try values.decode(Int64.self, forKey: CodingKeys.completedUnitCount)
        totalUnitCount = try values.decode(Int64.self, forKey: CodingKeys.totalUnitCount)
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(fileURL, forKey: .fileUrl)
        try values.encode(sourceURL, forKey: .sourceUrl)
        try values.encode(completedUnitCount, forKey: .completedUnitCount)
        try values.encode(totalUnitCount, forKey: .totalUnitCount)
    }
}
