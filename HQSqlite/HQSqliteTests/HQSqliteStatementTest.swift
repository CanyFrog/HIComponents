//
//  HQSqliteStatementTest.swift
//  HQSqliteTests
//
//  Created by qihuang on 2018/4/1.
//  Copyright © 2018年 HQ.Personal.modules. All rights reserved.
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
    
    func testStatementColumnCount() {
        let stmt = try! HQSqliteStatement(connect, "INSERT INTO \"users\" (email, age, salary, desc, admin) VALUES (?,?,?,?,?)")
        stmt.bind(["test_email", 12, 12.0, "fasd", false])
        XCTAssertEqual(stmt.columnCount, 5)
    }
}
