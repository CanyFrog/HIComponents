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

    func testRouterInit() {
        let uri = "test://home?key=value"
        let nav = UINavigationController()
        let router = Router(uri: uri, navigator: nav)
        
        XCTAssertEqual(router.scheme, "test")
        XCTAssertEqual(router.mainUrl.description, uri)
        XCTAssertNotNil(router.navigator)
    }
    
    func testRouterForward() {
        let uri = "test://home?key=value"
        let nav = UINavigationController()
        let router = Router(uri: uri, navigator: nav)
        
        router.forward(component: "path1/path2")
        XCTAssertEqual(router.mainUrl.description, uri.appending("/path1/path2"))
    }
    
    func testRouterBack() {
        let uri = "test://home?key=value/path1/path2"
        let nav = UINavigationController()
        let router = Router(uri: uri, navigator: nav)
        
        router.back(steps: 2, animated: true)
        XCTAssertEqual(router.mainUrl.description, "test://home?key=value")
    }
    
    func testRouterHome() {
        let uri = "test://home?key=value/path1/path2"
        let nav = UINavigationController()
        let router = Router(uri: uri, navigator: nav)
        
        router.back(steps: 2, animated: true)
        XCTAssertEqual(router.mainUrl.description, "test://home?key=value")
    }
}
