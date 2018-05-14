//
//  HQDownloadProgressTest.swift
//  HQDownloadTests
//
//  Created by qihuang on 2018/4/14.
//  Copyright © 2018年 com.personal.HQ. All rights reserved.
//

import XCTest
@testable import HQDownload

class HQdownloadProgress: HQDownloadTest {
    var defaultProgress: HQDownloadProgress?

    override func setUp() {
        super.setUp()
        defaultProgress = HQDownloadProgress()
    }

    override func tearDown() {
        super.tearDown()
        defaultProgress = nil
    }

    func testProgressSetGetSourceUrl() {
        defaultProgress?.sourceURL = domain
        XCTAssertNotNil(defaultProgress?.sourceURL)
    }
    
    func testProgressSetGetFileUrl() {
        defaultProgress?.fileURL = testDirectory
        XCTAssertNotNil(defaultProgress?.fileURL)
    }
    
    func testProgressStartHandler() {
        
        async { (done) in
            defaultProgress?.startHandler = {
                done()
            }
            defaultProgress?.start()
        }
    }
    
    
    func testProgressFinishHandler() {
        async { (done) in
            defaultProgress?.finishedHandler = {
                done()
            }
            defaultProgress?.totalUnitCount = 100
            for i in 0...100 {
                defaultProgress?.completedUnitCount = Int64(i)
            }
        }
    }
    
    func testProgressProgressHandler() {
        async { (done) in
            defaultProgress?.progressHandler = { (size) in
                XCTAssertLessThanOrEqual(size, (self.defaultProgress?.totalUnitCount)!)
                if size == self.defaultProgress?.totalUnitCount {
                    done()
                }
            }
            defaultProgress?.totalUnitCount = 100
            for i in 0...100 {
                defaultProgress?.completedUnitCount = Int64(i)
            }
        }
    }
    
//    func testProgressAddChild() {
//        let unitCount: Int64 = 50
//        defaultProgress?.completedUnitCount = 2 * unitCount
//
//        let progress1 = HQDownloadProgress()
//        progress1.totalUnitCount = unitCount
//        let progress2 = HQDownloadProgress()
//        progress2.totalUnitCount = unitCount
//
//        defaultProgress?.addChild(progress1, withPendingUnitCount: unitCount)
//        defaultProgress?.addChild(progress2, withPendingUnitCount: unitCount)
//
//        async { (done) in
//            progress1.finishedHandler = {
//                XCTAssertEqual(0.5, self.defaultProgress?.fractionCompleted)
//                XCTAssertEqual(1.0, progress1.fractionCompleted)
//                done()
//            }
//            for i in 0...unitCount {
//                progress1.completedUnitCount = i
//            }
//        }
//    }
    
    func testProgressCodable() {
        defaultProgress?.sourceURL = domain
        defaultProgress?.fileURL = testDirectory
        defaultProgress?.completedUnitCount = 1238
        defaultProgress?.totalUnitCount = 9999
        
        let data = try? JSONEncoder().encode(defaultProgress)
        XCTAssertNotNil(data)
        
        let codler = try? JSONDecoder().decode(HQDownloadProgress.self, from: data!)
        XCTAssertNotNil(codler)
        XCTAssertEqual(codler?.fileURL, testDirectory)
        XCTAssertEqual(codler?.sourceURL, domain)
        XCTAssertEqual(codler?.completedUnitCount, 1238)
        XCTAssertEqual(codler?.totalUnitCount, 9999)
    }
}
