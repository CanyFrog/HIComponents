//
//  HQDownloadOperationTest.swift
//  HQDownloadTests
//
//  Created by Magee Huang on 4/10/18.
//  Copyright © 2018 com.personal.HQ. All rights reserved.
//

import XCTest
@testable import HQDownload

class HQDownloadOperationTest: HQDownloadTest {
    var defaultOperation: HQDownloadOperation {
        return HQDownloadOperation(HQDownloadRequest(domain, testDirectory))
    }
    
    func testOperationInitProperities() {
        let operation = defaultOperation
        
        XCTAssertTrue(operation.isReady)
        XCTAssertFalse(operation.isExecuting)
        XCTAssertFalse(operation.isFinished)
        XCTAssertFalse(operation.isCancelled)
        
        operation.start()
        XCTAssertTrue(operation.isExecuting)
        XCTAssertNotNil(operation.ownRequest)
        XCTAssertNotNil(operation.sessionConfig)
        XCTAssertNotNil(operation.dataTask)
        XCTAssertNotNil(operation.progress)
    }
    
    func testOperationBeginCallback() {
        let operation = defaultOperation
        
        async { (done) in
            operation.begin { [unowned operation] (source, file, size) in
                XCTAssertTrue(operation.isExecuting)
                XCTAssertEqual(source, operation.ownRequest.request.url)
                XCTAssertEqual(file, operation.ownRequest.fileUrl)
                XCTAssertGreaterThan(size, 0)
                XCTAssertNotNil(operation.response)
                done()
            }.start()
        }
    }
    
    func testOperationFinishedCallback() {
        let operation = defaultOperation
        
        async { (done) in
            operation.finished({ (err) in
                XCTAssertTrue(operation.isFinished)
                done()
            }).start()
        }
    }
    
    func testOperationProgressStart() {
        let operation = HQDownloadOperation(HQDownloadRequest(domain.appendingPathComponent("stream/101"), randomTargetPath()))
        operation.start()
        async { (done) in
            operation.progress.startHandler = { [unowned operation] in
                XCTAssertNotNil(operation.progress.sourceURL)
                XCTAssertNotNil(operation.progress.fileURL)
                XCTAssertLessThan(operation.progress.fractionCompleted, 1)
                done()
            }
        }
    }
    
    func testOperationProgressCancel() {
        let operation = HQDownloadOperation(HQDownloadRequest(domain.appendingPathComponent("stream/102"), randomTargetPath()))
        operation.start()
        operation.cancel()
        async { (done) in
            operation.progress.cancellationHandler = {
                XCTAssertTrue(operation.isCancelled)
                XCTAssertNotNil(operation.progress.sourceURL)
                XCTAssertNotNil(operation.progress.fileURL)
                XCTAssertLessThan(operation.progress.fractionCompleted, 1)
                XCTAssertTrue(FileManager.default.fileExists(atPath: operation.progress.fileURL!.path))
                done()
            }
        }
    }
    
    func testOpertaionProgressFinished() {
        let operation = HQDownloadOperation(HQDownloadRequest(domain.appendingPathComponent("bytes/\(4*1024)"), randomTargetPath()))
        operation.start()
        async { (done) in
            operation.progress.finishedHandler = {
                XCTAssertNotNil(operation.progress.sourceURL)
                XCTAssertNotNil(operation.progress.fileURL)
                XCTAssertEqual(1, operation.progress.fractionCompleted)
                let attr = try! FileManager.default.attributesOfItem(atPath: operation.progress.fileURL!.path)
                XCTAssertEqual(operation.progress.totalUnitCount, attr[FileAttributeKey.size] as? Int64)
                done()
            }
        }
    }
    
    func testOperationProgressCallback() {
        let operation = HQDownloadOperation(HQDownloadRequest(domain.appendingPathComponent("bytes/\(5*1024)"), randomTargetPath()))
        operation.start()
        async { (done) in
            var size: Int64 = 0
            operation.progress.progressHandler = { (completed) in
                XCTAssertNotNil(operation.progress.sourceURL)
                XCTAssertNotNil(operation.progress.fileURL)
                XCTAssertLessThanOrEqual(size, completed)
                size = completed
                if operation.progress.fractionCompleted == 1.0 {
                    done()
                }
            }
        }
    }

    
    func testOpertionContinueDownload() {
        let link = URL(string: "https://upload.wikimedia.org/wikipedia/commons/6/69/NASA-HS201427a-HubbleUltraDeepField2014-20140603.jpg")!
        let operation = HQDownloadOperation(HQDownloadRequest(link, randomTargetPath()))
        operation.start()
        async { (done) in
            operation.progress.progressHandler = { (_) in
                if operation.progress.fractionCompleted > 0.3 {
                    operation.cancel()
                    done()
                }
            }
        }
    
        async { (done) in
            let operation2 = HQDownloadOperation(HQDownloadRequest(operation.progress)!)
            operation2.finished({ (_) in
                XCTAssertEqual(operation2.progress.totalUnitCount, operation.progress.totalUnitCount)
                let attr = try! FileManager.default.attributesOfItem(atPath: operation.progress.fileURL!.path)
                XCTAssertEqual(operation.progress.totalUnitCount, attr[FileAttributeKey.size] as? Int64)
                done()
            }).start()
        }
    }
    
    func testOperationBackgroundDownload() {
        
    }
    
    func testOperationAutoRetry() {
        
    }
}

