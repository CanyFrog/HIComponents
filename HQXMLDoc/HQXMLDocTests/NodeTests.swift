//
//  NodeTests.swift
//  HQXMLDocTests
//
//  Created by HonQi on 8/16/18.
//  Copyright © 2018 HonQi Indie. All rights reserved.
//

import XCTest
@testable import HQXMLDoc

class NodeTests: BaseTests {
    func testXML() {
        let html = try? DOC(html: htmlStr)
        XCTAssertNotNil(html?.rootNode)
    }
}

