//
//  HQSqliteErrorTest.swift
//  HQSqliteTests
//
//  Created by qihuang on 2018/4/1.
//  Copyright © 2018年 HQ.Personal.modules. All rights reserved.
//

@testable import HQSqlite
import SQLite3
import XCTest

class HQSqliteErrorTest: XCTestCase {
    let conn = try! HQSqliteConnection()
    
    func testErrorWithCodeOK() {
        XCTAssertNil(HQSqliteError(errorCode: SQLITE_OK, connection: conn))
    }
    
    func testErrorWithCodeROW() {
        XCTAssertNil(HQSqliteError(errorCode: SQLITE_ROW, connection: conn))
    }
    
    func testErrorWithCodeDONE() {
        XCTAssertNil(HQSqliteError(errorCode: SQLITE_DONE, connection: conn))
    }
    
    func testErrorWithCodeError() {
        if case .some(.error(let message, let code, let statement)) = HQSqliteError(errorCode: SQLITE_MISUSE, connection: conn) {
            XCTAssertEqual("not an error", message)
            XCTAssertEqual(SQLITE_MISUSE, code)
            XCTAssertNil(statement)
            XCTAssert(self.conn === conn)
        }
        else {
            XCTFail()
        }
    }
    
    func testErrorWithCodeErrorAndDesc() {
        XCTAssertEqual("not an error (code: 21)", HQSqliteError(errorCode: SQLITE_MISUSE, connection: conn)?.description)
    }
    
    func testErrorWithCodeErrorAndStatement() {
        let stmt = try! conn.prepare("SELECT 1")
        XCTAssertEqual("not an error (SELECT 1) (code: 21)", HQSqliteError(errorCode: SQLITE_MISUSE, connection: conn, statement: stmt)?.description)
    }
}
