////
////  HQDownloadProgressTest.swift
////  HQDownloadTests
////
////  Created by qihuang on 2018/4/14.
////  Copyright © 2018年 com.personal.HQ. All rights reserved.
////
//
//import XCTest
//@testable import HQDownload
//
//class HQdownloadProgress: HQDownloadTest {
//    var defaultProgress: HQDownloadProgress?
//
//    override func setUp() {
//        super.setUp()
//        defaultProgress = HQDownloadProgress()
//    }
//
//    override func tearDown() {
//        super.tearDown()
//        defaultProgress = nil
//    }
//
//    func testProgressFractionCompleted() {
//        defaultProgress?.start(100)
//        
//        var fraction: Double = 0
//        for i in 1...10 {
//            defaultProgress?.progress(Int64(i * 10))
//            XCTAssertLessThanOrEqual(fraction, defaultProgress!.fractionCompleted)
//            fraction = defaultProgress!.fractionCompleted
//        }
//    }
//    func testProgressStartHandler() {
//        let total: Int64 = 1024
//        async { (done) in
//            // call back1
//            defaultProgress?.started({ (t) in
//                XCTAssertEqual(total, t)
//                done()
//            })
//            // call back 2
//            defaultProgress?.started({ (t) in
//                XCTAssertEqual(total, t)
//                done()
//            })
//            
//            defaultProgress?.start(total)
//        }
//    }
//    
//    
//    func testProgressFinishHandler() {
//        async { (done) in
//            defaultProgress?.finished({ (_, error) in
//                XCTAssertNil(error)
//                done()
//            })
//            defaultProgress?.finished({ (_, error) in
//                XCTAssertNil(error)
//                done()
//            })
//            defaultProgress?.finish()
//        }
//    }
//    
//    func testProgressFinishHandlerWithError() {
//        async { (done) in
//            defaultProgress?.finished({ (_, error) in
//                XCTAssertNotNil(error)
//                done()
//            })
//            defaultProgress?.finished({ (_, error) in
//                XCTAssertNotNil(error)
//                done()
//            })
//            
//            defaultProgress?.finish(HQDownloadProgress.HQDownloadError.notEnoughSpace)
//        }
//    }
//    
//    func testProgressFinishHandlerWithCancel() {
//        var progress: HQDownloadProgress? = HQDownloadProgress(source: domain, file: testDirectory)
//        progress?.start(100)
//        async { (done) in
//            progress?.finished({ (_, error) in
//                XCTAssertNotNil(error)
//                done()
//            })
//            progress = nil
//        }
//    }
//
//
//    func testProgressProgressHandler() {
//        let total: Int64 = 100
//        defaultProgress?.start(100)
//        
//        async { (done) in
//            defaultProgress?.progress({ (complete, fraction) in
//                XCTAssertLessThanOrEqual(complete, total)
//                XCTAssertLessThanOrEqual(fraction, 1)
//                if fraction == 1 { done() }
//            })
//            
//            defaultProgress?.progress({ (complete, fraction) in
//                XCTAssertLessThanOrEqual(complete, total)
//                XCTAssertLessThanOrEqual(fraction, 1)
//                if fraction == 1 { done() }
//            })
//            
//            for _ in 0..<10 {
//                defaultProgress?.progress(10)
//            }
//        }
//    }
//    
//    func testProgressAddChildStart() {
//        let unitCount: Int64 = 50
//
//        let progress1 = HQDownloadProgress()
//        let progress2 = HQDownloadProgress()
//
//        defaultProgress?.addChild(progress1)
//        defaultProgress?.addChild(progress2)
//
//        async { (done) in
//            progress1.started({ (total) in
//                XCTAssertEqual(self.defaultProgress?.totalUnitCount, total)
//                done()
//            })
//            progress1.start(unitCount)
//        }
//        
//        async { (done) in
//            progress2.started({ (total) in
//                XCTAssertEqual(self.defaultProgress?.totalUnitCount, total+progress1.totalUnitCount)
//                done()
//            })
//            progress2.start(unitCount)
//        }
//    }
//    
//    func testProgressAddChildFinish() {
//        let unitCount: Int64 = 50
//        
//        let progress1 = HQDownloadProgress()
//        let progress2 = HQDownloadProgress()
//        
//        defaultProgress?.addChild(progress1)
//        defaultProgress?.addChild(progress2)
//        
//        progress1.start(unitCount)
//        progress2.start(unitCount)
//        
//        async { (done) in
//            progress1.finished({ (_, _) in
//                XCTAssertEqual(progress1.fractionCompleted, 1)
//                XCTAssertEqual(self.defaultProgress?.fractionCompleted, 0.5)
//                done()
//            })
//            progress1.progress(unitCount)
//            progress1.finish()
//        }
//        
//        async { (done) in
//            progress2.finished({ (_, _) in
//                XCTAssertEqual(progress1.fractionCompleted, 1)
//                XCTAssertEqual(self.defaultProgress?.fractionCompleted, 1)
//                done()
//            })
//            progress2.progress(unitCount)
//            progress2.finish()
//        }
//    }
//    
//    
//    func testProgressCodable() {
//        defaultProgress?.sourceUrl = domain
//        defaultProgress?.fileUrl = testDirectory
//        defaultProgress?.start(9999)
//        defaultProgress?.progress(1238)
//        
//        let data = try? JSONEncoder().encode(defaultProgress)
//        XCTAssertNotNil(data)
//
//        let codler = try? JSONDecoder().decode(HQDownloadProgress.self, from: data!)
//        XCTAssertNotNil(codler)
//        XCTAssertEqual(codler?.fileUrl, testDirectory)
//        XCTAssertEqual(codler?.sourceUrl, domain)
//        XCTAssertEqual(codler?.completedUnitCount, 1238)
//        XCTAssertEqual(codler?.totalUnitCount, 9999)
//    }
//}
