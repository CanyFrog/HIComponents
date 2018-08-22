//
//  DOCTests.swift
//  HQXMLDocTests
//
//  Created by HonQi on 8/16/18.
//  Copyright © 2018 HonQi Indie. All rights reserved.
//

import XCTest
@testable import HQXMLDoc

class BaseTests: XCTestCase {
    var xmlStr = try! String(contentsOf: URL(fileURLWithPath: Bundle(for: DOCTests.self).path(forResource: "xml-20081126", ofType: "xml")!))
    var htmlStr = try! String(contentsOf: URL(fileURLWithPath: Bundle(for: DOCTests.self).path(forResource: "w3", ofType: "html")!))
}

class DOCTests: BaseTests {
    
    func testDOCInitWithXML() {
        let xmlDoc = try? DOC(xml: xmlStr, encoding: .utf8)
        
        XCTAssertNotNil(xmlDoc)
        XCTAssertNotNil(xmlDoc?.rootNode)
        XCTAssertEqual(xmlDoc?.version, "1.0")
        XCTAssertEqual(xmlDoc?.encoding, String.Encoding.utf8)
    }
    
    func testDOCInitWithHtml() {
        let htmlDoc = try? DOC(html: htmlStr, encoding: .utf8)
        
        XCTAssertNotNil(htmlDoc)
        XCTAssertNotNil(htmlDoc?.rootNode)
    }
}
