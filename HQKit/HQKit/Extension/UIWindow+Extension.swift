//
//  UIWindow+Extension.swift
//  HQKit
//
//  Created by HonQi on 2018/5/20.
//  Copyright © 2018年 HonQi Indie. All rights reserved.
//

import HQFoundation

extension Namespace where T: UIWindow {
    public func replaceRootViewControllerWith(_ replacementController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        let snapshotImageView = UIImageView(image: snapshot())
        instance.addSubview(snapshotImageView)
        
        let dismissCompletion = {[weak instance] () -> Void in // dismiss all modal view controllers
            instance?.rootViewController = replacementController
            instance?.bringSubview(toFront: snapshotImageView)
            if animated {
                UIView.animate(withDuration: 0.4, animations: { () -> Void in
                    snapshotImageView.alpha = 0
                }, completion: { (success) -> Void in
                    snapshotImageView.removeFromSuperview()
                    completion?()
                })
            }
            else {
                snapshotImageView.removeFromSuperview()
                completion?()
            }
        }
        
        if instance.rootViewController!.presentedViewController != nil {
            instance.rootViewController!.dismiss(animated: false, completion: dismissCompletion)
        }
        else {
            dismissCompletion()
        }
    }
}
