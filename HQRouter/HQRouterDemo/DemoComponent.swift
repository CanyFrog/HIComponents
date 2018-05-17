//
//  DemoComponent.swift
//  HQRouterDemo
//
//  Created by Magee Huang on 5/17/18.
//  Copyright © 2018 HQ.components.router. All rights reserved.
//

import HQRouter

class DemoDataProvider: DataProvider {
    
}

class DemoComponent: Component {
    var uid: String!
    
    var urlComponent: RouterURLComponent!
    
    var router: Router?
    
    var navigateMode: RouterNavigateMode
    
    var viewController: UIViewController
    
    var dataProvider: DataProvider
    
    public init() {
        navigateMode = .push
        viewController = ViewController()
        dataProvider = DemoDataProvider()
    }
    
    func componentWillActive() {
        print(router!.mainUrl.description)
        print(urlComponent.description)
        for item in urlComponent.queryItems! {
            print(item.description)
        }
    }
}
