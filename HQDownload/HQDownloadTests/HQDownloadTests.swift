//
//  HQDownloadTests.swift
//  HQDownloadTests
//
//  Created by qihuang on 2018/3/26.
//  Copyright © 2018年 com.personal.HQ. All rights reserved.
//

import XCTest
@testable import HQDownload

class HQDownloadTests: XCTestCase {
    
    func testOperation() {
        let uri = URL(string: "https://www.apple.com/")
        let request = URLRequest(url: uri!)
        
        let operation = HQDownloadOperation(request: request, options: [], session: nil)
        let callback = operation.addCallback(progress: { (_, _, _, u) in
            XCTAssertEqual(u, uri)
        }) { (error) in
        }
        operation.start()
        
        XCTAssertNotNil(callback)
        XCTAssertEqual(callback?.operation, operation)
        XCTAssertEqual(callback?.url, uri)
        XCTAssertNotNil(operation.request)
        XCTAssertNotNil(operation.dataTask)
        
        
        let callback2 = HQDownloadCallback(url: nil, operation: nil, progress: { (_, _, _, _) in
        }, completed: nil)
        operation.addCallback(callback2)
        XCTAssertEqual(callback2.url, uri)
        XCTAssertEqual(callback2.operation, operation)
        
        callback!.cancel()
        XCTAssertTrue(operation.cancel(callback2))
    }
    
    
    func testScheduler() {
        let uri = URL(string: "https://www.apple.com/")
        
        let scheduler = HQDownloadScheduler.scheduler
        let callback = scheduler.download(url: uri!, options: [], progress: { (_, _, _, u) in
            XCTAssertEqual(u, uri)
        }, completed: nil)
        XCTAssertNotNil(callback?.operation)
        XCTAssertEqual(callback?.url, uri)
        
        
        let callback2 = HQDownloadCallback(url: nil, operation: nil, progress: { (_, _, _, _) in
        }, completed: nil)
        scheduler.addCallback(url: uri!, callback: callback2)
        XCTAssertEqual(callback2.url, uri)
        XCTAssertEqual(callback2.operation, callback?.operation)
        
        
        let uri2 = URL(string: "https://www.apple.com/query")
        let operation2 = HQDownloadOperation(request: URLRequest(url: uri2!), options: [], session: nil)
        scheduler.addCustomOperation(url: uri2!, operation: operation2)
        XCTAssertEqual(scheduler.currentDownloaders, 2)
        
        let callback3 = scheduler.addCallback(url: uri2!, progress: { (_, _, _, _) in }, completed: nil)
        XCTAssertNotNil(callback3)
        
        scheduler.setHeader(value: "header", field: "test")
        XCTAssertEqual(scheduler.getHeader(field: "test"), "header")
        scheduler.setHeader(value: nil, field: "test")
        XCTAssertNil(scheduler.getHeader(field: "test"))
        
        
        XCTAssertNotNil(scheduler.sessionConfig)
        let newConfig = URLSessionConfiguration.default
        newConfig.timeoutIntervalForRequest = 33
        scheduler.changeSession(config: newConfig)
        XCTAssertEqual(scheduler.sessionConfig, newConfig)
        // change session remove all downloaders
        XCTAssertNotEqual(scheduler.currentDownloaders, 0)
    }
}
