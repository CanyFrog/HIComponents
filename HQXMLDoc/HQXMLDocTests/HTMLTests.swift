//
//  HTMLTests.swift
//  HQXMLDocTests
//
//  Created by HonQi on 8/16/18.
//  Copyright © 2018 HonQi Indie. All rights reserved.
//

import XCTest
@testable import HQXMLDoc

class HTMLTests: XCTestCase {
    
    var xmlDoc: XMLDocument?
    
    override func setUp() {
        super.setUp()
        
        let file = Bundle(for: HTMLTests.self).path(forResource: "w3", ofType: "html")
        XCTAssertNotNil(file)
        
        xmlDoc = try! XMLDocument(html: Data(contentsOf: URL(fileURLWithPath: file!)))
        XCTAssertNotNil(xmlDoc)
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    
    func testRootNode() {
        XCTAssertEqual(xmlDoc?.rootNode.name, "html")
    }
    
    func testNodeChildren() {
        let children = xmlDoc?.rootNode.children
        XCTAssertNotNil(children)
        XCTAssertEqual(children?.count, 2)
        XCTAssertEqual(children?.first?.name, "head")
        XCTAssertEqual(children?.last?.name, "body")
    }
    
    func testTitleXPath() {
        let titles = xmlDoc?.xpath("//head/title")
        XCTAssertEqual(titles?.count, 1)
        XCTAssertEqual(titles?.first?.content, "World Wide Web Consortium (W3C)")
    }
}

