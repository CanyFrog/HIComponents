//
//  HQSqliteStatement.swift
//  HQSqlite
//
//  Created by Magee Huang on 3/29/18.
//  Copyright © 2018 HQ.Personal.modules. All rights reserved.
//

import Foundation
import SQLite3

public class HQSqliteStatement {
    internal var handle: OpaquePointer? = nil
    internal let connection: HQSqliteConnection
    
    init(_ connection: HQSqliteConnection, _ SQL: String) throws {
        self.connection = connection
        try connection.checkCode(sqlite3_prepare_v2(connection.handle, SQL, -1, &handle, nil))
    }
    
    deinit {
        sqlite3_finalize(handle)
    }
    
    public lazy var columnCount: Int = Int(sqlite3_column_count(self.handle))
    
    public lazy var columnNames: [String] = (0..<Int32(self.columnCount)).map {
        String(cString: sqlite3_column_name(self.handle, $0))
    }
    
    public lazy var cursor = HQSqliteCursor(self)
}


// MARK: - Bind values to statement
/// Binds a list of parameters to a statement.
///
/// - Parameter values: A list of parameters to bind to the statement.
///
/// - Returns: The statement object (useful for chaining).

let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

extension HQSqliteStatement {
    
    public func bind(_ values: HQSqliteMapping?...) -> HQSqliteStatement {
        return bind(values)
    }
    
    public func bind(_ values: [HQSqliteMapping?]) -> HQSqliteStatement {
        if values.isEmpty { return self }
        reset()
        guard values.count == Int(sqlite3_bind_parameter_count(handle)) else {
            fatalError("\(sqlite3_bind_parameter_count(handle)) values expected, \(values.count) passed")
        }
        for (idx, value) in values.enumerated() {
            bind(value, atIndex: idx+1)
        } // idx start from 1
        return self
    }
    
    public func bind(_ values: [String: HQSqliteMapping?]) -> HQSqliteStatement {
        reset()
        for (name, value) in values {
            let idx = sqlite3_bind_parameter_index(handle, name)
            guard idx > 0 else { fatalError("parameter not found: \(name)") }
            bind(value, atIndex: Int(idx))
        }
        return self
    }
    
    private func bind(_ value: HQSqliteMapping?, atIndex idx: Int) {
        if value == nil {
            sqlite3_bind_null(handle, Int32(idx))
        } else if let value = value as? Data {
//            let bytes = value.withUnsafeBytes{ [UInt8](UnsafeBufferPointer(start: $0, count: value.count)) }
            sqlite3_bind_blob(handle, Int32(idx), [UInt8](value), Int32(value.count), SQLITE_TRANSIENT)
        } else if let value = value as? String {
            sqlite3_bind_text(handle, Int32(idx), value, -1, SQLITE_TRANSIENT)
        } else if let value = value as? Double {
            sqlite3_bind_double(handle, Int32(idx), value)
        } else if let value = value as? Int {
            sqlite3_bind_int64(handle, Int32(idx), sqlite3_int64(value))
        } else if let value = value as? Int64 {
            sqlite3_bind_int64(handle, Int32(idx), value)
        } else if let value = value as? Bool {
            let v = value ? 1 : 0
            sqlite3_bind_int(handle, Int32(idx), Int32(v))
        } else if let value = value {
            fatalError("tried to bind unexpected value \(value)")
        }
    }
}



// MARK: - Run functions
/// - Parameter bindings: A list of parameters to bind to the statement.
///
/// - Throws: `Result.Error` if query execution fails.
///
/// - Returns: The statement object (useful for chaining).
extension HQSqliteStatement {

    /// final run
    @discardableResult
    public func run(_ bindings: HQSqliteMapping?...) throws -> HQSqliteStatement {
        guard bindings.isEmpty else { return try run(bindings) }
        
        reset(false)
        repeat {} while try step() // repear until success
        return self
    }
    
    @discardableResult
    public func run(_ bindings: [HQSqliteMapping?]) throws -> HQSqliteStatement {
        return try bind(bindings).run()
    }
    
    
    @discardableResult
    public func run(_ bindings: [String: HQSqliteMapping?]) throws -> HQSqliteStatement {
        return try bind(bindings).run()
    }

    /// Step execute sql command
    public func step() throws -> Bool {
        return try connection.sync { try self.connection.checkCode(sqlite3_step(self.handle)) == SQLITE_ROW }
    }
}

// MARK: - Private helper functions
extension HQSqliteStatement {
    private func reset(_ clearBindings: Bool = true) {
        sqlite3_reset(handle)
        if clearBindings { sqlite3_clear_bindings(handle) }
    }
}


extension HQSqliteStatement: CustomStringConvertible {
    public var description: String {
        return String(cString: sqlite3_sql(handle))
    }
}
