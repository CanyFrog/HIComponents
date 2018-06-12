//
//  UIViewController+Extension.swift
//  HQKit
//
//  Created by Magee on 2018/5/16.
//  Copyright © 2018年 com.personal.HQ. All rights reserved.
//

import HQFoundation

extension Namespace where T: UIViewController {
    public var currentViewController: UIViewController? {
        if let navigation = instance as? UINavigationController {
            return navigation.visibleViewController?.hq.currentViewController
        }
        else if let tabbar = instance as? UITabBarController {
            return tabbar.selectedViewController?.hq.currentViewController
        }
        else if let presented = instance.presentedViewController {
            return presented.hq.currentViewController
        }
        else {
            return instance
        }
    }
}
