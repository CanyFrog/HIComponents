//
//  HQDiskCacheTest.swift
//  HQCacheTests
//
//  Created by qihuang on 2018/4/5.
//  Copyright © 2018年 com.personal.HQ. All rights reserved.
//

import XCTest
@testable import HQCache


struct DiskTestClass: Codable, Equatable {
    var name: String = "test_name"
    var age: Int = 18
    var email: String = "test_class@email.com"
    var desc: Data?

    init(_ name: String = "test_name", _ age: Int = 18, _ email: String = "test_class@email.com", _ desc: Data? = nil) {
        self.name = name
        self.age = age
        self.email = email
        self.desc = desc
    }

    static func smallCls() -> DiskTestClass {
        return DiskTestClass()
    }
    
    static func bigCls() -> DiskTestClass {
        let data = Data(bytes: Array(repeating: 12, count: 30*1024))
        return DiskTestClass("big", 44, "test_insert_email", data)
    }

    static func createFile(_ name: String) -> URL {
        let cache = "\(NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!)/\(name)"
        let data = Data(bytes: Array(repeating: 123, count: 4*1024*1024))

        try! data.write(to: URL(fileURLWithPath: cache))
        return URL(fileURLWithPath: cache)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.age == rhs.age && lhs.name == rhs.name && lhs.email == rhs.email && lhs.desc == rhs.desc
    }
}


class HQDiskCacheTest: XCTestCase {
    var disk: HQDiskCache!
    let path: URL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("testDir")

    override func setUp() {
        super.setUp()
        disk = HQDiskCache(path)
    }
    override func tearDown() {
        super.tearDown()
        try? FileManager.default.removeItem(at: path)
        disk = nil
    }

    func testDiskExist() {
        disk.insertOrUpdate(object: DiskTestClass(), forKey: "test_exist")
        XCTAssertTrue(disk.exist(forKey: "test_exist"))
    }

    func testDiskExistInBackground() {
        async { (done) in
            disk.insertOrUpdate(object: DiskTestClass(), forKey: "test_exist_background") {
                XCTAssertTrue(self.disk.exist(forKey: "test_exist_background"))
                done()
            }
        }
    }

    func testDiskTotalCount() {
        let count = 10
        insertMultiItems(count)
        XCTAssertEqual(count, disk.getTotalCount())
    }

    func testDiskTotalCountInBackground() {
        let count = 12
        self.insertMultiItems(count)

        async { (done) in
            self.disk.getTotalCount(inBackThread: { (ct) in
                XCTAssertEqual(count, ct)
                done()
            })
        }
    }

    func testDiskTotalCost() {
        let count = 10
        let cost = insertMultiItems(count)
        XCTAssertEqual(cost, disk.getTotalCost())
    }

    func testDiskTotalCostInBackgroun() {
        let count = 15
        let cost = insertMultiItems(count)
        async { (done) in
            self.disk.getTotalCost(inBackThread: { (ct) in
                XCTAssertEqual(cost, ct)
                done()
            })
        }
    }

    func testDiskInsertQuerySmallThanCriticalObj() {
        disk.insertOrUpdate(object: DiskTestClass.smallCls(), forKey: "test_insert_small")
        let result: DiskTestClass? = disk.query(objectForKey: "test_insert_small")
        XCTAssertNotNil(result)
    }

    func testDiskInsertQuerySmallThanCriticalObjInBackground() {
        let obj = DiskTestClass.smallCls()
        disk.insertOrUpdate(object: obj, forKey: "test_insert_small_background")
        async { (done) in
            self.disk.query(objectForKey: "test_insert_small_background", inBackThreadCallback: { (key, value: DiskTestClass?) in
                XCTAssertEqual(obj, value)
                done()
            })
        }
    }

    func testDiskInsertQueryBigThanCriticalObj() {
        disk.insertOrUpdate(object: DiskTestClass.bigCls(), forKey: "test_insert_big")

        let file = try? FileManager.default.contentsOfDirectory(atPath: disk.dataPath.path)
        XCTAssertFalse((file?.isEmpty)!)

        let result: DiskTestClass? = disk.query(objectForKey: "test_insert_big")
        XCTAssertNotNil(result)
    }

    func testDiskInsertQueryBigThanCriticalObjInBackground() {
        let obj = DiskTestClass.bigCls()
        disk.insertOrUpdate(object: obj, forKey: "test_insert_big_background")
        async { (done) in
            self.disk.query(objectForKey: "test_insert_big_background", inBackThreadCallback: { (key, value: DiskTestClass?) in
                let file = try? FileManager.default.contentsOfDirectory(atPath: self.disk.dataPath.path)
                XCTAssertFalse((file?.isEmpty)!)
                XCTAssertTrue(self.disk.exist(forKey: "test_insert_big_background"))
                done()
            })
        }
    }

    func testDiskInsertQueryFile() {
        let mp4 = "insert_file.mp4"
        disk.insertOrUpdate(originFile: DiskTestClass.createFile(mp4), forKey: "insert_file_test")
        let targetFile = disk.query(filePathForKey: "insert_file_test")
        XCTAssertNotNil(targetFile)
        XCTAssertTrue(FileManager.default.fileExists(atPath: targetFile!))
        XCTAssertEqual(mp4, targetFile?.components(separatedBy: "/").last)
    }

    func testDiskInsertQueryFileInBackground() {
        let video = "insert_file_background.avi"
        disk.insertOrUpdate(originFile: DiskTestClass.createFile(video), forKey: "insert_file_test_background")
        async { (done) in
            self.disk.query(filePathForKey: "insert_file_test_background", inBackThreadCallback: { (key, value) in
                XCTAssertNotNil(value!)
                XCTAssertTrue(FileManager.default.fileExists(atPath: value!))
                XCTAssertEqual(video, value?.components(separatedBy: "/").last)
                done()
            })
        }
    }


    func testDiskQuery() {
        let obj = DiskTestClass("test_query", 18, "test_query@emial.com", nil)
        disk.insertOrUpdate(object: obj, forKey: "test_query")
        let query: DiskTestClass? = disk.query(objectForKey: "test_query")
        XCTAssertEqual(obj, query)
    }


    func testDiskQueryInBackground() {
        let obj = DiskTestClass("test_query_background", 22, "test_query_background@emial.com", nil)
        async { (done) in
            disk.insertOrUpdate(object: obj, forKey: "test_query_background", inBackThreadCallback: {
                let query: DiskTestClass? = self.disk.query(objectForKey: "test_query_background")
                XCTAssertEqual(obj, query)
                done()
            })
        }
    }

    func testDiskDeleteKey() {
        disk.insertOrUpdate(object: DiskTestClass.smallCls(), forKey: "test_delete_1")
        disk.insertOrUpdate(object: DiskTestClass.smallCls(), forKey: "test_delete_2")
        disk.delete(objectForKey: "test_delete_2")

        XCTAssertTrue(disk.exist(forKey: "test_delete_1"))
        XCTAssertFalse(disk.exist(forKey: "test_delete_2"))
    }

    func testDiskDeleteKeyInBackground() {
        disk.insertOrUpdate(object: DiskTestClass.smallCls(), forKey: "test_delete_background_1")
        disk.insertOrUpdate(object: DiskTestClass.smallCls(), forKey: "test_delete_background_2")

        async { (done) in
            disk.delete(objectForKey: "test_delete_background_2", inBackThreadCallback: { (k) in
                XCTAssertTrue(self.disk.exist(forKey: "test_delete_background_1"))
                XCTAssertFalse(self.disk.exist(forKey: k))
                done()
            })
        }
    }

    func testDiskDeleteAll() {
        let count = 10
        insertMultiItems(count)
        XCTAssertEqual(count, disk.getTotalCount())
        disk.deleteAllCache()
        XCTAssertEqual(0, disk.getTotalCount())

        // reconnect
        insertMultiItems(2)
        XCTAssertEqual(2, disk.getTotalCount())
    }

    func testDiskDeleteAllInBackground() {
        let count = 10
        insertMultiItems(count)
        XCTAssertEqual(count, disk.getTotalCount())
        async { (done) in
            disk.deleteAllCache {
                XCTAssertEqual(0, self.disk.getTotalCount())
                done()
            }
        }
    }

//    func testDiskDeleteProgress() {
//        insertMultiItems(50)
//        async { (done) in
//            disk.deleteAllCache(withProgressClosure: { (cur, tot, isSuc) in
//                XCTAssertLessThanOrEqual(cur, tot)
//                if isSuc {
//                    XCTAssertEqual(0, self.disk.getTotalCount())
//                    done()
//                }
//            })
//        }
//    }

    func testDiskClearToCount() {
        insertMultiItems(50)
        disk.deleteCache(exceedToCount: 20)
        XCTAssertEqual(20, disk.getTotalCount())
    }

    func testDiskClearToCountInBackground() {
        insertMultiItems(50)
        async { (done) in
            disk.deleteCache(exceedToCount: 20, inBackThread: {
                XCTAssertEqual(20, self.disk.getTotalCount())
                done()
            })
        }
    }

    func testDiskClearToCost() {
        insertMultiItems(20)
        disk.deleteCache(exceedToCost: 300)
        XCTAssertLessThanOrEqual(disk.getTotalCost(), 300)
    }

    func testDiskClearToCostInBackground() {
        insertMultiItems(20)
        async { (done) in
            disk.deleteCache(exceedToCost: 300, inBackThread: {
                XCTAssertLessThanOrEqual(self.disk.getTotalCost(), 300)
                done()
            })
        }
    }

    func testDiskClearToAge() {
        insertMultiItems(10)
        sleep(3) // wait 3 seconds, All the previous 10 elements have expired
        disk.deleteCache(exceedToAge: 2) // clears the elements before 2 seconds
        XCTAssertEqual(0, disk.getTotalCount())
    }

    func testDiskClearToAgeInBackground() {
        insertMultiItems(10)
        sleep(3)
        async { (done) in
            disk.deleteCache(exceedToAge: 2) {
                XCTAssertEqual(0, self.disk.getTotalCount())
                done()
            }
        }
    }

    func testDiskClearToFreeSpace() {
        // get free space
        let attr = try! FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
        let freeSize = attr[FileAttributeKey.systemFreeSize] as! Int

        // insert total size
        let cost = insertMultiItems(100)

        disk.deleteCache(toFreeSpace: freeSize + cost/2) // clear half of cost
        XCTAssertLessThanOrEqual(disk.getTotalCost(), cost/2)
    }

    func testDiskClearToFreeSpaceInBackground() {
        // get free space
        let attr = try! FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
        let freeSize = attr[FileAttributeKey.systemFreeSize] as! Int

        // insert total size
        let cost = insertMultiItems(100)

        async { (done) in
            disk.deleteCache(toFreeSpace: freeSize + cost/2) {
                XCTAssertLessThanOrEqual(self.disk.getTotalCost(), cost/2)
                done()
            }
        }
    }

//    func testDiskSpaceLimit() {
//        // get free space
//        let attr = try! FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
//        let freeSize = attr[FileAttributeKey.systemFreeSize] as! Int
//
//
//        disk.autoTrimInterval = 1
//
//        // insert total size
//        let cost = insertMultiItems(100)
//        disk.freeDiskSpaceLimit = freeSize + cost/2
//
//        sleep(2) // wait auto clear
//        XCTAssertLessThanOrEqual(disk.getTotalCost(), cost/2)
//    }
//
//
//    func testDiskAgeLimit() {
//        disk.autoTrimInterval = 1
//        disk.ageLimit = 1
//
//        insertMultiItems(10)
//
//        sleep(5)
//        XCTAssertEqual(0, disk.getTotalCount())
//    }
//
//    func testDiskCountLimit() {
//
//    }
//
//    func testDiskCostLimit() {
//
//    }
}

extension HQDiskCacheTest {
    func async(expect description: String = "async", timeout: Double = 5, block: (@escaping () -> Void) -> Void) {
        let expectation = self.expectation(description: description)
        block({ expectation.fulfill() })
        waitForExpectations(timeout: timeout, handler: nil)
    }

    @discardableResult
    func insertMultiItems(_ number: Int) -> Int {
        var cost = 0
        for idx in 0 ..< number {
            let obj = DiskTestClass("\(idx)", idx)
            disk.insertOrUpdate(object: obj, forKey: "\(idx)")
            cost += obj.serialize()?.count ?? 0
        }
        return cost
    }
}

