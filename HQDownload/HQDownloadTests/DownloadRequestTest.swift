////
////  DownloadRequestTest.swift
////  DownloadTests
////
////  Created by HonQi on 4/10/18.
////  Copyright © 2018 HonQi Indie. All rights reserved.
////
//
//import XCTest
//@testable import HQDownload
//
//class HQDownloadRequestTest: HQDownloadTest {
//    var defaultRequest: HQDownloadRequest!
//    
//    override func setUp() {
//        super.setUp()
//        defaultRequest = HQDownloadRequest(domain, randomTargetPath())
//    }
//    
//    override func tearDown() {
//        super.tearDown()
//    }
//    
//    func testRequestInitWithUrl() {
//        let request = HQDownloadRequest(domain, testDirectory)
//        
//        // Check request and file url
//        XCTAssertNotNil(request.request)
//        XCTAssertNotNil(request.fileUrl)
//    }
//    
//    func testRequestInitWithMethod() {
//        let request = HQDownloadRequest(domain, nil, .head)
//        XCTAssertEqual(request.request.httpMethod, HQDownloadRequest.Method.head.rawValue)
//    }
//    
//    func testRequestInitWithProgressNoCompletedSource() {
//        let progress = HQDownloadProgress()
//        progress.start(100)
//        progress.progress(10)
//        XCTAssertNil(HQDownloadRequest(progress))
//
//        progress.sourceUrl = domain
//        XCTAssertNil(HQDownloadRequest(progress))
//
//        progress.fileUrl = testDirectory.appendingPathComponent("test_request")
//        let request = HQDownloadRequest(progress)
//        XCTAssertNotNil(request)
//        
//        XCTAssertEqual(request?.requestRange?.0, progress.completedUnitCount)
//        XCTAssertEqual(request?.requestRange?.1, progress.totalUnitCount)
//    }
//    
//    func testRequestGetFileName() {
//        let fileName = "test.mp4"
//        let request = HQDownloadRequest(domain.appendingPathComponent(fileName), testDirectory)
//        XCTAssertEqual(fileName, request.fileName)
//    }
//
//    func testRequestSetGetTimeout() {
//        defaultRequest.requestTimeout = 30.0
//        XCTAssertEqual(30.0, defaultRequest.request.timeoutInterval)
//    }
//
//    func testRequestSetGetHeader() {
//        defaultRequest.headers(["testK": "testV1"])
//        XCTAssertEqual(1, defaultRequest.request.allHTTPHeaderFields?.count)
//        XCTAssertEqual("testV1", defaultRequest.value(forHTTPHeaderField: "testK"))
//
//        defaultRequest.headers(["testK": "testV2"])
//        XCTAssertEqual("testV2", defaultRequest.value(forHTTPHeaderField: "testK"))
//
//        defaultRequest.headers(["testK": nil])
//        XCTAssertNil(defaultRequest.value(forHTTPHeaderField: "testK"))
//        XCTAssertEqual(0, defaultRequest.request.allHTTPHeaderFields?.count)
//    }
//
//    func testRequestSetDownloadRange() {
//        var range: (Int64?, Int64?)? = (1234, 5678)
//        defaultRequest.requestRange(range)
//
//        XCTAssertEqual("bytes=\(range!.0!)-\(range!.1!)", defaultRequest.value(forHTTPHeaderField: "Range"))
//
//        defaultRequest.requestRange(nil)
//        XCTAssertNil(defaultRequest.value(forHTTPHeaderField: "Range")) // remove range
//
//        range?.1 = nil
//        defaultRequest.requestRange(range)
//        XCTAssertEqual("bytes=\(range!.0!)-", defaultRequest.value(forHTTPHeaderField: "Range"))
//
//        defaultRequest.requestRange(nil)
//
//        range = (nil, 5678)
//        defaultRequest.requestRange(range)
//        XCTAssertEqual("bytes=0-\(range!.1!)", defaultRequest.value(forHTTPHeaderField: "Range"))
//    }
//
//    func testRequestAuthCredentialByUserPass() {
//        clearHttpCredentialsCookieCache()
//
//        let user = "admin"
//        let pass = "password"
//        let source = domain.appendingPathComponent("basic-auth/\(user)/\(pass)")
//        let path = testDirectory.appendingPathComponent("auth.json")
//
//        var request = HQDownloadRequest(source, path)
//        request.userPassAuth = (user, pass)
//        XCTAssertNotNil(request.urlCredential)
//
//        async { (done) in
//            HQDownloadOperation(request).finished { (_, err) in
//                defer { done() }
//                XCTAssertNil(err)
//                do {
//                    let response = try Data(contentsOf: path)
//                    let dict = try JSONSerialization.jsonObject(with: response, options: JSONSerialization.ReadingOptions.init(rawValue: 0)) as? [String: Any]
//
//                    XCTAssertTrue(dict!["authenticated"] as! Bool)
//                    XCTAssertEqual(user, dict!["user"] as? String)
//                }
//                catch {
//                    XCTFail("Auth failure")
//                }
//            }.start()
//        }
//        
//    }
//    
//    func testRequestRetryCount() {
//        
//    }
//    
//    func testRequestBackground() {
//        
//    }
//    
//    func testRequestAllowSSLCert() {
//        
//    }
//    
//    func testRequestUseUrlCache() {
//        clearHttpCredentialsCookieCache()
//        defaultRequest.useUrlCache = true
//        async { (done) in
//            HQDownloadOperation(defaultRequest).finished { (_, err) in
//                XCTAssertNil(err)
//                // use url cache
//                XCTAssertNotNil(URLCache.shared.cachedResponse(for: self.defaultRequest.request)?.data)
//                done()
//            }.start()
//        }
//
////        clearHttpCredentialsCookieCache()
////        defaultRequest.useUrlCache = false
////        async { (done) in
////            HQDownloadOperation(defaultRequest).finished { (_, err) in
////                XCTAssertNil(err)
////                // do not use cache
////                XCTAssertNil(URLCache.shared.cachedResponse(for: self.defaultRequest.request)?.data)
////                done()
////            }.start()
////        }
//    }
//
//    func testRequestHandleCookie() {
//        clearHttpCredentialsCookieCache()
//        defaultRequest.handleCookies = false // do not use cookie
//        async { (done) in
//            HQDownloadOperation(defaultRequest).finished { (_, err) in
//                XCTAssertNil(err)
//                XCTAssertTrue(HTTPCookieStorage.shared.cookies(for: self.defaultRequest.request.url!)!.isEmpty)
//                done()
//            }.start()
//        }
//    }
//}
