//
//  UINavigationBar+HonQi.swift
//  HQKit
//
//  Created by HonQi on 2018/5/20.
//  Copyright © 2018年 HonQi Indie. All rights reserved.
//

import HQFoundation

var NavigationBarMargin: UInt8 = 001
extension Namespace where T: UINavigationBar {
    /// Set back button image, only change image
    public var backButtonImage: UIImage? { return instance.backIndicatorImage }

    public func set(backButtonImage: UIImage?) {
        instance.backIndicatorImage = backButtonImage
        instance.backIndicatorTransitionMaskImage = backButtonImage
    }
    
    /// Set backgroud iamge with white color and alpha
    public func set(backAlpha: CGFloat) {
        instance.setBackgroundImage(UIImage.hq.image(color: UIColor.white.withAlphaComponent(backAlpha), size: UIScreen.main.bounds.size), for: .default)
    }
    
    /// Hidden navigation bar bottom line
    public func hiddenLine() {
        instance.shadowImage = UIImage()
        if instance.backgroundImage(for: .default) == nil {
            instance.setBackgroundImage(UIImage(), for: .default)
        }
    }
}

//extension UINavigationBar {
//    open override func layoutSubviews() {
//        super.layoutSubviews()
//        if #available(iOS 11.0, *) {
//            subviews.forEach{ if NSStringFromClass($0.classForCoder).contains("ContentView") { $0.layoutMargins = UIEdgeInsets.zero }
//            }
//        }
//    }
//}
