//
//  HQCacheTests.swift
//  HQCacheTests
//
//  Created by qihuang on 2018/3/26.
//  Copyright © 2018年 com.personal.HQ. All rights reserved.
//

import XCTest
@testable import HQCache

class HQMemoryCacheTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testCommonEvent() {
        let memoryCache = HQMemoryCache()
        
        // test insert update delete and query function
        let str = "text data 1"
        memoryCache.insertOrUpdate(object: str, forKey: "stringKey")
        
        // query
        let testStr = memoryCache.query(objectForKey: "stringKey") as? String
        XCTAssertEqual(testStr, str, "Test insert string")
        
        // check
        let exist1 = memoryCache.exist(forKey: "stringKey")
        XCTAssertTrue(exist1)
        
        // update
        let str2 = "text data 2"
        memoryCache.insertOrUpdate(object: "text data 2", forKey: "stringKey")
        let testStr2 = memoryCache.query(objectForKey: "stringKey") as? String
        XCTAssertEqual(testStr2, str2)
        XCTAssertNotEqual(testStr2, str)
        
        // delete
        memoryCache.delete(objectForKey: "stringKey")
        let testStr3 = memoryCache.query(objectForKey: "stringKey") as? String
        XCTAssertNil(testStr3)
        
        // check
        let exist2 = memoryCache.exist(forKey: "stringKey")
        XCTAssertFalse(exist2)
    }
    
    
    func testLimitCount() {
        let memoryCache = HQMemoryCache()
        memoryCache.countLimit = 3
        
        for i in 0 ..< 10 {
            memoryCache.insertOrUpdate(object: i, forKey: "\(i)")
        }
        
        // hold lastest 3 item
        XCTAssertNil(memoryCache.query(objectForKey: "1"))
        XCTAssertFalse(memoryCache.exist(forKey: "2"))
        XCTAssertEqual(3, memoryCache.getTotalCount())
        XCTAssertNotNil(memoryCache.query(objectForKey: "7"))
        XCTAssertNotNil(memoryCache.query(objectForKey: "9"))
        XCTAssertNotNil(memoryCache.query(objectForKey: "8"))
    }
    
    func testLimitCost() {
        let memoryCache = HQMemoryCache()
        
        memoryCache.costLimit = 40
        for i in 0 ..< 10 {
            memoryCache.insertOrUpdate(object: i, forKey: "\(i)", cost: 10)
        }
        
        // hold lastest 3 item
        XCTAssertNil(memoryCache.query(objectForKey: "1"))
        XCTAssertFalse(memoryCache.exist(forKey: "2"))
        XCTAssertEqual(40, memoryCache.getTotalCost())
        XCTAssertNotNil(memoryCache.query(objectForKey: "7"))
        XCTAssertNotNil(memoryCache.query(objectForKey: "9"))
        XCTAssertNotNil(memoryCache.query(objectForKey: "8"))
    }
    
    func testLimitAge() {
        let memoryCache = HQMemoryCache()
        memoryCache.ageLimit = 3
        
        for i in 0 ... 10 {
            memoryCache.insertOrUpdate(object: i, forKey: "\(i)", cost: 10)
        }
        
        sleep(4)
        // all empty
        XCTAssertNil(memoryCache.query(objectForKey: "1"))
        XCTAssertFalse(memoryCache.exist(forKey: "2"))
        XCTAssertEqual(0, memoryCache.getTotalCost())
        XCTAssertEqual(0, memoryCache.getTotalCount())
    }
    
    func testLimitManual() {
        let memoryCache = HQMemoryCache()
        
        for i in 0 ... 10 {
            memoryCache.insertOrUpdate(object: i, forKey: "\(i)", cost: 10)
        }
        
        memoryCache.deleteCache(exceedToCount: 8)
        XCTAssertNil(memoryCache.query(objectForKey: "1"))
        XCTAssertFalse(memoryCache.exist(forKey: "2"))
        XCTAssertEqual(8, memoryCache.getTotalCount())
        
        memoryCache.deleteCache(exceedToCost: 40)
        XCTAssertNil(memoryCache.query(objectForKey: "4"))
        XCTAssertFalse(memoryCache.exist(forKey: "6"))
        XCTAssertEqual(40, memoryCache.getTotalCost())
    }
    
    
    
    func testMultiQueue() {
        let memoryCache = HQMemoryCache()
        memoryCache.countLimit = 10
        memoryCache.costLimit = 345
        
        let group = DispatchGroup()
        let queue1 = DispatchQueue(label: "1", qos: .default, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil)
        let queue2 = DispatchQueue(label: "2", qos: .default, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil)
        let queue3 = DispatchQueue(label: "3", qos: .default, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil)
        
        group.enter()
        queue1.async {
            for i in 0 ... 10 {
                memoryCache.insertOrUpdate(object: i, forKey: "\(i)", cost: UInt(i))
            }
            group.leave()
        }
        
        group.enter()
        queue2.async {
            for i in 0 ... 10 {
                memoryCache.insertOrUpdate(object: i*10, forKey: "\(i)", cost: UInt(i*10))
            }
            group.leave()
        }
        
        group.enter()
        queue3.async {
            for i in 0 ... 10 {
                memoryCache.insertOrUpdate(object: i*100, forKey: "\(i)", cost: UInt(i*100))
            }
            group.leave()
        }
        
        group.notify(queue: DispatchQueue.main, work: DispatchWorkItem.init(block: {
            XCTAssertLessThanOrEqual(memoryCache.getTotalCount(), 10)
            XCTAssertLessThanOrEqual(memoryCache.getTotalCost(), 345)
            for i in 0 ... 10 {
                print(memoryCache.query(objectForKey: "\(i)") ?? "empty")
            }
        }))
    }
}
