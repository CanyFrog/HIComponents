//
//  HQDownloadTests.swift
//  HQDownloadTests
//
//  Created by qihuang on 2018/3/26.
//  Copyright © 2018年 com.personal.HQ. All rights reserved.
//

import XCTest
@testable import HQDownload

class HQDownloadTest: XCTestCase {
    let domain: URL = URL(string: "https://httpbin.org")!
    let timeout: TimeInterval  = 15.0
    var testDirectory: URL {
        var url = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        url.appendPathComponent("download_test", isDirectory: true)
        return url
    }
    
    override func setUp() {
        super.setUp()
        try? FileManager.default.createDirectory(at: testDirectory, withIntermediateDirectories: true, attributes: nil)
    }
    
    override func tearDown() {
        super.tearDown()
        try? FileManager.default.removeItem(at: testDirectory)
    }
    
    func randomTargetPath() -> String {
        return testDirectory.appendingPathComponent("\(UUID().uuidString).json").path
    }
    
    func async(_ timeout: TimeInterval = 5, _ execute: (@escaping ()->Void) -> Void) {
        let exception = self.expectation(description: "Excetation async task executed")
        execute({exception.fulfill()})
        waitForExpectations(timeout: timeout, handler: nil)
    }

}
