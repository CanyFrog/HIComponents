//
//  UINavigationBar+HonQi.swift
//  HQKit
//
//  Created by HonQi on 2018/5/20.
//  Copyright © 2018年 HonQi Indie. All rights reserved.
//

import HQFoundation

extension Namespace where T: UINavigationBar {
    /// Set back button image, only change image
    public var backButtonImage: UIImage? {
        get {
            return instance.backIndicatorImage
        }
        set {
            let image: UIImage? = newValue
            instance.backIndicatorImage = image
            instance.backIndicatorTransitionMaskImage = image
        }
    }
}

var NavigationBarMargin: UInt8 = 001
extension UINavigationBar {
    /// Adjust iOS 11.0 ~ Bar margin; default is 8px
    public var hq_itemMargin: CGFloat? {
        get { return hq.associatedObject(key: &NavigationBarMargin)}
        set {
            hq.setAssociateObject(key: &NavigationBarMargin, value: hq_itemMargin, policy: objc_AssociationPolicy.OBJC_ASSOCIATION_ASSIGN)
            setNeedsLayout()
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        if #available(iOS 11.0, *) {
            let margin = hq_itemMargin ?? 0
            subviews.forEach{ if NSStringFromClass($0.classForCoder).contains("ContentView") { $0.layoutMargins = UIEdgeInsets(top: 0, left: margin, bottom: 0, right: margin) } }
        }
    }
}
