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
    var defaultOperation: HQDownloadOperation!
    
    override func setUp() {
        super.setUp()
        defaultOperation = HQDownloadOperation(HQDownloadRequest(domain, testDirectory))
    }
    
    override func tearDown() {
        super.tearDown()
        defaultOperation = nil
    }
    
    func testOperationInitProperities() {

        defaultOperation.start()
        
        XCTAssertNotNil(defaultOperation.ownRequest)
        XCTAssertNotNil(defaultOperation.sessionConfig)
        XCTAssertNotNil(defaultOperation.dataTask)
        XCTAssertNotNil(defaultOperation.progress)
    }
    
    func testOperationBeginCallback() {
        async { (done) in
            defaultOperation.begin { [unowned self] (source, file, size) in
                XCTAssertEqual(source, self.defaultOperation.ownRequest.request.url)
                XCTAssertEqual(file, self.defaultOperation.ownRequest.fileUrl)
                XCTAssertGreaterThan(size, 0)
                XCTAssertNotNil(self.defaultOperation.response)
                done()
            }.start()
        }
    }
    
//    func testOperationProperties() {
//        // Given
//        let request = HQDownloadRequest(domain)
//        let operation = HQDownloadOperation(request: request, targetPath: randomTargetPath())
//
//        // Then
//        operation.start()
//
//        // When
//        XCTAssertNotNil(operation.sessionConfig)
//        XCTAssertNotNil(operation.dataTask)
//        XCTAssertNotNil(operation.progress)
//        XCTAssertNil(operation.response)
//    }
//
//    func testOperationBasicAuthentication() {
//        clearHttpCredentialsAndCookie()
//        let role = "admin"
//        let pass = "passwork"
//
//        let link = domain.appendingPathComponent("basic-auth/\(role)/\(pass)")
//        var request = HQDownloadRequest(link)
//        request.userPassAuth = (role, pass)
//        let operation = HQDownloadOperation(request: request, targetPath: randomTargetPath())
//        operation.start()
//
//        async { (done) in
//            let _ = operation.addCallback({ (_, _, path, error, finished) in
//                if finished {
//                    XCTAssertNil(error)
//                    do {
//                        let response = try Data(contentsOf: path)
//                        let dict = try JSONSerialization.jsonObject(with: response, options: JSONSerialization.ReadingOptions.init(rawValue: 0)) as? [String: Any]
//
//                        XCTAssertTrue(dict!["authenticated"] as! Bool)
//                        XCTAssertEqual(role, dict!["user"] as? String)
//                    }
//                    catch {
//                        XCTFail("Auth failure")
//                    }
//                    done()
//                }
//            })
//        }
//
//    }
//
//    func testOperationDownloadCallback() {
//        let filePath = randomTargetPath()
//        let link = domain.appendingPathComponent("stream/100")
//        let request = HQDownloadRequest(link)
//        let operation = HQDownloadOperation(request: request, targetPath: filePath)
//
//        async { (done) in
//            let _ = operation.addCallback { (url, _, path, err, finished) in
//                if finished {
//                    XCTAssertEqual(url, link)
//                    XCTAssertEqual(path.path, filePath.path)
//                    XCTAssertNil(err)
//                    XCTAssertNotNil(operation.response)
//                    XCTAssertTrue(FileManager.default.fileExists(atPath: filePath.path))
//                    done()
//                }
//            }
//            operation.start()
//        }
//    }
//
//    func testOperationDownloadProgress() {
//        let randomBytes = 4 * 1024 * 1024
//        let filePath = randomTargetPath()
//        let link = domain.appendingPathComponent("bytes/\(randomBytes)")
//        let request = HQDownloadRequest(link)
//        let operation = HQDownloadOperation(request: request, targetPath: filePath)
//
//
//        var prevProgress: Double = 0
//        async(15) { (done) in
//            let _ = operation.addCallback({ (url, progress, path, err, finished) in
//                XCTAssertLessThanOrEqual(prevProgress, progress.fractionCompleted)
//                prevProgress = progress.fractionCompleted
//                if finished {
//                    XCTAssertEqual(1.0, prevProgress)
//                    let attr = try! FileManager.default.attributesOfItem(atPath: filePath.path)
//                    XCTAssertEqual(operation.response?.expectedContentLength, attr[FileAttributeKey.size] as? Int64)
//                    done()
//                }
//            })
//            operation.start()
//        }
//    }
//
//    func testOperationContinueDownload() {
//        let filePath = randomTargetPath()
//        let link = URL(string: "https://upload.wikimedia.org/wikipedia/commons/6/69/NASA-HS201427a-HubbleUltraDeepField2014-20140603.jpg")!
//        var request = HQDownloadRequest(link)
//        let operation1 = HQDownloadOperation(request: request, targetPath: filePath)
//
//        var currentSize: Int64 = 0
//        var totalSize: Int64 = 0
//
//        let exception1Done = self.expectation(description: "Operation 1 done")
//        let _ = operation1.addCallback({ (_, progress, _, _, _) in
//            if progress.fractionCompleted > 0.2 {
//                currentSize = progress.completedUnitCount
//                totalSize = progress.totalUnitCount
//                operation1.cancel()
//
//                XCTAssertTrue(operation1.isCancelled)
//                exception1Done.fulfill()
//            }
//        })
//        operation1.start()
//        waitForExpectations(timeout: 10, handler: nil)
//
//        // start operation 2
//        request.downloadRange = (currentSize, nil)
//        let operation2 = HQDownloadOperation(request: request, targetPath: filePath)
//        async(20) { (done) in
//            let _ = operation2.addCallback({ (_, progress, _, error, finished) in
//                XCTAssertLessThanOrEqual(currentSize, progress.completedUnitCount)
//                if finished {
//                    XCTAssertNil(error)
//                    XCTAssertEqual(1.0, progress.fractionCompleted)
//                    let attr = try? FileManager.default.attributesOfItem(atPath: filePath.path)
//                    XCTAssertEqual(progress.totalUnitCount, totalSize)
//                    XCTAssertEqual(totalSize, attr?[FileAttributeKey.size] as? Int64)
//                    done()
//                }
//            })
//            operation2.start()
//        }
//    }
}

