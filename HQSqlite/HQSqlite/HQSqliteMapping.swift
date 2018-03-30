//
//  HQSqliteMapping.swift
//  HQSqlite
//
//  Created by Magee Huang on 3/30/18.
//  Copyright © 2018 HQ.Personal.modules. All rights reserved.
//
import SQLite3

/// Protocol to mapping swift types to sqlite types
public protocol HQSqliteMapping {}

extension Data: HQSqliteMapping {}
extension Double: HQSqliteMapping {}
extension Int64: HQSqliteMapping {}
extension Int32: HQSqliteMapping {}
extension String: HQSqliteMapping {}
extension Bool: HQSqliteMapping {}
extension Int: HQSqliteMapping {}


// MARK: - Statement index cursor
public struct HQSqliteCursor {
    internal let handle: OpaquePointer
    internal let columnCount: Int
    
    internal init(_ statement: HQSqliteStatement) {
        handle = statement.handle!
        columnCount = statement.columnCount
    }
}


// MARK: - Cursor index
extension HQSqliteCursor {
    public subscript(idx: Int) -> Data {
        if let pointer = sqlite3_column_blob(handle, Int32(idx)) {
            let length = Int(sqlite3_column_bytes(handle, Int32(idx)))
            return Data(bytes: pointer, count: length)
        } else {
            // The return value from sqlite3_column_blob() for a zero-length BLOB is a NULL pointer.
            // https://www.sqlite.org/c3ref/column_blob.html
            return Data(bytes: [])
        }
    }
    
    public subscript(idx: Int) -> Double {
        return sqlite3_column_double(handle, Int32(idx))
    }
    
    public subscript(idx: Int) -> Int64 {
        return sqlite3_column_int64(handle, Int32(idx))
    }
    
    public subscript(idx: Int) -> String {
        return String(cString: UnsafePointer(sqlite3_column_text(handle, Int32(idx))))
    }

    public subscript(idx: Int) -> Bool {
        let v = sqlite3_column_int(handle, Int32(idx))
        return v == 0 ? false : true
    }
    
    public subscript(idx: Int) -> Int {
        let v = sqlite3_column_int64(handle, Int32(idx))
        return Int(v)
    }
}

// MARK: - Sequence
extension HQSqliteCursor: Sequence {
    public subscript(idx: Int) -> HQSqliteMapping? {
        switch sqlite3_column_type(handle, Int32(idx)) {
        case SQLITE_BLOB:
            return self[idx] as Data
        case SQLITE_FLOAT:
            return self[idx] as Double
        case SQLITE_INTEGER:
            return self[idx] as Int64
        case SQLITE_TEXT:
            return self[idx] as String
        case SQLITE_NULL:
            return nil
        case let type:
            fatalError("unsupported column type: \(type)")
        }
    }
        
    public func makeIterator() -> AnyIterator<HQSqliteMapping?> {
        var idx = 0
        return AnyIterator {
            if idx > self.columnCount {
                return Optional<HQSqliteMapping?>.none
            } else {
                idx += 1
                return self[idx - 1]
            }
        }
    }
}
