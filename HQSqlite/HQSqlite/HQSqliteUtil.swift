//
//  HQSqliteUtil.swift
//  HQSqlite
//
//  Created by Magee Huang on 3/29/18.
//  Copyright © 2018 HQ.Personal.modules. All rights reserved.
//

import Foundation
import SQLite3


extension HQSqliteConnection {
    public enum SqliteType {
        
        /// An in-memory database (equivalent to `.uri(":memory:")`).
        case memory
        
        /// A temporary database, save in file, Automatically delete after use (equivalent to `.uri("")`).
        case temporary
        
        /// A database located at given uri filename or path
        case uri(String)
    }
}


extension HQSqliteConnection.SqliteType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .memory:
            return ":memory:"
        case .temporary:
            return ""
        case .uri(let URI):
            return URI
        }
    }
}


/// An SQL operation passed to update callbacks.
public enum HQSqliteOperation {
    
    /// An INSERT operation.
    case insert
    
    /// An UPDATE operation.
    case update
    
    /// A DELETE operation.
    case delete
    
    init(rawValue:Int32) {
        switch rawValue {
        case SQLITE_INSERT:
            self = .insert
        case SQLITE_UPDATE:
            self = .update
        case SQLITE_DELETE:
            self = .delete
        default:
            fatalError("unhandled operation code: \(rawValue)")
        }
    }
}
