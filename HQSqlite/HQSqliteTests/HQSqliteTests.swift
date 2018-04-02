//
//  HQSqliteTests.swift
//  HQSqliteTests
//
//  Created by Magee Huang on 3/29/18.
//  Copyright © 2018 HQ.Personal.modules. All rights reserved.
//

import XCTest
import SQLite3
@testable import HQSqlite

class HQSqliteTests: XCTestCase {
    var connect: HQSqliteConnection!
    var trace: [String: Int]!
    
//    let file = "/Users/huangcong/Desktop/sss/test.sqlite"
//    if !FileManager.default.fileExists(atPath: file) {
//    FileManager.default.createFile(atPath: file, contents: nil, attributes: nil)
//    }
    
    override func setUp() {
        super.setUp()
        connect = try! HQSqliteConnection()
        trace  =  [String: Int]()
        
        connect.trace { (SQL) in
            print("Execute \(SQL)")
            self.trace[SQL, default: 0] += 1
        }
    }
    
    
    func createTable() {
        try! connect.execute("""
            pragma journal_mode = wal;
            pragma synchronous = normal;
            CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY,
                email TEXT NOT NULL UNIQUE,
                age INTEGER,
                salary REAL,
                desc BLOB,
                admin BOOLEAN NOT NULL DEFAULT 0 CHECK (admin IN (0,1)),
                manager_id INTEGER,
                FOREIGN KEY(manager_id) REFERENCES USERS(id)
            )
            """
        )
    }
    
    @discardableResult
    func insertUser(_ email: String, age: Int? = nil, salary: Double? = nil, desc: Data? = nil, admin: Bool = false) throws -> HQSqliteStatement {
        return try connect.run("INSERT INTO \"users\" (email, age, salary, desc, admin) VALUES (?,?,?,?,?)", [email, age, salary, desc, admin])
    }
    
    
    func async(expect description: String = "async", timeout: Double = 5, block: (@escaping () -> Void) -> Void) {
        let expectation = self.expectation(description: description)
        block({ expectation.fulfill() })
        waitForExpectations(timeout: timeout, handler: nil)
    }
}



