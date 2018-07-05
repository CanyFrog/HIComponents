////
////  HQDownloaderTest.swift
////  HQDownloadTests
////
////  Created by Magee Huang on 4/10/18.
////  Copyright © 2018 com.personal.HQ. All rights reserved.
////
//
//import XCTest
//@testable import HQDownload
//
//class HQDownloaderTest: HQDownloadTest {
//    var defaultOperation: HQDownloader {
//        return HQDownloadOperation(HQDownloadRequest(domain, randomTargetPath()))
//    }
//    
//    func testOperationInitProperities() {
//        let operation = defaultOperation
//        
//        XCTAssertTrue(operation.isReady)
//        XCTAssertFalse(operation.isExecuting)
//        XCTAssertFalse(operation.isFinished)
//        XCTAssertFalse(operation.isCancelled)
//        
//        operation.start()
//        XCTAssertTrue(operation.isExecuting)
//        XCTAssertNotNil(operation.ownRequest)
//        XCTAssertNotNil(operation.sessionConfig)
//        XCTAssertNotNil(operation.dataTask)
//        XCTAssertNotNil(operation.progress)
//    }
//    
//    func testOperationBeginCallback() {
//        let operation = defaultOperation
//        
//        async { (done) in
//            operation.started({ (size) in
//                XCTAssertTrue(operation.isExecuting)
//                XCTAssertEqual(size, operation.progress.totalUnitCount)
//                done()
//            }).start()
//        }
//    }
//
//    func testOperationFinishedCallback() {
//        let operation = defaultOperation
//        async { (done) in
//            operation.finished({ (_, err) in
//                let isExist = FileManager.default.fileExists(atPath: operation.progress.fileUrl!.path)
//                XCTAssertTrue(isExist)
//                XCTAssertEqual(1, operation.progress.fractionCompleted)
//                done()
//            }).start()
//        }
//    }
//
//    func testOperationProgressCallback() {
//        let operation = HQDownloadOperation(HQDownloadRequest(domain.appendingPathComponent("stream/101"), randomTargetPath()))
//        async { (done) in
//            let prog = operation.progress
//            operation.progress({ (com, frac) in
//                XCTAssertNotNil(prog?.sourceUrl)
//                XCTAssertNotNil(prog?.fileUrl)
//                XCTAssertLessThanOrEqual(prog!.fractionCompleted, frac)
//                done()
//            }).start()
//        }
//    }
//
//    func testOperationCancel() {
//        let operation = HQDownloadOperation(HQDownloadRequest(domain.appendingPathComponent("stream/102"), randomTargetPath()))
//        async { (done) in
//            operation.finished({ (_, error) in
//                if let err = error, case HQDownloadProgress.HQDownloadError.taskCancel = err {
//                    done()
//                }
//            }).start()
//            operation.cancel()
//        }
//    }
//
//
//    func testOpertaionProgressFinished() {
//        let operation = HQDownloadOperation(HQDownloadRequest(domain.appendingPathComponent("bytes/\(4*1024)"), randomTargetPath()))
//        async { (done) in
//            operation.finished({ (url, err) in
//                XCTAssertNotNil(operation.progress.sourceUrl)
//                XCTAssertNotNil(operation.progress.fileUrl)
//                XCTAssertEqual(1, operation.progress.fractionCompleted)
//                let attr = try! FileManager.default.attributesOfItem(atPath: url!.path)
//                XCTAssertEqual(operation.progress.totalUnitCount, attr[FileAttributeKey.size] as? Int64)
//                done()
//            }).start()
//        }
//    }
//
//    func testOpertionContinueDownload() {
//        let link = URL(string: "https://upload.wikimedia.org/wikipedia/commons/6/69/NASA-HS201427a-HubbleUltraDeepField2014-20140603.jpg")!
//        let operation = HQDownloadOperation(HQDownloadRequest(link, randomTargetPath()))
//        async { (done) in
//            operation.progress({ (_, frac) in
//                if frac > 0.3 {
//                    operation.cancel()
//                    done()
//                }
//            }).start()
//        }
//
//        async { (done) in
//            let operation2 = HQDownloadOperation(HQDownloadRequest(operation.progress)!)
//            operation2.finished({ (url, err) in
//                let attr = try! FileManager.default.attributesOfItem(atPath: url!.path)
//                XCTAssertEqual(operation.progress.totalUnitCount, attr[FileAttributeKey.size] as? Int64)
//                done()
//            }).start()
//        }
//    }
//
//    func testOperationBackgroundDownload() {
//
//    }
//
//    func testOperationAutoRetry() {
//
//    }
//}
//
