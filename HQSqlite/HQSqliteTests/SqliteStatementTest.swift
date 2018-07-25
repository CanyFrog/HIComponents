//
//  SqliteStatementTest.swift
//  HQSqliteTests
//
//  Created by HonQi on 2018/4/1.
//  Copyright © 2018年 HonQi Indie. All rights reserved.
//

import XCTest
import SQLite3
@testable import HQSqlite


/// connection test cover statement feature
class HQSqliteStatementTest: HQSqliteTests {
    override func setUp() {
        super.setUp()
        createTable()
    }
    
    func testStatement() {
        try! insertUser("test_statement_email", age: 18, salary: 9999.0, desc: "This is description".data(using: .utf8), admin: true)
        let stmt = try! Statement(connect, "SELECT * FROM users")
        let _ = try! stmt.step()
        XCTAssertEqual(stmt.columnCount, 7)
        XCTAssertEqual(stmt.columnNames.count, 7)
        
        XCTAssertEqual(stmt.cursor[0], 1)
        XCTAssertEqual(stmt.cursor[1], "test_statement_email")
        XCTAssertEqual(stmt.cursor[2], 18)
        XCTAssertEqual(stmt.cursor[3], 9999.0)
        XCTAssertEqual(stmt.cursor[4], "This is description".data(using: .utf8))
        XCTAssertEqual(stmt.cursor[5], true)
        XCTAssertNil(stmt.cursor[6])
    }
}
