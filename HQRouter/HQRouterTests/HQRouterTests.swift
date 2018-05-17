//
//  HQRouterTests.swift
//  HQRouterTests
//
//  Created by Magee Huang on 5/17/18.
//  Copyright © 2018 HQ.components.router. All rights reserved.
//

import XCTest
import HQRouter

class HQRouterConfigsTests: XCTestCase {
    class TestDataProvider: DataProvider { }
    class TestComponent: Component {
        var uid: String!
        var urlComponent: RouterURLComponent!
        var router: Router?
        var navigateMode: RouterNavigateMode
        var viewController: UIViewController
        var dataProvider: DataProvider
        
        init() {
            navigateMode = .none
            viewController = UIViewController()
            dataProvider = TestDataProvider()
        }
    }
    
    func testRouterConfigsRegister() {
        RouterConfigs.default.register(name: "component1") { (url) -> Component in
            let test = TestComponent()
            test.uid = "component1"
            return test
        }
        RouterConfigs.default.register(name: "component2") { (url) -> Component in
            let test = TestComponent()
            test.uid = "component2"
            return test
        }
        
        let component1: Component = RouterConfigs.default["component1"]!(RouterURLComponent(component: "component1"))
        XCTAssertNotNil(component1)
        XCTAssertEqual(component1.uid, "component1")
        
        let urlComponet = RouterURLComponent(component: "component2")
        let component2: Component = RouterConfigs.default[urlComponet]!
        XCTAssertNotNil(component2)
        XCTAssertEqual(component2.uid, "component2")
    }
}


class HQRouterTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
