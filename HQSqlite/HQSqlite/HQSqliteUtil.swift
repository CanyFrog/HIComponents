//
//  HQSqliteUtil.swift
//  HQSqlite
//
//  Created by Magee Huang on 3/29/18.
//  Copyright © 2018 HQ.Personal.modules. All rights reserved.
//
// Study and mock from SQLite https://github.com/stephencelis/SQLite.swift

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


extension HQSqliteConnection {
    /// An SQL operation passed to update callbacks.
    public enum SqliteOperation {
        
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
}

extension HQSqliteConnection {
    /// The mode in which a transaction acquires a lock.
    public enum TransactionMode : String {
        
        /// Defers locking the database till the first read/write executes.
        case deferred = "DEFERRED"
        
        /// Immediately acquires a reserved lock on the database.
        case immediate = "IMMEDIATE"
        
        /// Immediately acquires an exclusive lock on all databases.
        case exclusive = "EXCLUSIVE"
        
    }
}
