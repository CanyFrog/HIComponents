//
//  UIView+extension.swift
//  HQKit
//
//  Created by Magee on 2018/5/17.
//  Copyright © 2018年 com.personal.HQ. All rights reserved.
//

import HQFoundation
import UIKit

extension Namespace where T: UIView {
    public var viewController: UIViewController? {
        var view: UIView? = instance
        while view?.superview != nil || view?.next != nil {
            if let response = view?.next, response.isKind(of: UIViewController.self)  {
                return response as? UIViewController
            }
            view = view?.superview
        }
        return nil
    }
    
    public func snapshot() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(instance.bounds.size, false, UIScreen.main.scale)
        instance.drawHierarchy(in: instance.bounds, afterScreenUpdates: true)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }
    
    
    public func removeAllSubviews() {
        instance.subviews.forEach{ $0.removeFromSuperview() }
    }
}



extension Namespace where T: UIView {
    var left: CGFloat {
        get { return instance.frame.origin.x }
        set { instance.frame.origin.x = newValue }
    }
    
    var top: CGFloat {
        get { return instance.frame.origin.y }
        set { instance.frame.origin.y = newValue }
    }
    
    var width: CGFloat {
        get { return instance.frame.size.width }
        set { instance.frame.size.width = newValue }
    }
    
    var height: CGFloat {
        get { return instance.frame.size.height }
        set { instance.frame.size.height = newValue }
    }
    
    var right: CGFloat {
        get { return instance.hq.left + instance.hq.width }
//        set { instance.hq.left = newValue - instance.hq.width }
    }
    
    var bottom: CGFloat {
        get { return instance.hq.top + instance.hq.height }
//        set { instance.hq.top = newValue - instance.hq.height }
    }
    
    var origin: CGPoint {
        get { return instance.frame.origin }
        set { instance.frame.origin = newValue }
    }
    
    var size: CGSize {
        get { return instance.frame.size }
        set { instance.frame.size = newValue }
    }
    
    var centerX: CGFloat {
        get { return instance.center.x }
        set { instance.center.x = newValue }
    }
    
    var centerY: CGFloat {
        get { return instance.center.y }
        set { instance.center.y = newValue }
    }
    
    public static func autoLayout() -> T {
        let v = T(frame: .zero)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }
}
