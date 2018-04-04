//
//  HQDiskCache.swift
//  HQCache
//
//  Created by Magee Huang on 3/26/18.
//  Copyright © 2018 com.personal.HQ. All rights reserved.
//

import Foundation
import HQSqlite

/*
 Structure:
 /Path/
        diskcache.sqlite
        diskcache.sqlite-shm
        diskcache.sqlite-wal
        /data/
                /data-files
                /....
        /trash/
                /wait for delete files
                /...
 */

public class HQDiskCache: HQCacheInBackProtocol {

    enum CacheLocation {
        case sqlite, file, mixed
    }
    
    // MARK: - Public
    public var name: String = "DiskCache"

    public var errorEnable = false

    public var countLimit: Int = Int.max

    public var costLimit: Int = Int.max

    public var ageLimit: TimeInterval = TimeInterval(INTMAX_MAX)

    public var autoTrimInterval: TimeInterval = 7 * 24 * 60 * 60

    /// The minimum free disk space (in bytes) which the cache should kept
    public var freeDiskSpaceLimit: Int = 0

    
    // MARK: - Save to disk or sqlite limits
    
    /// When object data size bigger than this value, stored as file; otherwise stored as data to sqlite will be faster
    /// value is 0 mean all object save as file, Int.max mean all save to sqlite
    public private(set) var saveToDiskCritical: Int = 20 * 1024 {
        didSet {
            if saveToDiskCritical == 0 {
                location = .file
            }
            else if saveToDiskCritical == Int.max {
                location = .sqlite
            }
            else {
                location = .mixed
            }
        }
    }
    internal var location: CacheLocation = .mixed
    
    
    
    // MARK: - Cache path
    public private(set) var cachePath: String! {
        didSet {
            dataPath = "\(cachePath)/data"
            trashPath = "\(cachePath)/trash"
        }
    }
    internal var dataPath: String!
    internal var trashPath: String!
    internal var backgroundTrashQueue = DispatchQueue(label: "com.trash.disk.cache.personal.HQ", qos: .utility, attributes: .concurrent)
    internal var taskLock = DispatchSemaphore(value: 1)
    internal var taskQueue = DispatchQueue(label: "com.disk.cache.personal.HQ", qos: .default, attributes: .concurrent)
    
    
    // MARK: - Custom Closure
    /// Custom archive or unarchive object closure, if nil, use NSCoding
    public var customArchiveObjectClosure: ((Any)->Data)?

    public var customUnarchiveObjectClosure: ((Data)->Any)?

    public var customNamedFileClosure: ((_ key: String)->String)?

    
    // MARK: - Sqlite
    internal var connect: HQSqliteConnection!
    internal var stmtDict = [String: HQSqliteStatement]()
    
    
    init?(_ path: String) {
        if path.isEmpty || path.count > PATH_MAX - 128 { fatalError("Error: Path is invalid") }
        var path = path
        cachePath = path.last == "/" ? String(path.removeLast()) : path
        do {
            try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
            try FileManager.default.createDirectory(atPath: dataPath, withIntermediateDirectories: true, attributes: nil)
            try FileManager.default.createDirectory(atPath: trashPath, withIntermediateDirectories: true, attributes: nil)
            if !dbConnect() { return nil }
            emptyTrashInBackground()
        } catch {
            return nil
        }
    }
}



// MARK: - Query & Check
extension HQDiskCache {
    
    func query<T>(objectForKey key: String) -> T? {
        return nil
    }
    func query<T>(objectForKey key: String, inBackThreadCallback callback: @escaping (String, T?) -> Void) {

    }
    
//    /// query cache data
//    /// - Returns: object
//    public func query<T: NSCoding>(objectForKey key: String) -> T? {
//        guard !key.isEmpty else { return nil }
//
//        let _ = taskLock.wait(timeout: .distantFuture)
//        _ = dbQuery(key)
//        taskLock.signal()
//
//    //        if let data = dict["data"] {
//    //            if
//    //        }
//        return nil
//    }
//
//    public func query<T: NSCoding>(objectForKey key: String, inBackThreadCallback callback: @escaping (String, T?) -> Void) {
//
//    }
//
    
    
    /// query cache file
    ///
    /// - Returns: file path
    func query(filePathForKey key: String) -> String? {
        return nil
    }
    
    func query(filePathForKey key: String, inBackThreadCallback callback: @escaping (String, String?) -> Void) {
        
    }
    
    
    /// Check
    public func exist(forKey key: String) -> Bool {
        guard !key.isEmpty else { return false }
        return dispatchAutoLock(taskLock, closure: { () -> Bool in
            return self.dbQuery(key) != nil
        })
    }
    
    public func exist(forKey key: String, inBackThreadCallback callback: @escaping (String, Bool) -> Void) {
        taskQueue.async { [weak self] in
            callback(key, self?.exist(forKey: key) ?? false)
        }
    }
    
    
    public func getTotalCount() -> Int {
        return dispatchAutoLock(taskLock, closure: { () -> Int in
            return self.dbQueryTotalItemCount()
        })
    }
    
    public func getTotalCount(inBackThread closure: @escaping (Int) -> Void) {
        taskQueue.async { [weak self] in
            closure(self?.getTotalCount() ?? 0)
        }
    }
    
    
    public func getTotalCost() -> Int {
        return dispatchAutoLock(taskLock) { () -> Int in
            return self.dbQueryTotalItemSize()
        }
    }
    
    public func getTotalCost(inBackThread closure: @escaping (Int) -> Void) {
        taskQueue.async { [weak self] in
            closure(self?.getTotalCount() ?? 0)
        }
    }
}

// MARK: - Insert & Update
extension HQDiskCache {
    
    public func insertOrUpdate(file path: String, forKey key: String) {
        
    }

    public func insertOrUpdate(file path: String, forKey key: String, inBackThreadCallback callback: @escaping () -> Void) {
        
    }
    
    
    public func insertOrUpdate<T>(object obj: T, forKey key: String, cost: Int = 0) {
        
    }
    
    public func insertOrUpdate<T>(object obj: T, forKey key: String, cost: Int = 0, inBackThreadCallback callback: @escaping () -> Void) {
        
    }
}



// MARK: - Delete
extension HQDiskCache {

    public func delete(objectForKey key: String) {
        guard !key.isEmpty else { return }
        dispatchAutoLock(taskLock) {
            self.dbDelete([key])
        }
    }
    public func delete(objectForKey key: String, inBackThreadCallback callback: @escaping (String) -> Void) {
        taskQueue.async { [weak self] in
            self?.delete(objectForKey: key)
            callback(key)
        }
    }

    
    public func deleteAllCache() {
//        dispatchAutoLock(taskLock) {
//            try? FileManager.default.removeItem(at: convertToUrl(cachePath))
//        }
    }
    
    public func deleteAllCache(inBackThread callback: @escaping () -> Void) {
        taskQueue.async { [weak self] in
            self?.deleteAllCache()
            callback()
        }
    }

    public func deleteAllCache(withProgressClosure progress: @escaping (Int, Int, Bool) -> Void) {

    }

    
    public func deleteCache(exceedToCount count: Int) {
        if count <= 0 {
            deleteAllCache()
        }
        else {
            dispatchAutoLock(taskLock, closure: {
                
            })
        }
    }
    
    public func deleteCache(exceedToCount count: Int, inBackThread complete: @escaping () -> Void) {
        taskQueue.async { [weak self] in
            self?.deleteCache(exceedToCount: count)
            complete()
        }
    }

    
    public func deleteCache(exceedToCost cost: Int) {
        
    }
    
    public func deleteCache(exceedToCost cost: Int, inBackThread complete: @escaping () -> Void) {
        taskQueue.async { [weak self] in
            self?.deleteCache(exceedToCost: cost)
            complete()
        }
    }

    
    public func deleteCache(exceedToAge age: TimeInterval) {
        dispatchAutoLock(taskLock) {
            self.dbDeleteTimerEarlierThan(age)
        }
    }
    
    public func deleteCache(exceedToAge age: TimeInterval, inBackThread complete: @escaping () -> Void) {
        taskQueue.async { [weak self] in
            self?.deleteCache(exceedToAge: age)
            complete()
        }
    }
}
