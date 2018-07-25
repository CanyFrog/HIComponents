//
//  InnerKeyMapTest.swift
//  HQDownloadTests
//
//  Created by HonQi on 7/4/18.
//  Copyright © 2018 HonQi Indie. All rights reserved.
//

import XCTest
@testable import HQDownload

class InnerKeyMapTest: XCTestCase {
    typealias TestValue = ()->()
    var keyMap: InnerKeyMap<TestValue>!
    
    override func setUp() {
        super.setUp()
        keyMap = InnerKeyMap()
    }
    
    override func tearDown() {
        super.tearDown()
        keyMap?.removeAll()
        keyMap = nil
    }
    
    func testInsertValue() {
        let count = 2
        insertValues(times: count)
        XCTAssertEqual(count, keyMap.count)
    }
    
    func testMapCount() {
        XCTAssertEqual(0, keyMap.count)
        
        insertValues(times: 1)
        XCTAssertEqual(1, keyMap.count)
        
        insertValues(times: keyMap.ArrayMaxSize-1)
        XCTAssertEqual(keyMap.ArrayMaxSize, keyMap.count)
        
        insertValues(times: 5)
        XCTAssertEqual(keyMap.ArrayMaxSize+5, keyMap.count)
    }
    
    func testRemoveValueForKey() {
        let key = keyMap.insert {
            print("test ...")
        }
        XCTAssertEqual(1, keyMap.count)
        let value = keyMap.remove(key)
        XCTAssertNotNil(value)
        XCTAssertEqual(0, keyMap.count)
    }

    func testRemoveAll() {
        let count = 31
        insertValues(times: count)
        XCTAssertEqual(count, keyMap.count)
        keyMap.removeAll()
        XCTAssertEqual(0, keyMap.count)
    }
    
    
    func testForEachLoop() {
        var preNum: Int = 0
        
        for i in 1 ..< 33 {
            keyMap.insert{
                print("do ....")
                XCTAssertTrue(i > preNum)
                preNum = i
            }
        }
        
        keyMap.forEach { (c) in
            c()
        }
    }
    
    func insertValues(times: Int) {
        for i in 0 ..< times {
            keyMap.insert {
                print("Insert the \(i)th value ....")
            }
        }
    }
}
