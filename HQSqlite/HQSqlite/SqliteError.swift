//
//  SqliteError.swift
//  HQSqlite
//
//  Created by HonQi on 3/29/18.
//  Copyright © 2018 HonQi Indie. All rights reserved.
//

import Foundation
import SQLite3

public enum SqliteError: Error {
    private static let successCode: Set = [SQLITE_OK, SQLITE_ROW, SQLITE_DONE]
    
    case error(message: String, code: Int32, statement: Statement?)
    
    init?(errorCode: Int32, connection: Connection, statement: Statement? = nil) {
        guard !SqliteError.successCode.contains(errorCode) else { return nil } // success
        let msg = String(cString: sqlite3_errmsg(connection.handle))
        self = .error(message: msg, code: errorCode, statement: statement)
    }
}

extension SqliteError: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .error(msg, code, stmt):
            if let stmt = stmt {
                return "\(msg) (\(stmt)) (code: \(code))"
            }
            else {
                return "\(msg) (code: \(code))"
            }
        }
    }
}
