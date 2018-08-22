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
    
    public var leftBarButtonItem: UIBarButtonItem? {
        get { return instance.topItem?.leftBarButtonItem }
        set { instance.topItem?.leftBarButtonItem = leftBarButtonItem }
    }
    
    public var leftBarButtonItems: [UIBarButtonItem]? {
        get { return instance.topItem?.leftBarButtonItems }
        set { instance.topItem?.setLeftBarButtonItems(leftBarButtonItems, animated: true) }
    }
    
    public var rightBarButtonItem: UIBarButtonItem? {
        get { return instance.topItem?.rightBarButtonItem }
        set { instance.topItem?.rightBarButtonItem = rightBarButtonItem }
    }
    
    public var rightBarButtonItems: [UIBarButtonItem]? {
        get { return instance.topItem?.rightBarButtonItems }
        set { instance.topItem?.setLeftBarButtonItems(rightBarButtonItems, animated: true) }
    }
    
    public func layoutSubviews() {
        instance.layoutSubviews()
        if #available(iOS 11.0, *) {
            instance.subviews.forEach { (subV) in
                if NSStringFromClass(subV.classForCoder).contains("ContentView") {
                    subV.layoutMargins = UIEdgeInsetsMake(0, 8, 0, 8)
                    subV.subviews.forEach { if let stack = $0 as? UIStackView { stack.distribution = .equalCentering }}
                }
            }
        }
    }
}

open class NavigationBar: UINavigationBar {
    public var itemMargin: CGFloat?
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        customLayout()
    }
    
    func customLayout() {
        
    }
}

private var HeightKey: UInt8 = 111
private var MarginKey: UInt8 = 112
extension UIBarButtonItem {
    var height: CGFloat? {
        set { hq.setAssociateObject(key: &HeightKey, value: height, policy: .OBJC_ASSOCIATION_ASSIGN) }
        get { return hq.associatedObject(key: &HeightKey) }
    }
    
    var margin: CGFloat? {
        set { hq.setAssociateObject(key: &MarginKey, value: margin, policy: .OBJC_ASSOCIATION_ASSIGN) }
        get { return hq.associatedObject(key: &MarginKey) }
    }
}

extension Namespace where T: UIBarButtonItem {
    public var height: CGFloat? {
        set { instance.height = height }
        get { return instance.height }
    }
    
    public var margin: CGFloat? {
        set { instance.margin = margin }
        get { return instance.margin }
    }
}


