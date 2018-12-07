//
//  SqliteConnectionTest.swift
//  HQSqliteTests
//
//  Created by HonQi on 2018/4/1.
//  Copyright © 2018年 HonQi Indie. All rights reserved.
//

import XCTest
import SQLite3
@testable import HQSqlite

class HQSqliteConnectionTest: HQSqliteTests {
    override func setUp() {
        super.setUp()
        createTable()
    }
    
    func testConnectInitInMemory() {
        let conn = try! Connection(.memory)
        XCTAssertEqual("", conn.description)
    }
    
    func testConnectInitInTemporary() {
        let conn = try! Connection(.temporary)
        XCTAssertEqual("", conn.description)
    }
    
    func testConnectInitByDefault() {
        let conn = try! Connection()
        XCTAssertEqual("", conn.description)
    }
    
    func testConnectInitWithUri() {
        let path = "\(NSTemporaryDirectory())/connection_test.sqlite3"
        let conn = try! Connection(.uri(path))
        XCTAssertEqual(path, conn.description)
    }
    
    func testConnectReadOnlyWhenInitReadOnly() {
        let conn = try! Connection(.memory, readOnly: true)
        XCTAssertTrue(conn.readonly)
    }
    
    func testConnectNotReadOnlyByDefault() {
        let conn = try! Connection()
        XCTAssertFalse(conn.readonly)
    }
    
    func testConnectionInitNoChanges() {
        let conn = try! Connection()
        XCTAssertEqual(0, conn.changes)
        XCTAssertEqual(0, conn.totalChanges)
    }
    
    func testConnectLastIdAfterInserts() {
        try! insertUser("test_user_1")
        XCTAssertEqual(1, connect.lastInsertRowid)
    }
    
    func testConnectLastIdDoesNotResetAfterError() {
        XCTAssertEqual(0, connect.lastInsertRowid)
        try! insertUser("test_user_2")
        XCTAssertEqual(1, connect.lastInsertRowid)
        XCTAssertThrowsError(
            try connect.run("INSERT INTO \"users\" (email, age, admin) values ('error_user', 12, 'null')"), "insert error")
        { (err) in
            if case SQLError.error(message: _, code: let code, statement: _) = err {
                XCTAssertEqual(SQLITE_CONSTRAINT, code) // sqlite3 failer code
            }
            else {
                XCTFail(err.localizedDescription)
            }
        }
        XCTAssertEqual(1, connect.lastInsertRowid)
    }
    
    func testConnectChanges() {
        try! insertUser("test_user_3")
        XCTAssertEqual(1, connect.changes)
        try! insertUser("test_user_4")
        XCTAssertEqual(1, connect.changes)
    }
    
    func testConnectTotalChanges() {
        XCTAssertEqual(0, connect.totalChanges)
        try! insertUser("test_user_5")
        XCTAssertEqual(1, connect.totalChanges)
        try! insertUser("test_user_6")
        XCTAssertEqual(2, connect.totalChanges)
    }
    
    func testConnectPrepareReturnStatement() {
        XCTAssertNotNil(try! connect.prepare("SELECT * FROM users WHERE admin = 0"))
        XCTAssertNotNil(try! connect.prepare("SELECT * FROM users WHERE admin = ?", 0))
        XCTAssertNotNil(try! connect.prepare("SELECT * FROM users WHERE admin = ?", [0]))
        XCTAssertNotNil(try! connect.prepare("SELECT * FROM users WHERE admin = $admin", ["$admin": 0]))
    }
    
    func testConnectRunReturnStatements() {
        XCTAssertNotNil(try! connect.run("SELECT * FROM users WHERE admin = 0"))
        XCTAssertNotNil(try! connect.run("SELECT * FROM users WHERE admin = ?", 0))
        XCTAssertNotNil(try! connect.run("SELECT * FROM users WHERE admin = ?", [0]))
        XCTAssertNotNil(try! connect.run("SELECT * FROM users WHERE admin = $admin", ["$admin": 0]))
        XCTAssertEqual(trace["SELECT * FROM users WHERE admin = 0"], 4)
    }
    
    func testConnectUpdateHookWithInsert() {
        async { (done) in
            connect.updateHook({ (operation, db, table, rowid) in
                XCTAssertEqual(Connection.SqliteOperation.insert, operation)
                XCTAssertEqual("main", db)
                XCTAssertEqual("users", table)
                XCTAssertEqual(1, rowid)
                done()
            })
            try! insertUser("test_insert_hook")
        }
    }
    
    func testConnectUpdateHookWithUpdate() {
        try! insertUser("test_update_hook_1")
        async { (done) in
            connect.updateHook({ (operation, db, table, rowid) in
                XCTAssertEqual(Connection.SqliteOperation.update, operation)
                XCTAssertEqual("main", db)
                XCTAssertEqual("users", table)
                XCTAssertEqual(1, rowid)
                done()
            })
            try! connect.run("UPDATE users SET email = 'test_update_hook_2'")
        }
    }
    
    func testConnectUpdateHookWithDelete() {
        try! insertUser("test_delete_hook")
        async { (done) in
            connect.updateHook({ (operation, db, table, rowid) in
                XCTAssertEqual(Connection.SqliteOperation.delete, operation)
                XCTAssertEqual("main", db)
                XCTAssertEqual("users", table)
                XCTAssertEqual(1, rowid)
                done()
            })
            try! connect.run("DELETE FROM users WHERE id = 1")
        }
    }
    
    func testConnectCommiteHook() {
        async { (done) in
            connect.commitHook({
                done()
            })
            try! connect.transaction {
                try! self.insertUser("test_commit")
            }
            let stmt = try! connect.prepare("SELECT count(*) FROM users")
            let _ = try! stmt.step()
            XCTAssertEqual(1, stmt.cursor[0])
        }
    }
    
    func testConnectRollbackHook() {
        async { (done) in
            connect.rollbackHook(done)
            do {
                try connect.transaction {
                    try self.insertUser("test_rollback")
                    try self.insertUser("test_rollback") // repeat, throw and rollback
                }
            } catch { }
            let stmt = try! connect.prepare("SELECT count(*) FROM users")
            let _ = try! stmt.step()
            XCTAssertEqual(0, stmt.cursor[0])
        }
    }
    
    func testConnectCommitAndRollbackHook() {
        async { (done) in
            connect.commitHook({
                // custom throw error
                throw NSError(domain: "test.commit_rollback.error", code: 1, userInfo: nil)
            })
            connect.rollbackHook(done)
            do {
                try connect.transaction {
                    try self.insertUser("test_commit_rollback")
                }
            }catch {}
            let stmt = try! connect.prepare("SELECT count(*) FROM users")
            let _ = try! stmt.step()
            XCTAssertEqual(0, stmt.cursor[0])
        }
    }
    
    
    func testConnectTransactionDeferred() {
        try! connect.transaction(.deferred) {}
        XCTAssertEqual(trace["BEGIN DEFERRED TRANSACTION"], 1)
    }
    
    func testConnectTransactionImmediate() {
        try! connect.transaction(.immediate) {}
        XCTAssertEqual(trace["BEGIN IMMEDIATE TRANSACTION"], 1)
    }
    
    func testConnectTransactionExclusive() {
        try! connect.transaction(.exclusive) {}
        XCTAssertEqual(trace["BEGIN EXCLUSIVE TRANSACTION"], 1)
    }
    
    func testConnectTransactionBeginAndCommit() {
        let stmt = try! connect.prepare("INSERT INTO users (email) VALUES (?)", "test_transaction_begin_commit")
        try! connect.transaction {
            try stmt.run() // stmt will reset all bindings before run, so throw error
        }
        
        XCTAssertEqual(trace["BEGIN DEFERRED TRANSACTION"], 1)
        XCTAssertEqual(trace["INSERT INTO users (email) VALUES ('test_transaction_begin_commit')"], 1)
        XCTAssertEqual(trace["COMMIT TRANSACTION"], 1)
        XCTAssertNil(trace["ROLLBACK TRANSACTION"]) // did not rollback
    }
    
    
    func testConnectTransactionCommitFailure() {
        let stmt = try! connect.prepare("INSERT INTO users (email) VALUES (?)", "test_transaction_commit_rollback")
        
        do {
            try connect.transaction {
                try stmt.run()
                try stmt.run()
            }
        } catch {
        }
        
        XCTAssertEqual(trace["BEGIN DEFERRED TRANSACTION"], 1)
        XCTAssertEqual(trace["INSERT INTO users (email) VALUES ('test_transaction_commit_rollback')"], 2) // execute twice
        XCTAssertNil(trace["COMMIT TRANSACTION"]) // did not commit
        XCTAssertEqual(trace["ROLLBACK TRANSACTION"], 1) // rollback because stmt throw error
    }
    
    
    func testConnectSavepointBegin() {
        try! connect.savepoint("1", block: {
            try self.connect.savepoint("2", block: {
                try self.connect.run("INSERT INTO users (email) VALUES (?)", "test_savepoint_begin")
            })
        })
        XCTAssertEqual(trace["SAVEPOINT '1'"], 1)
        XCTAssertEqual(trace["SAVEPOINT '2'"], 1)
        XCTAssertEqual(trace["INSERT INTO users (email) VALUES ('test_savepoint_begin')"], 1)
        XCTAssertEqual(trace["RELEASE SAVEPOINT '2'"], 1)
        XCTAssertEqual(trace["RELEASE SAVEPOINT '1'"], 1)
        XCTAssertNil(trace["ROLLBACK TO SAVEPOINT '2'"])
        XCTAssertNil(trace["ROLLBACK TO SAVEPOINT '1'"])
    }
    
    func testConnectSavapointRollback() {
        let stmt = try! connect.prepare("INSERT INTO users (email) VALUES (?)", "test_savepoint_begin_rollback")
        
        do {
            try connect.savepoint("1", block: {
                try self.connect.savepoint("2", block: {
                    try stmt.run()
                    try stmt.run()
                })
                
                try self.connect.savepoint("2", block: {
                    try stmt.run()
                    try stmt.run()
                })
            })
        } catch {
        }
        XCTAssertEqual(trace["SAVEPOINT '1'"], 1)
        XCTAssertEqual(trace["SAVEPOINT '2'"], 1) // only save once
        XCTAssertEqual(trace["INSERT INTO users (email) VALUES ('test_savepoint_begin_rollback')"], 2)
        XCTAssertEqual(trace["ROLLBACK TO SAVEPOINT '2'"], 1)
        XCTAssertEqual(trace["ROLLBACK TO SAVEPOINT '1'"], 1)
        XCTAssertNil(trace["RELEASE SAVEPOINT '2'"])
        XCTAssertNil(trace["RELEASE SAVEPOINT '1'"])
    }
    
    func testConnectMultiThreadWorking() {
        let newConn = try! Connection(.uri("\(NSTemporaryDirectory())/\(UUID().uuidString)"))
        try! newConn.execute("DROP TABLE IF EXISTS test; CREATE TABLE test(value);")
        try! newConn.run("INSERT INTO test(value) VALUES(?)", 0)
        
        let queue = DispatchQueue(label: "sqlite_reader_queue", qos: .default, attributes: [.concurrent])
        
        let readersNum = 10
        var reads = Array(repeating: 0, count: readersNum)
        
        var isFinished = false
        for index in 0 ..< readersNum {
            queue.async {
                while !isFinished {
                    let _ = try! newConn.run("SELECT value FROM test")
                    reads[index] += 1
                }
            }
        }
        
        while !isFinished {
            sleep(1)
            // reads some item at least get more than 500 finished
            isFinished = reads.reduce(true, { $0 && ($1 > 500) })
        }
    }
}
