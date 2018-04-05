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
        /sqlite/
                /diskcache.sqlite
                /diskcache.sqlite-shm
                /diskcache.sqlite-wal
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
            sqlitePath = "\(cachePath)/sqlite"
        }
    }
    internal var sqlitePath: String!
    internal var dataPath: String!
    internal var trashPath: String!
    
    internal var backgroundTrashQueue = DispatchQueue(label: "com.trash.disk.cache.personal.HQ", qos: .utility, attributes: .concurrent)
    internal var taskLock = DispatchSemaphore(value: 1)
    internal var taskQueue = DispatchQueue(label: "com.disk.cache.personal.HQ", qos: .default, attributes: .concurrent)
    
    
    // MARK: - Custom Closure
    /// Custom archive or unarchive object closure, if nil, use NSCoding
    public var customArchiveObjectClosure: ((Any)->Data)?

    public var customUnarchiveObjectClosure: ((Data)->Any)?

//    public var customNamedFileClosure: ((_ key: String)->String)?

    
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
            clearCacheTiming()
        } catch {
            return nil
        }
    }
}



// MARK: - Query & Check
extension HQDiskCache {
    
    public func query<T: NSCoding>(objectForKey key: String) -> T? {
        guard !key.isEmpty, let data = queryDataFromSqlite(key) else { return nil }
        if let unar = customUnarchiveObjectClosure { return unar(data) as? T }
        return NSKeyedUnarchiver.unarchiveObject(with: data) as? T
    }
    
    public func query<T: NSCoding>(objectForKey key: String, inBackThreadCallback callback: @escaping (String, T?) -> Void) {
        taskQueue.async { [weak self] in
            let value: T? = self?.query(objectForKey: key)
            callback(key, value)
        }
    }

    
    /// query cache file path, use for big file, such as video & audio and so on
    ///
    /// - Returns: file path
    public func query(filePathForKey key: String) -> String? {
        guard !key.isEmpty else { return nil }
        let _ = taskLock.wait(timeout: .distantFuture)
        defer { taskLock.signal() }
        let resDict = dbQuery(key)
        
        guard let filename = resDict?["filename"] as? String else { return nil }
        
        let _ = dbUpdateAccessTime(key)
        return filename
    }
    
    public func query(filePathForKey key: String, inBackThreadCallback callback: @escaping (String, String?) -> Void) {
        taskQueue.async { [weak self] in
            let filename = self?.query(filePathForKey: key)
            callback(key, filename)
        }
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

// MARK: - Insert
extension HQDiskCache {
    
    public func insert(originFile path: String, size: Int = 0, forKey key: String) {
        let fileM = FileManager.default
        guard fileM.fileExists(atPath: path) && !key.isEmpty else { return }
        let newPath = "\(cachePath)/\(convertToUrl(path).lastPathComponent)"
        do {
            try fileM.moveItem(atPath: path, toPath: newPath)
            dispatchAutoLock(taskLock) {
                self.dbInsert(key: key, filename: newPath, size: Int64(size), data: nil)
            }
        } catch {
        }
    }

    public func insert(originFile path: String, size: Int = 0, forKey key: String, inBackThreadCallback callback: @escaping () -> Void) {
        taskQueue.async { [weak self] in
            self?.insert(originFile: path, size: size, forKey: key)
            callback()
        }
    }
    
    
    public func insert<T: NSCoding>(object obj: T, forKey key: String) {
        guard !key.isEmpty else { return }
        var data: Data? = nil
        if let arch = customArchiveObjectClosure {
            data = arch(obj)
        }
        else {
            data = NSKeyedArchiver.archivedData(withRootObject: obj)
        }
        guard let value = data, value.count > 0 else { return }
        
        if value.count >= saveToDiskCritical {
            do {
                try save(data: value, withFilename: String(key.hashValue))
                let path = "\(dataPath)/\(key.hashValue)"
                dispatchAutoLock(taskLock) {
                    self.dbInsert(key: key, filename: path, size: Int64(value.count), data: nil)
                }
            }
            catch {}
        }
        else {
            dispatchAutoLock(taskLock) {
                self.dbInsert(key: key, filename: nil, size: Int64(value.count), data: value)
            }
        }
    }
    
    public func insertOrUpdate<T: NSCoding>(object obj: T, forKey key: String, inBackThreadCallback callback: @escaping () -> Void) {
        taskQueue.async { [weak self] in
            self?.insert(object: obj, forKey: key)
            callback()
        }
    }
}



// MARK: - Delete
extension HQDiskCache {

    public func delete(objectForKey key: String) {
        guard !key.isEmpty else { return }
        dispatchAutoLock(taskLock) {
            self.dbDelete(key)
        }
    }
    public func delete(objectForKey key: String, inBackThreadCallback callback: @escaping (String) -> Void) {
        taskQueue.async { [weak self] in
            self?.delete(objectForKey: key)
            callback(key)
        }
    }

    public func deleteAllCache() {
        dispatchAutoLock(taskLock) {
            self.connect = nil // close sqlite
            self.moveAllFileToTrash()
            self.emptyTrashInBackground()
            let _ = self.dbConnect()
        }
    }
    
    public func deleteAllCache(inBackThread callback: @escaping () -> Void) {
        taskQueue.async { [weak self] in
            self?.deleteAllCache()
            callback()
        }
    }

    public func deleteAllCache(withProgressClosure progress: @escaping (Int, Int, Bool) -> Void) {
        let _ = taskLock.wait(timeout: .distantFuture)
        defer { taskLock.signal() }
        
        let total = dbQueryTotalItemCount()
        if total <= 0 {
            progress(0,0, true)
            return
        }
        
        var left = total // left items number
        let page = 20   // every time remove items number
        var items = [[String: Any]]()
        var isSuc = false
            
        repeat {
            items = dbQueryCacheInfo(orderByTimeAsc: page)!
            
            for item in items {
                if left > 0 {
                    if let file = item["filename"] as? String {
                        try? delete(fileWithFilename: file)
                    }
                    isSuc = dbDelete(item["key"] as! String)
                    left -= 1
                }
                else {
                    break
                }
                if !isSuc { break }
            }
            progress(total-left, total, false)
        } while left > 0 && !items.isEmpty && isSuc
        progress(total, total, true)
    }

    
    public func deleteCache(exceedToCount count: Int) {
        let _ = taskLock.wait(timeout: .distantFuture)
        defer { taskLock.signal() }
        
        if count > Int.max { return }
        if count <= 0 {
            deleteAllCache()
            return
        }
        
        var total = dbQueryTotalItemCount()
        if total < count || total < 0 { return }
        
        var items = [[String: Any]]()
        var isSuc = false
        
        repeat {
            items = dbQueryCacheInfo(orderByTimeAsc: 20)!
            for item in items {
                if total > count {
                    if let file = item["filename"] as? String {
                        try? delete(fileWithFilename: file)
                    }
                    isSuc = dbDelete(item["key"] as! String)
                    total -= 1
                }
                else {
                    break
                }
                if !isSuc { break }
            }
        } while total > count && !items.isEmpty && isSuc
    }
    
    public func deleteCache(exceedToCount count: Int, inBackThread complete: @escaping () -> Void) {
        taskQueue.async { [weak self] in
            self?.deleteCache(exceedToCount: count)
            complete()
        }
    }

    
    public func deleteCache(exceedToCost cost: Int) {
        let _ = taskLock.wait(timeout: .distantFuture)
        defer { taskLock.signal() }
        
        if cost >= Int.max { return }
        if cost <= 0 {
            deleteAllCache()
            return
        }
        
        var total = dbQueryTotalItemCount()
        if total < 0 || total < cost { return }
        
        var items = [[String: Any]]()
        var isSuc = false
        
        repeat {
            items = dbQueryCacheInfo(orderByTimeAsc: 20)!
            for item in items {
                if total > cost {
                    if let file = item["filename"] as? String {
                        try? delete(fileWithFilename: file)
                    }
                    isSuc = dbDelete(item["key"] as! String)
                    total -= (item["size"] as? Int) ?? 0
                }
                else {
                    break
                }
                if !isSuc { break }
            }
        } while total > cost && !items.isEmpty && isSuc
    }
    
    public func deleteCache(exceedToCost cost: Int, inBackThread complete: @escaping () -> Void) {
        taskQueue.async { [weak self] in
            self?.deleteCache(exceedToCost: cost)
            complete()
        }
    }

    
    public func deleteCache(exceedToAge age: TimeInterval) {
        if age < 0 {
            deleteAllCache()
            return
        }
        
        let current = CFAbsoluteTimeGetCurrent()
        if current <= age { return } // future time
        let timeDelta = current - age
        if timeDelta >= Double(Int.max) { return }
        
        dispatchAutoLock(taskLock) {
            self.dbDeleteTimerEarlierThan(timeDelta)
        }
    }
    
    public func deleteCache(exceedToAge age: TimeInterval, inBackThread complete: @escaping () -> Void) {
        taskQueue.async { [weak self] in
            self?.deleteCache(exceedToAge: age)
            complete()
        }
    }
    
    public func deleteCache(toFreeSpace space: Int) {
        if space == 0 { return }
        let totalBytes = dbQueryTotalItemCount()
        if totalBytes < 0 { return }
        guard let attr = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()) else { return }
        let freeSize = attr[FileAttributeKey.systemFreeSize] as? Int
        if let free = freeSize, free > 0 {
            let needDelete = totalBytes - free
            deleteCache(exceedToCost: max(0, needDelete))
        }
    }
    
    public func deleteCache(toFreeSpace space: Int, inBackThread complete: @escaping () -> Void) {
        taskQueue.async { [weak self] in
            self?.deleteCache(toFreeSpace: space)
            complete()
        }
    }
}



// MARK: - Private function helper
private extension HQDiskCache {
    func queryDataFromSqlite(_ key: String) -> Data? {
        let _ = taskLock.wait(timeout: .distantFuture)
        defer { taskLock.signal() }
        let resDict = dbQuery(key)
        guard let item = resDict else { return nil }
        let _ = dbUpdateAccessTime(key)
        if let data = item["data"] as? Data { return data }
        if let file = item["filename"] as? String { return try? Data(contentsOf: convertToUrl(file)) }
        
        let _ = dbDelete(key) // this item no filename and no data, remove it
        return nil
    }
    
    func clearCacheTiming() {
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: DispatchTime.now() + autoTrimInterval) {
            self.clearInBackground()
            self.clearCacheTiming()
        }
    }
    
    func clearInBackground() {
        taskQueue.async { [weak self] in
            guard let wself = self else { return }
            wself.deleteCache(exceedToAge: wself.ageLimit)
            wself.deleteCache(exceedToCost: wself.costLimit)
            wself.deleteCache(exceedToCount: wself.countLimit)
            wself.deleteCache(toFreeSpace: wself.freeDiskSpaceLimit)
        }
    }
}
