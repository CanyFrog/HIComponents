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
        scheduler = HQDownloadScheduler(.default, "test_scheduler")
    }
    
    override func tearDown() {
        super.tearDown()
        scheduler.invalidateAndCancelSession()
        scheduler = nil
    }
    
    func testShedulerAddDownloaderByLink() {
        scheduler.download(domain.appendingPathComponent("stream/123"))
        scheduler.download(domain.appendingPathComponent("stream/123"))
        scheduler.download(domain.appendingPathComponent("stream/124"))
        scheduler.download(domain.appendingPathComponent("stream/125"))
        XCTAssertEqual(3, scheduler.currentDownloaders)
    }
    
    func testShedulerAddDownloaderByRequest() {
        
        scheduler.download(HQDownloadRequest(domain.appendingPathComponent("stream/123")))
        scheduler.download(HQDownloadRequest(domain.appendingPathComponent("stream/123")))
        scheduler.download(HQDownloadRequest(domain.appendingPathComponent("stream/124")))
        scheduler.download(HQDownloadRequest(domain.appendingPathComponent("stream/125")))
        XCTAssertEqual(3, scheduler.currentDownloaders)
    }
    
    func testShedulerAsyncAddDownloader() {
        let group = DispatchGroup()
        
        group.enter()
        DispatchQueue(label: "test1").async {
            self.scheduler.download(self.domain.appendingPathComponent("stream/125"))
            self.scheduler.download(self.domain.appendingPathComponent("stream/123"))
            self.scheduler.download(self.domain.appendingPathComponent("stream/123"))
            group.leave()
        }
        
        group.enter()
        DispatchQueue(label: "test2").async {
            self.scheduler.download(HQDownloadRequest(self.domain.appendingPathComponent("stream/124")))
            self.scheduler.download(HQDownloadRequest(self.domain.appendingPathComponent("stream/124")))
            self.scheduler.download(HQDownloadRequest(self.domain.appendingPathComponent("stream/125")))
            group.leave()
        }
        
        group.wait()
        XCTAssertEqual(3, scheduler.currentDownloaders)
    }
    
    func testSchedulerDownloaderCallback() {
        async { (done) in
            scheduler.download(domain.appendingPathComponent("stream/100")).addCallback { (url, progress, path, err, finished) in
                if finished {
                    done()
                }
            }
        }
    }
}
