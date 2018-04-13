//
//  HQDownloadProgress.swift
//  HQDownload
//
//  Created by qihuang on 2018/4/12.
//  Copyright © 2018年 com.personal.HQ. All rights reserved.
//

public class HQdownloadProgress: Progress, Codable {
    public override var completedUnitCount: Int64 {
        didSet {
            if completedUnitCount >= totalUnitCount {
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
    
    public var finishedHandler: (() -> Void)?
    
    public func start() {
        startHandler?()
    }
    
    public override init(parent parentProgressOrNil: Progress?, userInfo userInfoOrNil: [ProgressUserInfoKey : Any]? = nil) {
        super.init(parent: parentProgressOrNil, userInfo: userInfoOrNil)
    }
    
    public required init(from decoder: Decoder) throws {
        self.init()
    }
    
    public func encode(to encoder: Encoder) throws {
        
    }
}
