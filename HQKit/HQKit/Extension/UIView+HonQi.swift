//
//  UIView+HonQi.swift
//  HQKit
//
//  Created by HonQi on 2018/5/17.
//  Copyright © 2018年 HonQi Indie. All rights reserved.
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
    
    
    public func animated(hidden: Bool, completion: (()->Void)? = nil) {
        UIView.animate(withDuration: CATransaction.animationDuration(), animations: {
            self.instance.alpha = hidden ? 0.0 : 1.0
        }) { (_) in
            self.instance.isHidden = hidden
            self.instance.alpha = 1.0
            completion?()
        }
    }
}



extension Namespace where T: UIView {
    public var safeAreaBottomAnchor: NSLayoutYAxisAnchor {
        if #available(iOS 11.0, *) {
            return instance.safeAreaLayoutGuide.bottomAnchor
        }
        return instance.bottomAnchor
    }
    
    public var safeAreaTopAnchor: NSLayoutYAxisAnchor {
        if #available(iOS 11.0, *) {
            return instance.safeAreaLayoutGuide.topAnchor
        }
        return instance.topAnchor
    }
    
    public var left: CGFloat { return instance.frame.origin.x }
    public func set(left: CGFloat) { instance.frame.origin.x = left }
    
    public var top: CGFloat { return instance.frame.origin.y }
    public func set(top: CGFloat) { instance.frame.origin.y = top }
    
    public var width: CGFloat { return instance.frame.size.width }
    public func set(width: CGFloat) { instance.frame.size.width = width }
    
    public var height: CGFloat { return instance.frame.size.height }
    public func set(height: CGFloat) { instance.frame.size.height = height }
    
    public var right: CGFloat { return left + width }
    public func set(right: CGFloat) { instance.frame.origin.x = right - width }
    
    public var bottom: CGFloat { return instance.hq.top + instance.hq.height }
    public func set(bottom: CGFloat) { instance.frame.origin.y = bottom - height }
    
    public var origin: CGPoint { return instance.frame.origin }
    public func set(origin: CGPoint) { instance.frame.origin = origin }
    
    public var size: CGSize { return instance.frame.size }
    public func set(size: CGSize) { instance.frame.size = size }
    
    public var centerX: CGFloat { return instance.center.x }
    public func set(centerX: CGFloat) { instance.center.x = centerX }
    
    public var centerY: CGFloat { return instance.center.y }
    public func set(centerY: CGFloat) { instance.center.y = centerY }
    
    public static func autoLayout() -> T {
        let v = T(frame: .zero)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }
    
    public func constrainEqualWithSuperview() {
        precondition(!instance.translatesAutoresizingMaskIntoConstraints, "Auto layout must be translatesAutoresizingMaskIntoConstraints == false")
        let views = ["self": instance]
        NSLayoutConstraint.constraints(withVisualFormat: "H:|[self]|", options: .init(rawValue: 0), metrics: nil, views: views)
        NSLayoutConstraint.constraints(withVisualFormat: "V:|[self]|", options: .init(rawValue: 0), metrics: nil, views: views)
    }
    
    public func constrainCenterInSuperview() {
        precondition(!instance.translatesAutoresizingMaskIntoConstraints, "Auto layout must be translatesAutoresizingMaskIntoConstraints == false")
        NSLayoutConstraint.activate([
            instance.centerXAnchor.constraint(equalTo: instance.superview!.centerXAnchor),
            instance.centerYAnchor.constraint(equalTo: instance.superview!.centerYAnchor)
            ])
    }

}
