//
//  HQDownloadSchedulerTest.swift
//  HQDownloadTests
//
//  Created by Magee Huang on 4/11/18.
//  Copyright © 2018 com.personal.HQ. All rights reserved.
//

import XCTest
@testable import HQDownload

class HQDownloadSchedulerTest: HQDownloadTest {
    var scheduler: HQDownloadScheduler!
    
    override func setUp() {
        super.setUp()
        scheduler = HQDownloadScheduler(testDirectory)
    }
    
    override func tearDown() {
        super.tearDown()
//        scheduler.invalidateAndCancelSession()
        scheduler.cancelAllDownloaders()
        scheduler = nil
    }
    
    func testSchedulerProperties() {
        XCTAssertNotNil(scheduler.sessionConfig)
        XCTAssertEqual(scheduler.directory, testDirectory)
        XCTAssertEqual(0, scheduler.currentDownloaders)
    }
    
    func testShedulerAddDownloaderByLink() {
        scheduler.download(domain.appendingPathComponent("stream/123"))
        scheduler.download(domain.appendingPathComponent("stream/123"))
        scheduler.download(domain.appendingPathComponent("stream/124"))
        scheduler.download(domain.appendingPathComponent("stream/125"))
        XCTAssertEqual(3, scheduler.currentDownloaders)
    }
    
    func testShedulerAddDownloaderByRequest() {
        scheduler.download(HQDownloadRequest(domain.appendingPathComponent("stream/123"), testDirectory.appendingPathComponent("123")))
        scheduler.download(HQDownloadRequest(domain.appendingPathComponent("stream/123"), testDirectory.appendingPathComponent("456")))
        scheduler.download(HQDownloadRequest(domain.appendingPathComponent("stream/124"), testDirectory.appendingPathComponent("4313")))
        scheduler.download(HQDownloadRequest(domain.appendingPathComponent("stream/125"), testDirectory.appendingPathComponent("afda")))
        XCTAssertEqual(3, scheduler.currentDownloaders)
    }
    
    
    func testSchedulerStart() {
        let op1 = scheduler.download(domain.appendingPathComponent("stream/\(123 * 1024)"))
        XCTAssertTrue(op1.isReady)
        async { (done) in
            op1.progress.started({ (_) in
                XCTAssertTrue(op1.isExecuting)
                done()
            })
        }
    }
    
    func testSchedulerSuspended() {
        let op1 = scheduler.download(domain.appendingPathComponent("stream/\(123 * 1024)"))
        XCTAssertTrue(op1.isReady)
        
        scheduler.suspended()
    
        let op2 = scheduler.download(domain.appendingPathComponent("stream/\(124 * 1024)"))
        XCTAssertFalse(op2.isExecuting) // never be executing
    }
    
    func testSchedulerCancel() {
        scheduler.download(domain.appendingPathComponent("stream/\(123 * 1024)"))
        scheduler.download(domain.appendingPathComponent("stream/\(124 * 1024)"))
        
        scheduler.cancelAllDownloaders()
        XCTAssertEqual(0, scheduler.currentDownloaders)
    }
    
//    func testSchedulerInvalidateAndCancelSession() {
//        scheduler.invalidateAndCancelSession()
//        let op1 = scheduler.download(domain.appendingPathComponent("stream/\(123 * 1024)"))
//
//        let op2 = scheduler.download(domain.appendingPathComponent("stream/\(124 * 1024)"))
//
//        XCTAssertTrue(op1.isCancelled)
//        XCTAssertTrue(op2.isFinished)
//    }
}
