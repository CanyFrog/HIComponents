//
//  HQSqliteConnection.swift
//  HQSqlite
//
//  Created by Magee Huang on 3/29/18.
//  Copyright © 2018 HQ.Personal.modules. All rights reserved.
//
// Study and mock from SQLite https://github.com/stephencelis/SQLite.swift

// TODO: Transaction & Function & Hook
// Now only simple support insert update delete and select

import Foundation
import SQLite3

public final class HQSqliteConnection {
    
    /// sqlite handle
    public private(set) var handle: OpaquePointer?
    
    // MARK: - Queue
    /// connection sync queue
    private var queue = DispatchQueue(label: "connection.sqlite.personal.HQ", attributes: [])
    private static let queueKey = DispatchSpecificKey<Int>()
    private lazy var queueContext: Int = unsafeBitCast(self, to: Int.self)
    
    // MARK: - Public property
    
    /// Whether or not the database was opened in a read-only state.
    public var readonly: Bool { return sqlite3_db_readonly(handle, nil) == 1 }
    
    /// The last rowid inserted into the database via this connection.
    public var lastInsertRowid: Int64 {
        return sqlite3_last_insert_rowid(handle)
    }
    
    /// The last number of changes (inserts, updates, or deletes) made to the
    /// database via this connection.
    public var changes: Int {
        return Int(sqlite3_changes(handle))
    }
    
    /// The total number of changes (inserts, updates, or deletes) made to the
    /// database via this connection.
    public var totalChanges: Int {
        return Int(sqlite3_total_changes(handle))
    }
    
    
    // MARK: - Initialize
    
    public init(_ type: SqliteType = .memory, readOnly: Bool = false) throws {
        let flags = readOnly ? SQLITE_OPEN_READONLY : SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE
        try checkCode(sqlite3_open_v2(type.description, &handle, flags | SQLITE_OPEN_FULLMUTEX, nil))
        queue.setSpecific(key: HQSqliteConnection.queueKey, value: queueContext)
    }
    
    public convenience init(_ filepath: String, readOnly: Bool = false) throws {
        try self.init(.uri(filepath), readOnly: readOnly)
    }
    
    deinit {
        sqlite3_close(handle)
    }
    
    
    // MARK: - Busy handler callback
    
    /// Sets a handler to call after encountering a busy signal (lock).
    ///
    /// - Parameter callback: This block is executed during a lock in which a
    ///   busy error would otherwise be returned. It’s passed the number of
    ///   times it’s been called for this lock. If it returns `true`, it will
    ///   try again. If it returns `false`, no further attempts will be made.
    public func busyHandler(_ callback: ((_ tries: Int) -> Bool)?) {
        guard let callback = callback else {
            sqlite3_busy_handler(handle, nil, nil)
            busyHandler = nil
            return
        }
        
        let box: BusyHandler = { callback(Int($0)) ? 1 : 0 }
        sqlite3_busy_handler(handle, { callback, tries in
            unsafeBitCast(callback, to: BusyHandler.self)(tries)
        }, unsafeBitCast(box, to: UnsafeMutableRawPointer.self))
        busyHandler = box
    }
    
    /// The number of seconds a connection will attempt to retry a statement
    /// after encountering a busy signal (lock).
    public var busyTimeout: Double = 0 {
        didSet {
            sqlite3_busy_timeout(handle, Int32(busyTimeout * 1_000))
        }
    }
    private typealias BusyHandler = @convention(block) (Int32) -> Int32
    private var busyHandler: BusyHandler?


    // MARK: - SQLite operation Hook callback
    
    /// Registers a callback to be invoked whenever a row is inserted, updated,
    /// or deleted in a rowid table.
    ///
    /// - Parameter callback: A callback invoked with the `Operation` (one of
    ///   `.Insert`, `.Update`, or `.Delete`), database name, table name, and
    ///   rowid.
    public func updateHook(_ callback: ((_ operation: HQSqliteOperation, _ db: String, _ table: String, _ rowid: Int64) -> Void)?) {
        guard let callback = callback else {
            sqlite3_update_hook(handle, nil, nil)
            updateHook = nil
            return
        }
        
        let box: UpdateHook = {
            callback(
                HQSqliteOperation(rawValue: $0),
                String(cString: $1),
                String(cString: $2),
                $3
            )
        }
        sqlite3_update_hook(handle, { callback, operation, db, table, rowid in
            unsafeBitCast(callback, to: UpdateHook.self)(operation, db!, table!, rowid)
        }, unsafeBitCast(box, to: UnsafeMutableRawPointer.self))
        updateHook = box
    }
    
    /*
     @convention
     修饰 Swift 中的函数类型，调用 C 的函数时候，可以传入修饰过@convention(c)的函数类型，匹配 C 函数参数中的函数指针。
     修饰 Swift 中的函数类型，调用 Objective-C 的方法时候，可以传入修饰过@convention(block)的函数类型，匹配 Objective-C 方法参数中的 block 参数
     */
    fileprivate typealias UpdateHook = @convention(block) (Int32, UnsafePointer<Int8>, UnsafePointer<Int8>, Int64) -> Void
    fileprivate var updateHook: UpdateHook?
    
    
    // MARK: - Commit hook
    
    /// Registers a callback to be invoked whenever a transaction is committed.
    ///
    /// - Parameter callback: A callback invoked whenever a transaction is
    ///   committed. If this callback throws, the transaction will be rolled
    ///   back.
    public func commitHook(_ callback: (() throws -> Void)?) {
        guard let callback = callback else {
            sqlite3_commit_hook(handle, nil, nil)
            commitHook = nil
            return
        }
        
        let box: CommitHook = {
            do {
                try callback()
            } catch {
                return 1
            }
            return 0
        }
        sqlite3_commit_hook(handle, { callback in
            unsafeBitCast(callback, to: CommitHook.self)()
        }, unsafeBitCast(box, to: UnsafeMutableRawPointer.self))
        commitHook = box
    }
    fileprivate typealias CommitHook = @convention(block) () -> Int32
    fileprivate var commitHook: CommitHook?

    
    
    // MARK: - Rollback hook
    /// Registers a callback to be invoked whenever a transaction rolls back.
    ///
    /// - Parameter callback: A callback invoked when a transaction is rolled
    ///   back.
    public func rollbackHook(_ callback: (() -> Void)?) {
        guard let callback = callback else {
            sqlite3_rollback_hook(handle, nil, nil)
            rollbackHook = nil
            return
        }
        
        let box: RollbackHook = { callback() }
        sqlite3_rollback_hook(handle, { callback in
            unsafeBitCast(callback, to: RollbackHook.self)()
        }, unsafeBitCast(box, to: UnsafeMutableRawPointer.self))
        rollbackHook = box
    }
    fileprivate typealias RollbackHook = @convention(block) () -> Void
    fileprivate var rollbackHook: RollbackHook?
}


// MARK: - Prepare
/// Prepares a single SQL statement (with optional parameter bindings).
///
/// - Parameters:
///
///   - statement: A single SQL statement.
///
///   - bindings: A list of parameters to bind to the statement.
///
/// - Returns: A prepared statement.
public extension HQSqliteConnection {
    
    public func prepare(_ statement: String, _ bindings: HQSqliteMapping?...) throws -> HQSqliteStatement {
        if !bindings.isEmpty { return try prepare(statement, bindings) }
        return try HQSqliteStatement(self, statement) // final function
    }
    
    public func prepare(_ statement: String, _ bindings: [HQSqliteMapping?]) throws -> HQSqliteStatement {
        return try prepare(statement).bind(bindings)
    }
    
    public func prepare(_ statement: String, _ bindings: [String: HQSqliteMapping?]) throws -> HQSqliteStatement {
        return try prepare(statement).bind(bindings)
    }
}


// MARK: - Run
/// Runs a single SQL statement (with optional parameter bindings).
///
/// - Parameters:
///
///   - statement: A single SQL statement.
///
///   - bindings: A list of parameters to bind to the statement.
///
/// - Throws: `Result.Error` if query execution fails.
///
/// - Returns: The statement.
public extension HQSqliteConnection {

    @discardableResult public func run(_ statement: String, _ bindings: HQSqliteMapping?...) throws -> HQSqliteStatement {
        return try run(statement, bindings)
    }
    
    @discardableResult public func run(_ statement: String, _ bindings: [HQSqliteMapping?]) throws -> HQSqliteStatement {
        return try prepare(statement).run(bindings) // final function
    }
    
    @discardableResult public func run(_ statement: String, _ bindings: [String: HQSqliteMapping?]) throws -> HQSqliteStatement {
        return try prepare(statement).run(bindings)
    }

}

// MARK: - Public functions
public extension HQSqliteConnection {
    
    /// Execute a batch of sql statements
    public func execute(_ SQL: String) throws {
        let _ = try sync { try self.checkCode(sqlite3_exec(self.handle, SQL, nil, nil, nil)) }
    }
    
//    public func prepare(_ statement: String, _ bindings: )
//    public func bind
    
    /// Interrupts any long-running queries.
    public func interrupt() {
        sqlite3_interrupt(handle)
    }

}


// MARK: - Private helper function
internal extension HQSqliteConnection {
    
    /// checkCode
    @discardableResult
    func checkCode(_ resultCode: Int32, statement: HQSqliteStatement? = nil) throws -> Int32 {
        guard let error = HQSqliteError(errorCode: resultCode, connection: self, statement: statement) else { return resultCode }
        throw error
    }
    
    /// sync execute
    func sync<T>(_ block: () throws -> T) rethrows -> T {
        if DispatchQueue.getSpecific(key: HQSqliteConnection.queueKey) == queueContext {
            return try block() // if in self seecific queue, execute
        } else {
            return try queue.sync(execute: block) // otherwise back to queue sync execute
        }
    }
}
