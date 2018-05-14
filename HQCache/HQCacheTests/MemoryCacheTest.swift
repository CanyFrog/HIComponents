//
//  MemoryCacheTest.swift
//  HQCacheTests
//
//  Created by qihuang on 2018/4/5.
//  Copyright © 2018年 com.personal.HQ. All rights reserved.
//

import XCTest
@testable import HQCache

class HQMemoryCacheTest: XCTestCase {
    var memory: MemoryCache!

    override func setUp() {
        super.setUp()
        memory = MemoryCache()
    }


    func testMemoryObjExistAfterInsert() {
        memory.insertOrUpdate(object: MemoryCache(), forKey: "testClass")
        XCTAssertTrue(memory.exist(forKey: "testClass"))
    }

    func testMemoryInsertAndQuery() {
        memory.insertOrUpdate(object: 56732, forKey: "number")
        XCTAssertEqual(56732, memory.query(objectForKey: "number"))

        memory.insertOrUpdate(object: "test_string", forKey: "string")
        XCTAssertEqual("test_string", memory.query(objectForKey: "string"))

        let cls = Array(repeating: 1, count: 10)
        memory.insertOrUpdate(object: cls, forKey: "class")
        XCTAssertEqual(cls, memory.query(objectForKey: "class"))
    }

    func testMemoryTotalCount() {
        let count = 10
        insertMultiValues(count)
        XCTAssertEqual(count, memory.getTotalCount())
    }

    func testMemoryTotalCost() {
        let count = 10
        let cost = insertMultiValues(count)
        XCTAssertEqual(cost, memory.getTotalCost())
    }

    func testMemoryUpdate() {
        memory.insertOrUpdate(object: 56732, forKey: "number")
        XCTAssertEqual(56732, memory.query(objectForKey: "number"))
        memory.insertOrUpdate(object: "change_to_string", forKey: "number")
        XCTAssertEqual("change_to_string", memory.query(objectForKey: "number"))
    }

    func testMemoryDelete() {
        memory.insertOrUpdate(object: 123, forKey: "123")
        memory.insertOrUpdate(object: 456, forKey: "456")
        memory.delete(objectForKey: "123")
        XCTAssertNil(memory.query(objectForKey: "123"))
        XCTAssertEqual(456, memory.query(objectForKey: "456"))
    }

    func testMemoryDeleteAll() {
        memory.insertOrUpdate(object: 123, forKey: "123")
        memory.insertOrUpdate(object: 456, forKey: "456")
        XCTAssertEqual(2, memory.getTotalCount())

        memory.deleteAllCache()
        XCTAssertNil(memory.query(objectForKey: "123"))
        XCTAssertNil(memory.query(objectForKey: "456"))
    }

    func testMemoryCountLimit() {
        memory.countLimit = 8
        insertMultiValues(15)

        // waiting for auto clear to limit
        XCTAssertEqual(memory.countLimit, memory.getTotalCount())
    }

    func testMemoryClearToCount() {
        let count = 8
        insertMultiValues(count*2)
        memory.deleteCache(exceedToCount: count)
        XCTAssertEqual(count, memory.getTotalCount())
    }

    func testMomeryCostLimit() {
        memory.costLimit = 60
        insertMultiValues(20)
        // waiting for auto clear to limit
        XCTAssertLessThanOrEqual(memory.getTotalCost(), memory.costLimit)
    }

    func testMemoryClearToCost() {
        let totalCost = 60
        insertMultiValues(20)
        memory.deleteCache(exceedToCost: totalCost)
        XCTAssertLessThanOrEqual(memory.getTotalCost(), totalCost)
    }

    func testMemotyAgeLimit() {
        memory.ageLimit = 1
        memory.autoTrimInterval = 1
        let count = 5
        insertMultiValues(count)
        sleep(2) // wait 2 secons auto clear
        insertMultiValues(count)
        XCTAssertEqual(count, memory.getTotalCount())
    }

    func testMemoryClearToAge() {
        let count = 5
        insertMultiValues(count)
        sleep(2) // wait 2 secons
        insertMultiValues(count)
        memory.deleteCache(exceedToAge: 1) // clear age over than 1 second items
        XCTAssertEqual(count, memory.getTotalCount())
    }
}

extension HQMemoryCacheTest {
    @discardableResult
    func insertMultiValues(_ num: Int) -> Int {
        var cost = 0
        for idx in 0 ..< num {
            memory.insertOrUpdate(object: idx, forKey: "\(idx)", cost: idx)
            cost += idx
        }
        return cost
    }
}
