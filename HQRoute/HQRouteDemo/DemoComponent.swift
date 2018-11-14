//
//  DemoComponent.swift
//  HQRouterDemo
//
//  Created by HonQi on 5/17/18.
//  Copyright © 2018 HonQi Indie. All rights reserved.
//

import HQRoute

struct DemoDataProvider: DataProvider {
    enum FuncNames: String {
        case demoDesc
    }
    func invoke<T>(name: String, params: [String : Any]) -> T? {
        guard let funcName = FuncNames(rawValue: name) else { return nil }
        switch funcName {
        case .demoDesc:
            return name as? T
        }
    }
}

class DemoComponent: Component {
    var uid: String!
    
    var urlComponent: RouterURLComponent!
    
    var router: Router?
    
    var navigateMode: RouterNavigateMode
    
    var viewController: UIViewController
    
    var dataProvider: DataProvider
    
    public init(dataProvider: DataProvider) {
        navigateMode = .push
        viewController = ViewController()
        self.dataProvider = dataProvider
    }
    
    func componentWillActive() {
        if let vc = viewController as? ViewController {
            vc.title = urlComponent["title"]
            vc.router = router
        }
    }
}
