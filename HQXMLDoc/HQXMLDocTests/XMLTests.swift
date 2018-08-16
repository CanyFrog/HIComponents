//
//  XMLTests.swift
//  HQXMLDocTests
//
//  Created by HonQi on 8/16/18.
//  Copyright © 2018 HonQi Indie. All rights reserved.
//

import XCTest
@testable import HQXMLDoc

class XMLTests: XCTestCase {
    
    var xmlDoc: XMLDocument?
    
    override func setUp() {
        super.setUp()
        
        let file = Bundle(for: XMLTests.self).path(forResource: "xml-20081126", ofType: "xml")
        XCTAssertNotNil(file)
        
        xmlDoc = try! XMLDocument(xml: Data(contentsOf: URL(fileURLWithPath: file!)))
        XCTAssertNotNil(xmlDoc)
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    func testXMLVersion() {
        XCTAssertEqual(xmlDoc?.version, "1.0")
    }

    func testXMLEncoding() {
        XCTAssertEqual(xmlDoc?.encoding, String.Encoding.utf8)
    }
    
    func testXMLRootElement() {
        XCTAssertEqual(xmlDoc?.rootNode.name, "spec")
        
        XCTAssertEqual(xmlDoc?.rootNode["w3c-doctype"], "rec")
        XCTAssertEqual(xmlDoc?.rootNode["lang"], "en")

    }
    
    func testXMLXPath() {
        let path = "/spec/header/title"
        let nodes = xmlDoc?.xpath(path)
        XCTAssertEqual(nodes?.count, 1)
        XCTAssertEqual(nodes![0].name, "title")
    }
}
