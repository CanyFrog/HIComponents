//
//  HQDownloadRequestTest.swift
//  HQDownloadTests
//
//  Created by Magee Huang on 4/10/18.
//  Copyright © 2018 com.personal.HQ. All rights reserved.
//

import XCTest
@testable import HQDownload

class HQDownloadRequestTest: HQDownloadTest {
    var request: HQDownloadRequest!
    
    override func setUp() {
        super.setUp()
        request = HQDownloadRequest(domain)
    }
    
    override func tearDown() {
        super.tearDown()
        request = nil
    }
    
    func testRequestFileName() {
        let fileName = "test.mp4"
        let url = domain.appendingPathComponent(fileName)
        let req = HQDownloadRequest(url)
        XCTAssertEqual(fileName, req.fileName)
    }
    
    func testRequestTimeout() {
        request.downloadTimeout = 30.0
        XCTAssertEqual(30.0, request.request.timeoutInterval)
    }
    
    func testRequestRangeNil() {
        request.downloadRange = nil
        XCTAssertNil(request.value(forHTTPHeaderField: "Range"))
    }
    
    func testRequestRangeStart() {
        request.downloadRange = (1234, nil)
        let range = request.value(forHTTPHeaderField: "Range")
        XCTAssertNotNil(range)
        XCTAssertEqual("bytes=1234-", range)
    }
    
    func testRequestRangeEnd() {
        request.downloadRange = (nil, 1234)
        XCTAssertEqual("bytes=0-1234", request.value(forHTTPHeaderField: "Range"))
    }
    
    func testRequestRangeStartAndEnd() {
        request.downloadRange = (123, 1234)
        XCTAssertEqual("bytes=123-1234", request.value(forHTTPHeaderField: "Range"))
    }

    func testRequestRangeReset() {
        request.downloadRange = (123, 1234)
        XCTAssertEqual("bytes=123-1234", request.value(forHTTPHeaderField: "Range"))
        
        request.downloadRange = nil
        XCTAssertNil(request.value(forHTTPHeaderField: "Range"))
    }
    
    func testRequestUserPassAuth() {
        request.userPassAuth = ("user", "pass")
        XCTAssertNotNil(request.urlCredential)
    }
    
    func testRequestInitHeaders() {
        let headers = [
            "k1": "v1",
            "k2": "v2",
            "k3": "v3"
            ]
        let req = HQDownloadRequest(domain, headers)
        XCTAssertEqual(headers, req.request.allHTTPHeaderFields)
    }
}
