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
    var connect: HQSqliteConnection!
    var stmtDict = [String: HQSqliteStatement]()
    
    public var name: String = "DiskCache"

    private(set) var cachePath: String!

    public var errorEnable = false

    public var countLimit: UInt = UInt.max

    public var costLimit: UInt = UInt.max

    public var ageLimit: TimeInterval = TimeInterval(UINTMAX_MAX)

    public var autoTrimInterval: TimeInterval = 7 * 24 * 60 * 60

    /// The minimum free disk space (in bytes) which the cache should kept
    public var freeDiskSpaceLimit: UInt = 0

    /// When object data size bigger than this value, stored as file; otherwise stored as data to sqlite will be faster
    /// value is 0 mean all object save as file, Uint.max mean all save to sqlite
    public var saveToDiskCritical: UInt = 20 * 1024


    /// Custom archive or unarchive object closure, if nil, use NSCoding
    public var customArchiveObjectClosure: ((Any)->Data)?

    public var customUnarchiveObjectClosure: ((Data)->Any)?

    public var customNamedFileClosure: ((_ key: String)->String)?

    private var backgroundTrashQueue = DispatchQueue(label: "com.disk_trash.cache.personal.HQ", qos: .utility, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil)

    init?(_ path: String) {
        if path.isEmpty || path.count > PATH_MAX - 128 { fatalError("Error: Path is invalid") }
        cachePath = path.last == "/" ? path : "\(path)/"
        do {
            try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
            try FileManager.default.createDirectory(atPath: "\(path)data", withIntermediateDirectories: true, attributes: nil)
            try FileManager.default.createDirectory(atPath: "\(path)trash", withIntermediateDirectories: true, attributes: nil)
            connectDB(path)
            emptyTrash(path: <#T##String#>, inBackQueue: <#T##DispatchQueue#>)
        } catch {
            
        }
    }
}

extension HQDiskCache {
    public func exist(forKey key: String, inBackThreadCallback callback: @escaping (String, Bool) -> Void) {

    }

    public func query(objectForKey key: String, inBackThreadCallback callback: @escaping (String, Any?) -> Void) {

    }

    public func insertOrUpdate(object obj: Any, forKey key: String, inBackThreadCallback callback: @escaping () -> Void) {

    }

    public func delete(objectForKey key: String, inBackThreadCallback callback: @escaping (String) -> Void) {

    }

    public func deleteAllCache(inBackThread callback: @escaping () -> Void) {

    }

    public func deleteAllCache(withProgressClosure progress: @escaping (UInt, UInt, Bool) -> Void) {

    }

    public func deleteCache(exceedToCount count: UInt, inBackThread complete: @escaping () -> Void) {

    }

    public func deleteCache(exceedToCost cost: UInt, inBackThread complete: @escaping () -> Void) {

    }

    public func deleteCache(exceedToAge: TimeInterval, inBackThread complete: @escaping () -> Void) {

    }

    public func getTotalCount(inBackThread closure: @escaping (UInt) -> Void) {

    }

    public func getTotalCost(inBackThread closure: @escaping (UInt) -> Void) {

    }

    public func exist(forKey key: String) -> Bool {
        return false
    }

    public func query(objectForKey key: String) -> Any? {
        return nil
    }

    public func insertOrUpdate(object obj: Any, forKey key: String, cost: UInt = 0) {

    }

    public func delete(objectForKey key: String) {

    }

    public func deleteAllCache() {

    }

    public func deleteCache(exceedToCount count: UInt) {

    }

    public func deleteCache(exceedToCost cost: UInt) {

    }

    public func deleteCache(exceedToAge age: TimeInterval) {

    }

    public func getTotalCount() -> UInt {
        return 0
    }

    public func getTotalCost() -> UInt {
        return 0
    }
}


// MARK: - File manager helper
private extension HQDiskCache {
    func convertUrl(_ path: String) -> URL {
        return URL(fileURLWithPath: path)
    }

    func save(data: Data, withPath path: String) throws {
        try data.write(to: convertUrl(path))
    }

    func read(dataFromPath path: String) throws -> Data {
        return try Data(contentsOf: convertUrl(path))
    }

    func delete(fileWithPath path: String) throws {
        try FileManager.default.removeItem(atPath: path)
    }

    func moveFileToTrash(path: String) throws {
        let trashPath = path.appending(String(path.hashValue))
        do {
            try FileManager.default.moveItem(atPath: path, toPath: trashPath)
            try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        } catch let err {
            throw err
        }
    }

    func emptyTrash(path: String, inBackQueue queue: DispatchQueue) {
        let trashPath = path.appending(String(path.hashValue))
        queue.async {
            let fileManager = FileManager()
            if let trashs = try? fileManager.contentsOfDirectory(atPath: trashPath) {
                let _ = trashs.map{ p in
                    try? fileManager.removeItem(atPath: trashPath.appending(p))
                }
            }
        }
    }
}






