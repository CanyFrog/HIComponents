//
//  HQDiskCache+Sqlite.swift
//  HQCache
//
//  Created by Magee Huang on 4/3/18.
//  Copyright © 2018 com.personal.HQ. All rights reserved.
//

import HQSqlite

/*
 SQLite/
 diskcache (
 key TEXT NOT NULL PRIMARY KEY,  # cache key
 filename TEXT,                  # if value save as file, this stored file path
 size INTEGER DEFAULT 0,         # value size
 save_time INTEGER,              # save timestamp
 access_time INTEGER INDEX       # cache last access timestamp
 data BLOB                       # value save as data
 )
 */

extension HQDiskCache {
    // MARK: - Connect to sqlite
    func connectDB(_ path: String) -> Bool {
        connect = try? HQSqliteConnection(path)
        return initDBTable()
    }
    
    

    // MARK: - Insert
    func insert(key: String, filename: String? = nil, size: Int64 = 0, data: Data? = nil) -> Bool {
        guard let stmt = getOrCreateStatement("insertItemSQL", "insert or replace into diskcache (key, filename, size, save_time, access_time, data) values (?, ?, ?, ?, ?, ?);") else { return false }
        
        let current = CFAbsoluteTimeGetCurrent()
        let _ = stmt.bind(key, filename, size, current, current, data)
        
        return (try? stmt.step()) ?? false
    }
    
    func updateAccessTime(_ keys: [String]) -> Bool {
        guard let stmt = getOrCreateStatement("updateItemAccessTimeSQL", "update diskcache set access_time = ? where key in (?);") else { return false }
        
        let _ = stmt.bind(CFAbsoluteTimeGetCurrent(), keys.joined(separator: ","))
        return (try? stmt.step()) ?? false
    }
    
    
    // MARK: - Delete
    func delete(_ keys: [String]) -> Bool {
        guard let stmt = getOrCreateStatement("deleteItemSQL", "delete from diskcache where key in (?);") else { return false }
        let _ = stmt.bind(keys.joined(separator: ","))
        return (try? stmt.step()) ?? false
    }
    
    func deleteSizeLargerThan(_ size: Int) -> Bool {
        guard let stmt = getOrCreateStatement("deleteItemLargerSizeSQL", "delete from diskcache where size > ?;") else { return false }
        let _ = stmt.bind(size)
        return (try? stmt.step()) ?? false
    }
    
    func deleteTimerEarlierThan(_ time: TimeInterval) -> Bool {
        guard let stmt = getOrCreateStatement("deleteItemEarlierTimeSQL", "delete from diskcache where access_time < ?;") else { return false }
        let _ = stmt.bind(time)
        return (try? stmt.step()) ?? false
    }
    
    
    // MARK: - Query
    func query(_ key: String) -> [String: Any]? {
        guard let stmt = getOrCreateStatement("queryItemSQL", "select * from diskcache where key = ?;") else { return nil }

        let _ = stmt.bind(key)
        if let succ = try? stmt.step(), succ  == true {
            var result = [String: Any]()
            for i in 0 ..< stmt.columnCount {
                result[stmt.columnNames[i]] = stmt.cursor[i]
            }
            return result
        }
        return nil
    }
    
    func query(_ keys: [String]) -> [[String: Any]]? {
        guard let stmt = getOrCreateStatement("queryItemsSQL", "select * from diskcache where key in (?);") else { return nil }
        let _ = stmt.bind(keys.joined(separator: ","))
        var results = [[String: Any]]()
        
        repeat {
            if let succ = try? stmt.step(), succ  == true {
                var res = [String: Any]()
                for i in 0 ..< stmt.columnCount {
                    res[stmt.columnNames[i]] = stmt.cursor[i]
                }
                results.append(res)
            }
            else {
                break
            }
        } while true
        
        return results
    }
    
    func queryFilename(sizeLargerThan size: Int) -> [String]? {
        guard let stmt = getOrCreateStatement("queryFilenameSizeSQL", "select filename from diskcache where size > ? and filename is not null;") else { return nil }

        let _ = stmt.bind(size)
        
        var results = [String]()
        repeat {
            if let succ = try? stmt.step(), succ  == true {
                results.append(stmt.cursor[0])
            }
            else {
                break
            }
        } while true
        
        return results
    }
    
    func queryFilename(timeEarlierThan time: TimeInterval) -> [String]? {
        guard let stmt = getOrCreateStatement("queryFilenameTimeSQL", "select filename from diskcache where access_time < ? and filename is not null;") else { return nil }
        let _ = stmt.bind(time)
        
        var results = [String]()
        repeat {
            if let succ = try? stmt.step(), succ  == true {
                results.append(stmt.cursor[0])
            }
            else {
                break
            }
        } while true
        
        return results
    }
    
    
    func queryCacheInfo(orderByTimeAsc limit: Int) -> [[String: Any]]? {
        guard let stmt = getOrCreateStatement("queryItemsInfoSQL", "select key, filename, size from diskcache order by access_time asc limit ?;") else { return nil }

        let _ = stmt.bind(limit)
        var results = [[String: Any]]()
        repeat {
            if let succ = try? stmt.step(), succ  == true {
                var res = [String: Any]()
                for i in 0 ..< stmt.columnCount {
                    res[stmt.columnNames[i]] = stmt.cursor[i]
                }
                results.append(res)
            }
            else {
                break
            }
        } while true
        
        return results
    }

    
    func queryTotalItemSize() -> Int {
        guard let stmt = getOrCreateStatement("queryTotalItemSize", "select sum(size) from diskcache;") else { return -1 }
        
        let isSucc = (try? stmt.step()) ?? false
        return isSucc ? stmt.cursor[0] : -1
    }
    
    func queryTotalItemCount() -> Int {
        guard let stmt = getOrCreateStatement("queryTotalItemCount", "select count(*) from diskcache;") else { return -1 }

        let isSucc = (try? stmt.step()) ?? false
        return isSucc ? stmt.cursor[0] : -1
    }
}


extension HQDiskCache {
    private func getOrCreateStatement(_ key: String, _ SQL: String) -> HQSqliteStatement? {
        guard let connect = connect else { return nil }
        if let stmt = stmtDict[key] { return stmt }
        let stmt = try? connect.prepare(SQL)
        stmtDict[key] = stmt
        return stmt
    }
    
    private func initDBTable() -> Bool {
        let initTable = """
            PRAGMA JOURNAL_MODE = WAL;
            PRAGMA SYNCHRONOUS = NORMAL;
            CREATE TABLE IF NOT EXISTS diskcache (
                key TEXT NOT NULL PRIMARY KEY,
                filename TEXT,
                size INTEGER DEFAULT 0,
                save_time INTEGER,
                access_time INTEGER INDEX,
                data BLOB
            );
        """
        
        return (try? connect.execute(initTable)) == nil
    }
}
