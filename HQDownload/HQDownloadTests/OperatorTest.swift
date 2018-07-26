//
//  OperatorTest.swift
//  HQDownloadTests
//
//  Created by HonQi on 7/26/18.
//  Copyright © 2018 HonQi Indie. All rights reserved.
//

import XCTest
@testable import HQDownload

class OperatorTest: DownloadTest {
    func testOperatorStart() {
        let oper = Operator([.sourceUrl(domain)])
        oper.start()
        async { (done) in
            oper.subscribe(.start({ (source, file, size) in
                XCTAssertNotNil(source)
                XCTAssertNotNil(file)
                XCTAssertTrue(size > 0)
                done()
            }))
        }
    }
}
