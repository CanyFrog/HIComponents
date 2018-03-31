//
//  HQDownloadTests.swift
//  HQDownloadTests
//
//  Created by qihuang on 2018/3/26.
//  Copyright © 2018年 com.personal.HQ. All rights reserved.
//

import XCTest
@testable import HQDownload

class HQDownloadOperationTest: XCTestCase {

    func testOperation() {
        let operation = HQDownloadOperation(request: URLRequest(url: URL(string: "https://www.apple.com/")!), options: [], session: nil)
        operation.start()
        XCTAssertNotNil(operation.request)
        XCTAssertNotNil(operation.dataTask)
        XCTAssertTrue(operation.callbackLists.isEmpty)
        XCTAssertNotNil(operation.sessionConfig)
        XCTAssertTrue(operation.options.isEmpty)
    }
    
    func testOperationAddCallbacks() {
        let operation = HQDownloadOperation(request: URLRequest(url: URL(string: "https://www.apple.com/")!), options: [], session: nil)
        operation.start()
        
        // if not callback closure, did not add callback to operation
        XCTAssertNil(operation.addCallback(progress: nil, completed: nil))
        
        let cb1 = HQDownloadCallback(url: nil, operation: nil, progress: nil) { (_) in }
        operation.addCallback(cb1)
        XCTAssertEqual(cb1.url, operation.request.url)
        XCTAssertEqual(cb1.operation, operation)
        XCTAssertEqual(operation.callbackLists.count, 1)
        
        operation.addCallback(cb1)
        XCTAssertEqual(operation.callbackLists.count, 1)
        
        let cb2 = operation.addCallback(progress: nil) { (_) in }
        XCTAssertNotNil(cb2)
        XCTAssertEqual(operation.callbackLists.count, 2)
        
        operation.addCallbacks([cb1, cb2!])
        XCTAssertEqual(operation.callbackLists.count, 2)
        
        let cb3 = HQDownloadCallback(url: nil, operation: nil, progress: nil) { (_) in }
        operation.addCallbacks([cb3])
        XCTAssertEqual(operation.callbackLists.count, 3)
        
        cb3.cancel()
        XCTAssertEqual(operation.callbackLists.count, 2)
    
        operation.cancel(cb1)
        XCTAssertEqual(operation.callbackLists.count, 1)
        
    }
    
    func testOperationCallback() {
        let exception = XCTestExpectation(description: "Invoke callback when task start or finished")
        let operation = HQDownloadOperation(request: URLRequest(url: URL(string: "https://www.apple.com/")!), options: [], session: nil)
        let _ = operation.addCallback(progress: { (_, _, _, url) in
            XCTAssertEqual(url, operation.request.url)
            exception.fulfill()
        }) { (_) in
            exception.fulfill()
        }
        operation.start()
    }
}


class HQDownloadSchedulerTest: XCTestCase {
    func testScheduler() {
        let scheduler = HQDownloadScheduler.scheduler
    
        let oldSeession = scheduler.sessionConfig
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForResource = 99
        scheduler.changeSession(config: config)
        XCTAssertNotNil(scheduler.sessionConfig)
        XCTAssertNotEqual(scheduler.sessionConfig, oldSeession)
        
        scheduler.setHeader(value: "test1", field: "field")
        XCTAssertEqual("test1", scheduler.getHeader(field: "field"))
        scheduler.setHeader(value: nil, field: "field")
        XCTAssertNil(scheduler.getHeader(field: "field"))
        
        scheduler.setHeader(value: "test2", field: "field2")
        
        
        scheduler.headersFilter = { (url, headers) in
            var h = headers!
            XCTAssertEqual("test2", h.removeValue(forKey: "field2"))
            return h
        }
        
        let url = URL(string: "https://www.apple.com/")!
        let cb1 = scheduler.download(url: url, options: [], progress: nil) { (_) in }
        XCTAssertNotNil(cb1?.operation)
        XCTAssertEqual(cb1?.url, url)
    }
    
    
    func testSchedulerAddOperation() {
        let scheduler = HQDownloadScheduler(sessionConfig: URLSessionConfiguration.default)
        let url = URL(string: "https://www.apple.com/test0")!
        let cb1 = scheduler.download(url: url, options: [], progress: nil) { (_) in }
        
        let url2 = URL(string: "https://www.apple.com/test1")!
        scheduler.download(url: url2, options: [])
        XCTAssertEqual(scheduler.operationsDict.count, 2)
        
        let url3 = URL(string: "https://www.apple.com/test2")!
        let op1 = HQDownloadOperation(request: URLRequest(url: url3), options: [], session: nil)
        scheduler.addCustomOperation(url: url3, operation: op1)
        XCTAssertEqual(scheduler.operationsDict.count, 3)
        XCTAssertEqual(scheduler.operationsDict[url3], op1)
        XCTAssertEqual(scheduler.currentDownloaders, scheduler.operationsDict.count)
        
        scheduler.cancel(cb1!)
        XCTAssertEqual(scheduler.operationsDict.count, 2)
        
        let op2 = HQDownloadOperation(request: URLRequest(url: url3), options: [], session: nil)
        op2.addCallback(cb1!)
        scheduler.addCustomOperation(url: url3, operation: op2)
        XCTAssertEqual(scheduler.operationsDict.count, 2)
        
        scheduler.cancelAllDownloaders()
        XCTAssertEqual(scheduler.operationsDict.count, 0)
        scheduler.invalidateAndCancelSession(cancelPendingOperations: true)
    }
}
