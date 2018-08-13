//
//  DownloadTests.swift
//  DownloadTests
//
//  Created by HonQi on 2018/3/26.
//  Copyright © 2018年 HonQi Indie. All rights reserved.
//

import XCTest
@testable import HQDownload

class DownloadTest: XCTestCase {
    let domain: URL = URL(string: "https://httpbin.org")!
    let testDirectory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
    
    func randomTargetPath() -> URL {
        return testDirectory.appendingPathComponent("\(UUID().uuidString).json")
    }
    
    override func tearDown() {
        super.tearDown()
        try? FileManager.default.removeItem(at: testDirectory)
    }
    
    func async(_ timeout: TimeInterval = 15, _ execute: (@escaping ()->Void) -> Void) {
        var exception: XCTestExpectation? = self.expectation(description: "Excetation async task executed")
        execute({
            exception?.fulfill()
            exception = nil
        })
        waitForExpectations(timeout: timeout, handler: nil)
    }
    
    func clearHttpCredentialsCookieCache() {
        // Clear out credentials
        let credentialStorage = URLCredentialStorage.shared
        
        for (protectionSpace, credentials) in credentialStorage.allCredentials {
            for (_, credential) in credentials {
                credentialStorage.remove(credential, for: protectionSpace)
            }
        }
        
        // Clear out cookies
        let cookieStorage = HTTPCookieStorage.shared
        cookieStorage.cookies?.forEach { cookieStorage.deleteCookie($0) }
        
        // Clear cache
        URLCache.shared.removeAllCachedResponses()
    }
}

class URLRequestTest: DownloadTest {
    
    func testCreateWithUrl() {
        let requestNil = URLRequest.hq.create([])
        XCTAssertNil(requestNil)
        
        let request = URLRequest.hq.create([.sourceUrl(domain)])
        XCTAssertNotNil(request)
    }
    
    func testCreateWithRange() {
        let start: Int64 = 432
        let end: Int64 = 1234
        let request = URLRequest.hq.create([.sourceUrl(domain), .exceptedCount(end), .completedCount(start)])
        XCTAssertEqual("bytes=\(start)-\(end)", request?.value(forHTTPHeaderField: "Range"))
    }
    
    func testCreateWithRangeStart() {
        let start: Int64 = 432
        let request = URLRequest.hq.create([.sourceUrl(domain), .completedCount(start)])
        XCTAssertEqual("bytes=\(start)-", request?.value(forHTTPHeaderField: "Range"))
    }
    
    func testCreateWithRangeEnd() {
        let end: Int64 = 1234
        let request = URLRequest.hq.create([.sourceUrl(domain), .exceptedCount(end)])
        XCTAssertEqual("bytes=0-\(end)", request?.value(forHTTPHeaderField: "Range"))
    }
}

