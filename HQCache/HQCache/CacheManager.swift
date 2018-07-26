//
//  CacheManager.swift
//  HQCache
//
//  Created by HonQi on 2018/4/5.
//  Copyright © 2018年 HonQi Indie. All rights reserved.
//

import Foundation


public final class Cache {
    public private(set) var memory: MemoryCache!
    public private(set) var disk: DiskCache!

    public init(_ path: URL) {
        disk = DiskCache(path)
        if disk == nil { fatalError("Path is invalid") }
        memory = MemoryCache()
    }
    
    public convenience init(_ name: String = "Cache") {
        self.init(URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!).appendingPathComponent(name))
    }
}

extension Cache {
    public func contains(_ key: String) -> Bool {
        return memory.contains(key) || disk.contains(key)
    }

    public func object<T: Codable>(forKey key: String) -> T? {
        var obj: T? = memory.object(forKey: key)
        if obj == nil {
            obj = disk.object(forKey: key)
            if obj != nil {
                memory.setObject(obj, forKey: key)
            }
        }
        return obj
    }


    public func setObject<T: Codable>(_ obj: T, forKey key: String) {
        memory.setObject(obj, forKey: key)
        disk.setObject(obj, forKey: key)
    }


    public func removeObject(forKey key: String) {
        memory.removeObject(forKey: key)
        disk.removeObject(forKey: key)
    }

    
    public func removeAllObjects() {
        memory.removeAllObjects()
        disk.removeAllObjects()
    }


    public func removeAllObjects(progress: @escaping (Int, Int, Bool) -> Void) {
        memory.removeAllObjects()
        disk.removeAllObjects(progress: progress)
    }
}
