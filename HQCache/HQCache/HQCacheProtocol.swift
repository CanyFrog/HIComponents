//
//  HQCacheProtocol.swift
//  HQCache
//
//  Created by qihuang on 2018/3/26.
//  Copyright © 2018年 com.personal.HQ. All rights reserved.
//

import Foundation

/// Cache background queue protocol
protocol HQCacheInBackProtocol: HQCacheProtocol {
    
    func exist(forKey key: String, inBackThreadCallback callback: @escaping (_ key: String, _ isExists: Bool) -> Void)
    
//    func query<T: NSCoding>(objectForKey key: String) -> T?
    func query<T>(objectForKey key: String, inBackThreadCallback callback: @escaping (_ key: String, _ obj: T?) -> Void)
    
    func query(filePathForKey key: String) -> String?
    func query(filePathForKey key: String, inBackThreadCallback callback: @escaping (_ key: String, _ path: String?) -> Void)
    
//    func insertOrUpdate<T: NSCoding>(object obj: T, forKey key: String)
    func insertOrUpdate<T>(object obj: T, forKey key: String, cost: Int, inBackThreadCallback callback: @escaping () -> Void)
    
    func insertOrUpdate(file path: String, forKey key: String)
    func insertOrUpdate(file path: String, forKey key: String, inBackThreadCallback callback: @escaping () -> Void)
    
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
    var name: String {get set}
    
    var countLimit: Int {get set}
    var costLimit: Int {get set}
    var ageLimit: TimeInterval {get set}
    var autoTrimInterval: TimeInterval {get set}
    
    // query
    func exist(forKey key: String) -> Bool
    
    func query<T>(objectForKey key: String) -> T?    // optional
    
    
    // insert and update
    func insertOrUpdate<T>(object obj: T, forKey key: String, cost: Int) // optional
    
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

//extension HQCacheProtocol {
//    func query(objectForKey key: String) -> Any? { return nil }
//    func insertOrUpdate(object obj: Any, forKey key: String, cost: Int) {}
//}

