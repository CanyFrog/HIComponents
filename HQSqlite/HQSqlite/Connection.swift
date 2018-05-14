//
//  Connection.swift
//  HQSqlite
//
//  Created by Magee Huang on 3/29/18.
//  Copyright © 2018 HQ.Personal.modules. All rights reserved.
//
// Study and mock from SQLite https://github.com/stephencelis/SQLite.swift

// TODO: & Function
// Now only simple support insert update delete and select

import Foundation
import SQLite3

public final class Connection {
    
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
    
    public init(_ type: Location = .memory, readOnly: Bool = false) throws {
        let flags = readOnly ? SQLITE_OPEN_READONLY : SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE
        try checkCode(sqlite3_open_v2(type.description, &handle, flags | SQLITE_OPEN_FULLMUTEX, nil))
        queue.setSpecific(key: Connection.queueKey, value: queueContext)
    }
    
    public convenience init(_ filepath: String, readOnly: Bool = false) throws {
        try self.init(.uri(filepath), readOnly: readOnly)
    }
    
    deinit {
        if #available(iOS 8.2, *) {
            sqlite3_close_v2(handle)
        } else {
            sqlite3_close(handle)
        }
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
    public func updateHook(_ callback: ((_ operation: SqliteOperation, _ db: String, _ table: String, _ rowid: Int64) -> Void)?) {
        guard let callback = callback else {
            sqlite3_update_hook(handle, nil, nil)
            updateHook = nil
            return
        }
        
        let box: UpdateHook = {
            callback(
                SqliteOperation(rawValue: $0),
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
    
    
    
    // MARK: - Trace execute result
    
    /// Sets a handler to call when a statement is executed with the compiled
    /// SQL.
    ///
    /// - Parameter callback: This block is invoked when a statement is executed
    ///   with the compiled SQL as its argument.
    ///
    ///       db.trace { SQL in print(SQL) }
    public func trace(_ callback: ((String) -> Void)?) {
        guard let callback = callback else {
            if #available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
                // If the X callback is NULL or if the M mask is zero, then tracing is disabled.
                sqlite3_trace_v2(handle, 0 /* mask */, nil /* xCallback */, nil /* pCtx */)
            } else {
               sqlite3_trace(handle, nil /* xCallback */, nil /* pCtx */)
            }
            trace = nil
            return
        }
        
        let box: Trace = { (pointer: UnsafeRawPointer) in
            callback(String(cString: pointer.assumingMemoryBound(to: UInt8.self)))
        }
        
        if #available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
            sqlite3_trace_v2(handle,
                             UInt32(SQLITE_TRACE_STMT) /* mask */,
                {
                    // A trace callback is invoked with four arguments: callback(T,C,P,X).
                    // The T argument is one of the SQLITE_TRACE constants to indicate why the
                    // callback was invoked. The C argument is a copy of the context pointer.
                    // The P and X arguments are pointers whose meanings depend on T.
                    (T: UInt32, C: UnsafeMutableRawPointer?, P: UnsafeMutableRawPointer?, X: UnsafeMutableRawPointer?) in
                    if let P = P,
                        let expandedSQL = sqlite3_expanded_sql(OpaquePointer(P)) {
                        unsafeBitCast(C, to: Trace.self)(expandedSQL)
                        sqlite3_free(expandedSQL)
                    }
                    return Int32(0) // currently ignored
            },
                unsafeBitCast(box, to: UnsafeMutableRawPointer.self) /* pCtx */
            )
        } else {
            sqlite3_trace(handle,
                          {
                            (C: UnsafeMutableRawPointer?, SQL: UnsafePointer<Int8>?) in
                            if let C = C, let SQL = SQL {
                                unsafeBitCast(C, to: Trace.self)(SQL)
                            }
            },
                          unsafeBitCast(box, to: UnsafeMutableRawPointer.self)
            )
        }
        trace = box
    }
    
    private typealias Trace = @convention(block) (UnsafeRawPointer) -> Void
    private var trace: Trace?
}


// MARK: - Transaction
/// Runs a transaction with the given mode.
///
/// - Note: Transactions cannot be nested. To nest transactions, see
///   `savepoint()`, instead.
///
/// - Parameters:
///
///   - mode: The mode in which a transaction acquires a lock.
///
///     Default: `.deferred`
///
///   - block: A closure to run SQL statements within the transaction.
///     The transaction will be committed when the block returns. The block
///     must throw to roll the transaction back.
///
/// - Throws: `Result.Error`, and rethrows.
extension Connection {
    public func transaction(_ mode: TransactionMode = .deferred, block: () throws -> Void) throws {
        try transaction("BEGIN \(mode.rawValue) TRANSACTION", block, "COMMIT TRANSACTION", or: "ROLLBACK TRANSACTION")
    }
    
    /// Runs a transaction with the given savepoint name (if omitted, it will
    /// generate a UUID).
    ///
    /// - SeeAlso: `transaction()`.
    ///
    /// - Parameters:
    ///
    ///   - savepointName: A unique identifier for the savepoint (optional).
    ///
    ///   - block: A closure to run SQL statements within the transaction.
    ///     The savepoint will be released (committed) when the block returns.
    ///     The block must throw to roll the savepoint back.
    ///
    /// - Throws: `SQLite.Result.Error`, and rethrows.
    public func savepoint(_ name: String = UUID().uuidString, block: () throws -> Void) throws {
        // replace \' character to \'' and surround by ''
        let name = "'\(name.reduce("") { (str, c) -> String in return str + (c == "'" ? "''" : "\(c)")})'"
        let savepoint = "SAVEPOINT \(name)"
        
        try transaction(savepoint, block, "RELEASE \(savepoint)", or: "ROLLBACK TO \(savepoint)")
    }
    
    private func transaction(_ begin: String, _ block: () throws -> Void, _ commit: String, or rollback: String) throws {
        return try sync {
            try self.run(begin)
            do {
                try block()
                try self.run(commit)
            } catch {
                try self.run(rollback)
                throw error
            }
        }
    }
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
public extension Connection {
    
    public func prepare(_ statement: String, _ bindings: SqliteMapping?...) throws -> Statement {
        if !bindings.isEmpty { return try prepare(statement, bindings) }
        return try Statement(self, statement) // final function
    }
    
    public func prepare(_ statement: String, _ bindings: [SqliteMapping?]) throws -> Statement {
        return try prepare(statement).bind(bindings)
    }
    
    public func prepare(_ statement: String, _ bindings: [String: SqliteMapping?]) throws -> Statement {
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
public extension Connection {

    @discardableResult public func run(_ statement: String, _ bindings: SqliteMapping?...) throws -> Statement {
        return try run(statement, bindings)
    }
    
    @discardableResult public func run(_ statement: String, _ bindings: [SqliteMapping?]) throws -> Statement {
        return try prepare(statement).run(bindings) // final function
    }
    
    @discardableResult public func run(_ statement: String, _ bindings: [String: SqliteMapping?]) throws -> Statement {
        return try prepare(statement).run(bindings)
    }

}

// MARK: - Public functions
public extension Connection {
    
    /// Execute a batch of sql statements
    public func execute(_ SQL: String) throws {
        let _ = try sync { try self.checkCode(sqlite3_exec(self.handle, SQL, nil, nil, nil)) }
    }

    /// Interrupts any long-running queries.
    public func interrupt() {
        sqlite3_interrupt(handle)
    }

}


// MARK: - Private helper function
internal extension Connection {
    
    /// checkCode
    @discardableResult
    func checkCode(_ resultCode: Int32, statement: Statement? = nil) throws -> Int32 {
        guard let error = SqliteError(errorCode: resultCode, connection: self, statement: statement) else { return resultCode }
        throw error
    }
    
    /// sync execute
    func sync<T>(_ block: () throws -> T) rethrows -> T {
        if DispatchQueue.getSpecific(key: Connection.queueKey) == queueContext {
            return try block() // if in self seecific queue, execute
        } else {
            return try queue.sync(execute: block) // otherwise back to queue sync execute
        }
    }
}



// MARK: - Connection filename
extension Connection : CustomStringConvertible {
    public var description: String {
        return String(cString: sqlite3_db_filename(handle, nil))
    }
    
}
