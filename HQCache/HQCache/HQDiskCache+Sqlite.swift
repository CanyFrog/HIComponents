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


internal struct HQSqliteItem {
    var key: String!
    var filename: String?
    var size: Int = 0
    var saveTime: TimeInterval!
    var accessTime: TimeInterval!
    var data: Data?
}

extension HQDiskCache {
    // MARK: - Connect to sqlite
    func dbConnect() -> Bool {
        connect = try? HQSqliteConnection(dbPath)
        connect?.busyTimeout = 0.1
        return connect != nil && !dbInitTable()
    }

    // MARK: - Insert
    func dbInsert(key: String, filename: String? = nil, size: Int = 0, data: Data? = nil) -> Bool {
        guard let stmt = getOrCreateStatement("insertItemSQL", "insert or replace into diskcache (key, filename, size, save_time, access_time, data) values (?, ?, ?, ?, ?, ?);") else { return false }
        
        let current = CACurrentMediaTime()
        let _ = stmt.bind(key, filename, size, current, current, data)
        
        return (try? stmt.step()) ?? false
    }
    
    func dbUpdateAccessTime(_ key: String) -> Bool {
        guard let stmt = getOrCreateStatement("updateItemAccessTimeSQL", "update diskcache set access_time = ? where key = ?;") else { return false }
        
        let _ = stmt.bind(CACurrentMediaTime(), key)
        return (try? stmt.step()) ?? false
    }
    
    
    // MARK: - Delete
    func dbDelete(_ key: String) -> Bool {
        guard let stmt = getOrCreateStatement("deleteItemSQL", "delete from diskcache where key = ?;") else { return false }
        let _ = stmt.bind(key)
        return (try? stmt.step()) ?? false
    }
    
    func dbDeleteSizeLargerThan(_ size: Int) -> Bool {
        guard let stmt = getOrCreateStatement("deleteItemLargerSizeSQL", "delete from diskcache where size > ?;") else { return false }
        let _ = stmt.bind(size)
        return (try? stmt.step()) ?? false
    }
    
    func dbDeleteTimerEarlierThan(_ time: TimeInterval) -> Bool {
        guard let stmt = getOrCreateStatement("deleteItemEarlierTimeSQL", "delete from diskcache where access_time < ?;") else { return false }
        let _ = stmt.bind(time)
        return (try? stmt.step()) ?? false
    }
    
    // MARK: - Query
    func dbQuery(_ key: String) -> [String: Any]? {
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
    
    
    func dbQueryFilename(sizeLargerThan size: Int) -> [String]? {
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
    
    func dbQueryFilename(timeEarlierThan time: TimeInterval) -> [String]? {
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
    
    
    func dbQueryCacheInfo(orderByTimeAsc limit: Int) -> [[String: Any]]? {
        guard let stmt = getOrCreateStatement("queryItemsTimeOrderSQL", "select key, filename, size from diskcache order by access_time asc limit ?;") else { return nil }

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

    
    func dbQueryTotalItemSize() -> Int {
        guard let stmt = getOrCreateStatement("queryTotalItemSize", "select sum(size) from diskcache;") else { return -1 }
        
        let isSucc = (try? stmt.step()) ?? false
        return isSucc ? stmt.cursor[0] : -1
    }
    
    func dbQueryTotalItemCount() -> Int {
        guard let stmt = getOrCreateStatement("queryTotalItemCount", "select count(*) from diskcache;") else { return -1 }

        let isSucc = (try? stmt.step()) ?? false
        return isSucc ? stmt.cursor[0] : -1
    }
}


extension HQDiskCache {
    private func getOrCreateStatement(_ key: String, _ SQL: String) -> HQSqliteStatement? {
        guard let connect = connect else {
            let _ = dbConnect() // reconnect
            return nil
        }
        if let stmt = stmtDict[key] { return stmt }
        let stmt = try? connect.prepare(SQL)
        stmtDict[key] = stmt
        return stmt
    }
    
    private func dbInitTable() -> Bool {
        let initTable = """
            PRAGMA JOURNAL_MODE = WAL;
            PRAGMA SYNCHRONOUS = NORMAL;
            CREATE TABLE IF NOT EXISTS diskcache (
                key TEXT NOT NULL PRIMARY KEY,
                filename TEXT,
                size INTEGER DEFAULT 0,
                save_time INTEGER,
                access_time INTEGER,
                data BLOB
            );
            create index if not exists access_time_idx on diskcache(access_time);
        """
        return (try? connect?.execute(initTable)) == nil
    }
}
