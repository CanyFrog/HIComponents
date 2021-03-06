//
//  UIViewController+HonQi.swift
//  HQKit
//
//  Created by HonQi on 2018/5/16.
//  Copyright © 2018年 HonQi Indie. All rights reserved.
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
    
    public func modal(viewController: UIViewController, preferredHeight: CGFloat, animated: Bool, completion: (()->Void)? = nil) {
        let presentation = ActionSheetPresentation(presentedViewController: viewController, presenting: instance)
        presentation.preferredHeight = preferredHeight
    
        viewController.modalPresentationStyle = .custom
        viewController.transitioningDelegate = presentation
        instance.present(viewController, animated: animated, completion: completion)
    }
}
