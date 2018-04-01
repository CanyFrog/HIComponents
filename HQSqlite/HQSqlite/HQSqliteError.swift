//
//  HQSqliteError.swift
//  HQSqlite
//
//  Created by Magee Huang on 3/29/18.
//  Copyright © 2018 HQ.Personal.modules. All rights reserved.
//

import Foundation
import SQLite3

public enum HQSqliteError: Error {
    private static let successCode: Set = [SQLITE_OK, SQLITE_ROW, SQLITE_DONE]
    
    case error(message: String, code: Int32, statement: HQSqliteStatement?)
    
    init?(errorCode: Int32, connection: HQSqliteConnection, statement: HQSqliteStatement? = nil) {
        guard !HQSqliteError.successCode.contains(errorCode) else { return nil } // success
        let msg = String(cString: sqlite3_errmsg(connection.handle))
        self = .error(message: msg, code: errorCode, statement: statement)
    }
}

extension HQSqliteError: CustomStringConvertible {
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
