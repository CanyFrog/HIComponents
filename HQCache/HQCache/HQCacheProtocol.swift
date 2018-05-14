//
//  HQCacheProtocol.swift
//  HQCache
//
//  Created by qihuang on 2018/3/26.
//  Copyright © 2018年 com.personal.HQ. All rights reserved.
//

import Foundation

extension Encodable {
    func serialize() -> Data? {
        return try? JSONEncoder().encode(self)
    }
}
extension Decodable {
    static func unSerialize<T: Decodable>(_ encoded: Data) -> T? {
        return try? JSONDecoder().decode(T.self, from: encoded)
    }
}

/// Cache background queue protocol
protocol HQCacheInBackProtocol: HQCacheProtocol {
    
    func exist(forKey key: String, inBackThreadCallback callback: @escaping (_ key: String, _ isExists: Bool) -> Void)
    
    // delete
    func delete(objectForKey key: String, inBackThreadCallback callback: @escaping (_ key: String) -> Void)
    
    func deleteAllCache(inBackThread callback: @escaping () -> Void )
    func deleteAllCache(withProgressClosure progress: @escaping (_ deleted: Int, _ total: Int, _ end: Bool) -> Void)
    
    func deleteCache(exceedToCount count: Int, inBackThread complete: @escaping ()->Void)
    
    func deleteCache(exceedToCost cost: Int, inBackThread complete: @escaping ()->Void)
    
    func deleteCache(exceedToAge age: TimeInterval, inBackThread complete: @escaping ()->Void)
    
    
    // get cache information
    func getTotalCount(inBackThread closure: @escaping (_ count: Int)->Void)
    func getTotalCost(inBackThread closure: @escaping (_ count: Int) -> Void)
}

/// Cache protocol
protocol HQCacheProtocol {
    
    /// Cache count limit, default Int.max
    var countLimit: Int {get set}
    
    /// Cache item size limit, default Int.max
    var costLimit: Int {get set}
    
    /// Cache item storted time limit, default Double.max
    var ageLimit: TimeInterval {get set}
    
    /// Cache manager auto trim invalid item time
    var autoTrimInterval: TimeInterval {get set}
    
    // query
    func exist(forKey key: String) -> Bool
    
    // delete
    func delete(objectForKey key: String)
    func deleteAllCache()
    
    func deleteCache(exceedToCount count: Int)
    
    func deleteCache(exceedToCost cost: Int)
    
    func deleteCache(exceedToAge age: TimeInterval)
    
    
    // get cache information
    func getTotalCount() -> Int
    func getTotalCost() -> Int
}

