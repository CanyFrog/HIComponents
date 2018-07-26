//
//  DiskCache.swift
//  HQCache
//
//  Created by HonQi on 3/26/18.
//  Copyright © 2018 HonQi Indie. All rights reserved.
//

import HQFoundation
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

public class DiskCache {

    // MARK: - Public
    public var name: String = "Disk.Cache.me.HonQi"

    /// Default Int.max
    public var countLimit: Int = Int.max

    /// Default Int.max
    public var costLimit: Int = Int.max

    /// Default is 7 days
    public var ageLimit: TimeInterval = 7 * 24 * 60 * 60

    /// The minimum free disk space (in bytes) which the cache should kept
    public var freeDiskSpaceLimit: Int = 0

    
    // MARK: - Save to disk or sqlite limits
    
    /// When object data size bigger than this value, stored as file; otherwise stored as data to sqlite will be faster
    /// value is 0 mean all object save as file, Int.max mean all save to sqlite
    public private(set) var saveToDiskCritical: Int = 20 * 1024
    
    
    // MARK: - Cache path
    public private(set) var cachePath: URL!
    internal var dbPath: URL { return cachePath.appendingPathComponent("diskcache.sqlite") }
    internal var dbWalPath: URL { return cachePath.appendingPathComponent("diskcache.sqlite-wal") }
    internal var dbShmPath: URL { return cachePath.appendingPathComponent("diskcache.sqlite-shm") }
    internal var dataPath: URL { return cachePath.appendingPathComponent("data", isDirectory: true) }
    internal var trashPath: URL { return cachePath.appendingPathComponent("trash", isDirectory: true) }
    
    internal var backgroundTrashQueue = DispatchQueue(label: "queue.trash.disk.cache.me.HonQi", qos: .utility, attributes: .concurrent)
    internal var taskLock = DispatchSemaphore(value: 1)
    internal var taskQueue = DispatchQueue(label: "queue.data.disk.cache.me.HonQi", qos: .default, attributes: .concurrent)
    
    // MARK: - Sqlite
    internal var connect: Connection?
    internal var stmtDict = [String: Statement]()
    
    
    public init?(_ path: URL) {
        cachePath = path
        do {
            try FileManager.default.createDirectory(at: cachePath, withIntermediateDirectories: true, attributes: nil)
            try FileManager.default.createDirectory(at: dataPath, withIntermediateDirectories: true, attributes: nil)
            try FileManager.default.createDirectory(at: trashPath, withIntermediateDirectories: true, attributes: nil)
            if !dbConnect() { return nil }
            emptyTrashInBackground()
            clearCacheTiming()
        } catch {
            return nil
        }
    }
}



// MARK: - Query & Check
extension DiskCache {
    
    public func object<T: Codable>(forKey key: String) -> T? {
        guard !key.isEmpty, let data = queryDataFromSqlite(key) else { return nil }
        return T.unSerialize(data)
    }
    
    public func object<T: Codable>(forKey key: String, callback: @escaping (String, T?) -> Void) {
        taskQueue.async { [weak self] in
            let value: T? = self?.object(forKey: key)
            callback(key, value)
        }
    }

    
    /// query cache file path, use for big file, such as video & audio and so on
    ///
    /// - Returns: file path
    public func file(forKey key: String) -> String? {
        guard !key.isEmpty else { return nil }
        let _ = taskLock.wait(timeout: .distantFuture)
        defer { taskLock.signal() }
        let resDict = dbQuery(key)
        
        guard let filename = resDict?["filename"] as? String else { return nil }
        
        let _ = dbUpdateAccessTime(key)
        return filename
    }
    
    public func file(forKey key: String, callback: @escaping (String, String?) -> Void) {
        taskQueue.async { [weak self] in
            let filename = self?.file(forKey: key)
            callback(key, filename)
        }
    }
    
    
    /// Check
    public func contains(_ key: String) -> Bool {
        guard !key.isEmpty else { return false }
        return Lock.semaphore(taskLock, closure: { () -> Bool in
            return self.dbQuery(key) != nil
        })
    }
    
    
    public func totalCount() -> Int {
        return Lock.semaphore(taskLock, closure: { () -> Int in
            return self.dbQueryTotalItemCount()
        })
    }
    
    public func totalCost() -> Int {
        return Lock.semaphore(taskLock) { () -> Int in
            return self.dbQueryTotalItemSize()
        }
    }
}

// MARK: - Insert
extension DiskCache {
    
    public func setFile(_ path: URL, forKey key: String, size: Int = 0) {
        let fileM = FileManager.default
        guard fileM.fileExists(atPath: path.path) && !key.isEmpty else { return }

        let newPath = dataPath.appendingPathComponent(path.lastPathComponent)
        do {
            try fileM.moveItem(at: path, to: newPath)
            Lock.semaphore(taskLock) {
                self.dbInsert(key: key, filename: newPath.path, size: size, data: nil)
            }
        } catch {
        }
    }
    
    public func setObject<T: Codable>(_ obj: T, forKey key: String) {
        guard !key.isEmpty else { return }

        guard let value = obj.serialize(), value.count > 0 else { return }
        
        if value.count >= saveToDiskCritical {
            do {
                try save(data: value, withFilename: String(key.hashValue))
                let path = dataPath.appendingPathComponent("\(key.hashValue)")
                Lock.semaphore(taskLock) {
                    self.dbInsert(key: key, filename: path.path, size: value.count, data: nil)
                }
            }
            catch {}
        }
        else {
            Lock.semaphore(taskLock) {
                self.dbInsert(key: key, filename: nil, size: value.count, data: value)
            }
        }
    }
}



// MARK: - Delete
extension DiskCache {

    public func removeObject(forKey key: String) {
        guard !key.isEmpty else { return }
        Lock.semaphore(taskLock) {
            self.dbDelete(key)
        }
    }
    public func removeObject(forKey key: String, completed: @escaping (String) -> Void) {
        taskQueue.async { [weak self] in
            self?.removeObject(forKey: key)
            completed(key)
        }
    }

    public func removeAllObjects() {
        Lock.semaphore(taskLock) {
            self.stmtDict.removeAll()
            // FIXME: BUG IN CLIENT OF libsqlite3.dylib: database integrity compromised by API violation: vnode unlinked while in use:
            self.connect = nil // close sqlite
            try? FileManager.default.removeItem(at: dbPath)
            try? FileManager.default.removeItem(at: dbWalPath)
            try? FileManager.default.removeItem(at: dbShmPath)
            self.moveAllFileToTrash()
            self.emptyTrashInBackground()
            let _ = self.dbConnect() // reconnect
        }
    }
    
    public func removeAllObjects(progress: @escaping (Int, Int, Bool) -> Void) {
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
                    isSuc = dbDelete((item["key"] as! String))
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

    
    public func removeObjects(toCountLessThan count: Int) {
        let _ = taskLock.wait(timeout: .distantFuture)
        defer { taskLock.signal() }
        
        if count > Int.max { return }
        if count <= 0 {
            removeAllObjects()
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
    
    public func removeObjects(toCostLessThan cost: Int) {
        let _ = taskLock.wait(timeout: .distantFuture)
        defer { taskLock.signal() }
        
        if cost >= Int.max { return }
        if cost <= 0 {
            removeAllObjects()
            return
        }
        
        var total = dbQueryTotalItemSize()
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

    
    public func removeObjects(toAgeMoreThan age: TimeInterval) {
        if age < 0 {
            removeAllObjects()
            return
        }
        
        let current = CACurrentMediaTime()
        if current <= age { return } // future time
        let timeDelta = current - age
        if timeDelta >= Double(Int.max) { return }
        
        Lock.semaphore(taskLock) {
            self.dbDeleteTimerEarlierThan(timeDelta)
        }
    }
    
    
    public func removeObjects(toFreeSpace space: Int) {
        if space <= 0 { return }
        
        let totalBytes = Lock.semaphore(taskLock) { () -> Int in
            return self.dbQueryTotalItemSize()
        }
        if totalBytes <= 0 { return }
        guard let attr = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()) else { return }
        let freeSize = attr[FileAttributeKey.systemFreeSize] as? Int
        guard let free = freeSize else { return } // not get system free size
        let needDelete = space - free
        if needDelete <= 0 { return } // now free space larger than target
        
        let costLimit = totalBytes - needDelete // need hold item'size
        removeObjects(toCostLessThan: max(0, costLimit))
    }
}

// MARK: - Private function helper
private extension DiskCache {
    func queryDataFromSqlite(_ key: String) -> Data? {
        let _ = taskLock.wait(timeout: .distantFuture)
        defer { taskLock.signal() }
        let resDict = dbQuery(key)
        guard let item = resDict else { return nil }
        let _ = dbUpdateAccessTime(key)
        if let data = item["data"] as? Data { return data }
        if let file = item["filename"] as? String { return try? Data(contentsOf: URL(fileURLWithPath: file)) }
        
        let _ = dbDelete(key) // this item no filename and no data, remove it
        return nil
    }
    
    func clearCacheTiming() {
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: DispatchTime.now()) {[weak self] in
            guard let wself = self else { return }
            wself.clearInBackground()
//            wself.clearCacheTiming()
        }
    }
    
    func clearInBackground() {
        taskQueue.async { [weak self] in
            guard let wself = self else { return }
            wself.removeObjects(toAgeMoreThan: wself.ageLimit)
            wself.removeObjects(toCostLessThan: wself.costLimit)
            wself.removeObjects(toCountLessThan: wself.countLimit)
            wself.removeObjects(toFreeSpace: wself.freeDiskSpaceLimit)
        }
    }
}
