//
//  HQDownloadRequestTest.swift
//  HQDownloadTests
//
//  Created by Magee Huang on 4/10/18.
//  Copyright © 2018 com.personal.HQ. All rights reserved.
//

import XCTest
@testable import HQDownload

class HQDownloadRequestTest: HQDownloadTest {
    var defaultRequest: HQDownloadRequest!
    
    override func setUp() {
        super.setUp()
        defaultRequest = HQDownloadRequest(domain, testDirectory)
    }
    
    override func tearDown() {
        super.tearDown()
        defaultRequest = nil
    }
    
    
    func testRequestInitWithUrl() {
        let request = HQDownloadRequest(domain, testDirectory)
        
        // Check request and file url
        XCTAssertNotNil(request.request)
        XCTAssertNotNil(request.fileUrl)
    }
    
    func testRequestInitWithHeaders() {
        let headers = ["k1":"v1", "k2":"v2"]
        let request = HQDownloadRequest(domain, testDirectory, headers)
        
        XCTAssertEqual(request.request.allHTTPHeaderFields?.count, 2)
        XCTAssertEqual(request.request.allHTTPHeaderFields, headers)
    }
    
    func testRequestInitWithProgressNoCompletedSource() {
        let progress = HQDownloadProgress()
        XCTAssertNil(HQDownloadRequest(progress))
        
        progress.sourceURL = domain
        XCTAssertNil(HQDownloadRequest(progress))
        
        progress.fileURL = testDirectory.appendingPathComponent("test_request")
        XCTAssertNotNil(HQDownloadRequest(progress))
    }
    
    
    func testRequestGetFileName() {
        let fileName = "test.mp4"
        let request = HQDownloadRequest(domain.appendingPathComponent(fileName), testDirectory)
        XCTAssertEqual(fileName, request.fileName)
    }

    func testRequestSetGetTimeout() {
        defaultRequest.downloadTimeout = 30.0
        XCTAssertEqual(30.0, defaultRequest.request.timeoutInterval)
    }

    func testRequestSetGetHeader() {
        defaultRequest.setValue("testV1", forHTTPHeaderField: "testK")
        XCTAssertEqual(1, defaultRequest.request.allHTTPHeaderFields?.count)
        XCTAssertEqual("testV1", defaultRequest.value(forHTTPHeaderField: "testK"))
        
        defaultRequest.setValue("testV2", forHTTPHeaderField: "testK")
        XCTAssertEqual("testV2", defaultRequest.value(forHTTPHeaderField: "testK"))
     
        defaultRequest.setValue(nil, forHTTPHeaderField: "testK")
        XCTAssertNil(defaultRequest.value(forHTTPHeaderField: "testK"))
        XCTAssertEqual(0, defaultRequest.request.allHTTPHeaderFields?.count)
    }
    
    func testRequestAddHeader() {
        defaultRequest.addValue("testV1", forHTTPHeaderField: "testK")
        XCTAssertEqual(1, defaultRequest.request.allHTTPHeaderFields?.count)
        
        defaultRequest.addValue("testV2", forHTTPHeaderField: "testK")
        XCTAssertEqual("testV1,testV2", defaultRequest.value(forHTTPHeaderField: "testK"))
    }
    
    func testRequestSetDownloadRange() {
        var range: (Int64?, Int64?)? = (1234, 5678)
        defaultRequest.downloadRange = range

        XCTAssertEqual("bytes=\(range!.0!)-\(range!.1!)", defaultRequest.value(forHTTPHeaderField: "Range"))
        
        defaultRequest.downloadRange = nil
        XCTAssertNil(defaultRequest.value(forHTTPHeaderField: "Range")) // remove range
        
        range?.1 = nil
        defaultRequest.downloadRange = range
        XCTAssertEqual("bytes=\(range!.0!)-", defaultRequest.value(forHTTPHeaderField: "Range"))
        
        defaultRequest.downloadRange = nil
        
        range = (nil, 5678)
        defaultRequest.downloadRange = range
        XCTAssertEqual("bytes=0-\(range!.1!)", defaultRequest.value(forHTTPHeaderField: "Range"))
        
        defaultRequest.downloadRange = (345,nil)
        XCTAssertEqual("bytes=0-\(range!.1!),bytes=345-", defaultRequest.value(forHTTPHeaderField: "Range"))
    }

    func testRequestAuthCredentialByUserPass() {
        clearHttpCredentialsCookieCache()
        
        let user = "admin"
        let pass = "password"
        let source = domain.appendingPathComponent("basic-auth/\(user)/\(pass)")
        let path = testDirectory.appendingPathComponent("auth.json")
        
        var request = HQDownloadRequest(source, path)
        request.userPassAuth = (user, pass)
        XCTAssertNotNil(request.urlCredential)
        
        async { (done) in
            HQDownloadOperation(request).finished { (err) in
                defer { done() }
                XCTAssertNil(err)
                do {
                    let response = try Data(contentsOf: path)
                    let dict = try JSONSerialization.jsonObject(with: response, options: JSONSerialization.ReadingOptions.init(rawValue: 0)) as? [String: Any]
                    
                    XCTAssertTrue(dict!["authenticated"] as! Bool)
                    XCTAssertEqual(user, dict!["user"] as? String)
                }
                catch {
                    XCTFail("Auth failure")
                }
            }.start()
        }
    }
    
    func testRequestRetryCount() {
        
    }
    
    func testRequestBackground() {
        
    }
    
    func testRequestAllowSSLCert() {
        
    }
    
    func testRequestUseUrlCache() {
        clearHttpCredentialsCookieCache()
//        defaultRequest.useUrlCache = true
//        async { (done) in
//            HQDownloadOperation(defaultRequest).finished { (err) in
//                XCTAssertNil(err)
//                // use url cache
//                XCTAssertNil(URLCache.shared.cachedResponse(for: self.defaultRequest.request)?.data)
//                done()
//            }.start()
//        }
//
//        defaultRequest.useUrlCache = false
//        async { (done) in
//            HQDownloadOperation(defaultRequest).finished { (err) in
//                XCTAssertNil(err)
//                // do not use cache
//                XCTAssertNil(URLCache.shared.cachedResponse(for: self.defaultRequest.request)?.data)
//                done()
//            }.start()
//        }
    }
    
    func testRequestHandleCookie() {
        clearHttpCredentialsCookieCache()
        defaultRequest.handleCookies = false // do not use cookie
        async { (done) in
            HQDownloadOperation(defaultRequest).finished { (err) in
                XCTAssertNil(err)
                XCTAssertTrue(HTTPCookieStorage.shared.cookies(for: self.defaultRequest.request.url!)!.isEmpty)
                done()
            }.start()
        }
    }
}

