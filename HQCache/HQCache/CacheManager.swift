//
//  CacheManager.swift
//  HQCache
//
//  Created by qihuang on 2018/4/5.
//  Copyright © 2018年 com.personal.HQ. All rights reserved.
//

import Foundation


public final class CacheManager {
    public private(set) var memoryCache: MemoryCache!
    public private(set) var diskCache: DiskCache!
    
    public init(_ path: URL) {
        diskCache = DiskCache(path)
        if diskCache == nil { fatalError("Path is invalid") }
        memoryCache = MemoryCache()
        
    }
    public convenience init(_ name: String = "cacheManager") {
        self.init(URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!).appendingPathComponent(name))
    }
}

extension CacheManager {
    public func exist(forKey key: String) -> Bool {
        return memoryCache.exist(forKey:key) || diskCache.exist(forKey:key)
    }
    
    public func exist(forKey key: String, inBackThreadCallback callback: @escaping (String, Bool) -> Void) {
        if memoryCache.exist(forKey: key) {
            DispatchQueue.global(qos: .default).async {
                callback(key, true)
            }
        }
        else {
            diskCache.exist(forKey: key, inBackThreadCallback: callback)
        }
    }
    
    public func query<T: Codable>(objectForKey key: String) -> T? {
        var obj: T? = memoryCache.query(objectForKey: key)
        if obj == nil {
            obj = diskCache.query(objectForKey: key)
            if obj != nil {
                memoryCache.insertOrUpdate(object: obj, forKey: key)
            }
        }
        return obj
    }
    
    public func query<T: Codable>(objectForKey key: String, inBackThreadCallback callback: @escaping (String, T?) -> Void) {
        if let obj: T? = memoryCache.query(objectForKey: key) {
            DispatchQueue.global(qos: .default).async {
                callback(key, obj)
            }
        }
        else {
            diskCache.query(objectForKey: key) { (k: String, v: T?) in
                if v != nil && !self.memoryCache.exist(forKey: key) {
                    self.memoryCache.insertOrUpdate(object: v, forKey: k)
                }
                callback(k,v)
            }
        }
    }
    
    
    public func insert<T: Codable>(object obj: T, forKey key: String) {
        memoryCache.insertOrUpdate(object: obj, forKey: key)
        diskCache.insertOrUpdate(object: obj, forKey: key)
    }
    
    public func insertOrUpdate<T: Codable>(object obj: T, forKey key: String, inBackThreadCallback callback: @escaping () -> Void) {
        memoryCache.insertOrUpdate(object: obj, forKey: key)
        diskCache.insertOrUpdate(object: obj, forKey: key, inBackThreadCallback: callback)
    }
    
    
    public func delete(objectForKey key: String) {
        memoryCache.delete(objectForKey: key)
        diskCache.delete(objectForKey: key)
    }
    
    public func delete(objectForKey key: String, inBackThreadCallback callback: @escaping (String) -> Void) {
        memoryCache.delete(objectForKey: key)
        diskCache.delete(objectForKey: key, inBackThreadCallback: callback)
    }
    
    public func deleteAllCache() {
        memoryCache.deleteAllCache()
        diskCache.deleteAllCache()
    }
    
    public func deleteAllCache(inBackThread callback: @escaping () -> Void) {
        memoryCache.deleteAllCache()
        diskCache.deleteAllCache(inBackThread: callback)
    }
    
    public func deleteAllCache(withProgressClosure progress: @escaping (Int, Int, Bool) -> Void) {
        memoryCache.deleteAllCache()
        diskCache.deleteAllCache(withProgressClosure: progress)
    }
}