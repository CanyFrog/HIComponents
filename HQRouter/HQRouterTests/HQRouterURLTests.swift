//
//  HQRouterURLTests.swift
//  HQRouterTests
//
//  Created by Magee Huang on 5/17/18.
//  Copyright © 2018 HQ.components.router. All rights reserved.
//

import XCTest
@testable import HQRouter

class HQRouterURLTests: XCTestCase {
    
    func testURLQueryItemInitWithoutValue() {
        let item = RouterURLQueryItem(pair: "testKey=")
        XCTAssertNotNil(item)
        XCTAssertNil(item.value)
        
        let item1 = RouterURLQueryItem(pair: "testKey")
        XCTAssertNotNil(item1)
        XCTAssertNil(item1.value)
    }
    
    func testURLQueryItemInitWithSpecialValue() {
        let item = RouterURLQueryItem(pair: "key==")
        XCTAssertEqual(item.value!, "=")
    }
    
    
    func testURLPathComponentInitWithoutQuery() {
        let path = RouterURLComponent(component: "path")
        XCTAssertNotNil(path)
        XCTAssertNil(path.queryItems)
        
        let path1 = RouterURLComponent(component: "path?")
        XCTAssertNotNil(path1)
        XCTAssertNil(path1.queryItems)
    }
}


