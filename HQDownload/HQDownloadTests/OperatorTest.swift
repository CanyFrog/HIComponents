//
//  OperatorTest.swift
//  HQDownloadTests
//
//  Created by HonQi on 7/26/18.
//  Copyright © 2018 HonQi Indie. All rights reserved.
//

import XCTest
@testable import HQDownload

class OperatorTest: DownloadTest {
    
    func testOperatorStart() {
        let oper = Operator([.sourceUrl(domain)])
        oper.start()
        async { (done) in
            oper.subscribe(.start({ (source, file, size) in
                XCTAssertNotNil(source)
                XCTAssertTrue(size > 0)
                done()
                }),
                .completed({ (_, file) in
                    XCTAssertNotNil(file)
                    done()
                })
            )
        }
    }
    
    func testOperatorRequestError() {
        let url = URL(string: "abc")!
        let oper = Operator([.sourceUrl(url)])
        oper.start()
        async { (done) in
            oper.subscribe(.error({ (_, error) in
                XCTAssertNotNil(error)
                print(error)
                done()
            }))
        }
    }
    
    
    func testOperatorError() {
        let url = domain.appendingPathComponent("/status/400")
        let oper = Operator([.sourceUrl(url)])
        oper.start()
        async { (done) in
            oper.subscribe(.error({ (_, error) in
                XCTAssertNotNil(error)
                print(error)
                done()
            }))
        }
    }
    
    func testOperatorErrorNoCache() {
        let url = domain.appendingPathComponent("/status/304")
        let oper = Operator([.sourceUrl(url)])
        oper.start()
        async { (done) in
            oper.subscribe(.error({ (_, error) in
                XCTAssertNotNil(error)
                print(error)
                done()
            }))
        }
    }
    
    func testOperatorReceiveData() {
        let url = domain.appendingPathComponent("/bytes/\(1024*1024*3)")
        let oper = Operator([.sourceUrl(url)])
        oper.start()
        
        var completed: Int64 = 0
        async { (done) in
            oper.subscribe(
                .data({ (_, data) in
                    XCTAssertNotNil(data)
                    print("receive data")
                }),
                .progress({ (_, pro) in
                    XCTAssertTrue(pro.completedUnitCount > completed)
                    completed = pro.completedUnitCount
                    if pro.totalUnitCount == pro.completedUnitCount {
                        done()
                    }
                }))
        }
    }
    
    
    func testOperatorCompleted() {
        let url = domain.appendingPathComponent("/image/svg")
        let oper = Operator([.sourceUrl(url)])
        oper.start()
        
        async { (done) in
            oper.subscribe(
                .completed({ (_, file) in
                    XCTAssertTrue(FileManager.default.fileExists(atPath: file.path))
                    done()
                })
            )
        }
    }
    
    
    func testOperatorSaveStream() {
        let url = domain.appendingPathComponent("/image/jpeg")
        let dir = testDirectory.appendingPathComponent("test", isDirectory: true)
        let oper = Operator([.sourceUrl(url), .cacheDirectory(dir)])
        oper.start()

        var name: String?
        var size: Int64?
        async { (done) in
            oper.subscribe(
                .start({ (_, n, s) in
                    name = n
                    size = s
                }),
                .completed({ (_, file) in
                    XCTAssertEqual(file, dir.appendingPathComponent(name!))
                    XCTAssertTrue(FileManager.default.fileExists(atPath: file.path))
                    let attr = try? FileManager.default.attributesOfItem(atPath: file.path)
                    XCTAssertNotNil(attr)
                    XCTAssertEqual(size, attr![FileAttributeKey.size] as? Int64)
                    done()
                })
            )
        }
    }
    
    
    func testOperatorAuthWithUserPass() {
        let user = "username"
        let pass = "123456"
        let url = domain.appendingPathComponent("/basic-auth/\(user)/\(pass)")
        let oper = Operator([.sourceUrl(url), .userPassAuth(user, pass)])
        oper.start()
        
        async { (done) in
            oper.subscribe(
                .completed({ (_, _) in
                    done()
                }))
        }
    }
    
    func testOperatorAuthWithCred() {
        let user = "username"
        let pass = "123456"
        let url = domain.appendingPathComponent("/digest-auth/auth/\(user)/\(pass)")
        let oper = Operator([.sourceUrl(url), .urlCredential(URLCredential(user: user, password: pass, persistence: .none))])
        oper.start()
        
        async { (done) in
            oper.subscribe(
                .completed({ (_, _) in
                    done()
                }))
        }
    }
    
    
    func testOperatorRetry() {
        
    }
    
    func testOperatorCancel() {
        let url = domain.appendingPathComponent("/bytes/\(1024*1024*30)")
        let oper = Operator([.sourceUrl(url)])
        oper.start()
        async { (done) in
            oper.subscribe(
                .progress({ (_, pro) in
                    if pro.totalUnitCount >= pro.completedUnitCount/2 {
                        oper.cancel()
                    }
                }),
                .error({ (_, err) in
                    XCTAssertNotNil(err)
                    done()
                })
            )
        }
    }
    
}
