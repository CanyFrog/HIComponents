//
//  HQRouterURLTests.swift
//  HQRouterTests
//
//  Created by HonQi on 5/17/18.
//  Copyright © 2018 HonQi. All rights reserved.
//

import XCTest
@testable import HQRouter

class HQRouterURLQueryItemTests: XCTestCase {
    
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
    
    func testURLQueryItemDescription() {
        let pairs = "123=431"
        let item = RouterURLQueryItem(pair: pairs)
        XCTAssertEqual(item.description, pairs)
    }
}


class HQRouterURLComponentTests: XCTestCase {
    
    func testURLPathComponentInitWithoutQuery() {
        let path = RouterURLComponent(component: "path")
        XCTAssertNotNil(path)
        XCTAssertNil(path.queryItems)
        
        let path1 = RouterURLComponent(component: "path?")
        XCTAssertNotNil(path1)
        XCTAssertNil(path1.queryItems)
    }
    
    func testURLPathComponentQueryItems() {
        let path = RouterURLComponent(component: "path?key1=value1;key2=value2")
        XCTAssertEqual(path.queryItems?.count, 2)
    }
    
    func testURLPathComponentSubscript() {
        let path = RouterURLComponent(component: "path?int=2;str=aaa;double=5.5;bool=true")
        let intV: Int = path["int"]!
        XCTAssertTrue(intV == 2)
        
        let strV: String = path["str"]!
        XCTAssertTrue(strV == "aaa")
        
        let doubleV: Double = path["double"]!
        XCTAssertTrue(doubleV == 5.5)
        
        let boolV: Bool = path["bool"]
        XCTAssertTrue(boolV)
    }
    
    func testURLPathComponentSeparate() {
        let path1 = "path1?int=2;str=aaa;double=5.5;bool=true"
        let paths1 = RouterURLComponent.separate(url: path1)
        XCTAssertEqual(paths1.count, 1)
        
        let path2 = "path2/int=2/str=aaa/double=5.5/bool=true"
        let paths2 = RouterURLComponent.separate(url: path2)
        XCTAssertEqual(5, paths2.count)
    }
    
    func testURLPathComponentDescription() {
        let str = "path?123=fasd;rer=fas"
        let path = RouterURLComponent(component: str)
        XCTAssertEqual(path.description, str)
    }
}

class HQRouterUrlTests: XCTestCase {
    func testURLInitWithoutPath() {
        let uri = "test://"
        let url = RouterURL(url: uri)
        XCTAssertNotNil(url)
        XCTAssertTrue(url.components.isEmpty)
    }
    
    func testURLInit() {
        let uri = "test://path?ppp=123/path2?ccc=eee"
        let url = RouterURL(url: uri)
        XCTAssertEqual(2, url.components.count)
    }
    
    func testURLSubscript() {
        let uri = "test://path?ppp=123/path2?ccc=eee"
        let url = RouterURL(url: uri)
        
        let path = url["path"]
        XCTAssertNotNil(path)
        XCTAssertEqual(path!["ppp"], 123)
    }
    
    func testURLDescription() {
        let uri = "test://path?123=412"
        let url = RouterURL(url: uri)
        
        XCTAssertEqual(url.description, uri)
    }
    
    
    func testURLForward() {
        let uri = "test://path?123=412"
        var url = RouterURL(url: uri)
        
        let appending = RouterURLComponent(component: "appending?jjj=vvv")
        url.forward(path: [appending])
        XCTAssertEqual(url.description, uri.appending("/appending?jjj=vvv"))
    }
    
    func testURLBack() {
        let uri = "test://path?ppp=123/path2?ccc=eee/path3/path4?123=423/path5"
        let paths = uri.components(separatedBy: "/")
        
        var url = RouterURL(url: uri)
        XCTAssertEqual(5, url.components.count)
        
        url.back()
        XCTAssertEqual(4, url.components.count)
        XCTAssertEqual(url.description, paths[0..<paths.count-1].joined(separator: "/"))
        
        url.back(steps: 2)
        XCTAssertEqual(2, url.components.count)
        XCTAssertEqual(url.description, paths[0..<paths.count-3].joined(separator: "/"))
    }
    
    func testURLCompareDiffScheme() {
        let c1 = RouterURL(url: "test://path?ppp=123/path2?ccc=eee/path3/path4?123=423/path5")
        let c2 = RouterURL(url: "test1://path?ppp=123/path2?ccc=eee/path3/path4?123=423/path5")
        
        XCTAssertEqual(-1, c1.compare(other: c2))
    }
    
    func testURLCompareDiffPath() {
        let c1 = RouterURL(url: "test://path?ppp=123/path2?ccc=eee/path3/path4?123=423/path5")
        let c2 = RouterURL(url: "test://path?ppp=123/path3/path4?123=423/path5")
        
        XCTAssertEqual(1, c1.compare(other: c2))
    }
    
    func testURLCompareDiffItem() {
        let c1 = RouterURL(url: "test://path?ppp=123/path2?ccc=eee/path3/path4?123=423/path5")
        let c2 = RouterURL(url: "test://path?ppp=123/path2?ccc=eee/path3?k1=v1/path4?123=423/path5")
        
        XCTAssertEqual(2, c1.compare(other: c2))
    }
    
    func testURLCompareEqualAll() {
        let c1 = RouterURL(url: "test://path?ppp=123/path2?ccc=eee/path3/path4?123=423/path5")
        let c2 = RouterURL(url: "test://path?ppp=123/path2?ccc=eee/path3")
        
        XCTAssertEqual(3, c1.compare(other: c2))
    }
}

