//
//  HQCacheProtocol.swift
//  HQCache
//
//  Created by qihuang on 2018/3/26.
//  Copyright © 2018年 com.personal.HQ. All rights reserved.
//

import Foundation

protocol HQCacheInBackProtocol: HQCacheProtocol {
    func exist(forKey key: String, inBackThreadCallback callback: @escaping (_ key: String, _ isExists: Bool) -> Void)
    
    func query(objectForKey key: String, inBackThreadCallback callback: @escaping (_ key: String, _ obj: Any?) -> Void)
    
    func insertOrUpdate(object obj: Any, forKey key: String, inBackThreadCallback callback: @escaping () -> Void)
    
    // delete
    func delete(objectForKey key: String, inBackThreadCallback callback: @escaping (_ key: String) -> Void)
    
    func deleteAllCache(inBackThread callback: @escaping () -> Void )
    func deleteAllCache(withProgressClosure progress: @escaping (_ deleted: UInt, _ total: UInt, _ end: Bool) -> Void)
    
    func deleteCache(exceedToCount count: UInt, inBackThread complete: @escaping ()->Void)
    
    func deleteCache(exceedToCost cost: UInt, inBackThread complete: @escaping ()->Void)
    
    func deleteCache(exceedToAge: TimeInterval, inBackThread complete: @escaping ()->Void)
    
    
    // get cache information
    func getTotalCount(inBackThread closure: @escaping (_ count: UInt)->Void)
    func getTotalCost(inBackThread closure: @escaping (_ count: UInt) -> Void)
}


/// Cache protocol
protocol HQCacheProtocol {
    var name: String {get set}
    
    var countLimit: UInt {get set}
    var costLimit: UInt {get set}
    var ageLimit: TimeInterval {get set}
    var autoTrimInterval: TimeInterval {get set}
    
    // query
    func exist(forKey key: String) -> Bool
    
    func query(objectForKey key: String) -> Any?
    
    
    // insert and update
    func insertOrUpdate(object obj: Any, forKey key: String, cost: UInt)
    
    // delete
    func delete(objectForKey key: String)
    func deleteAllCache()
    
    func deleteCache(exceedToCount count: UInt)
    
    func deleteCache(exceedToCost cost: UInt)
    
    func deleteCache(exceedToAge age: TimeInterval)
    
    
    // get cache information
    func getTotalCount() -> UInt
    func getTotalCost() -> UInt
}
