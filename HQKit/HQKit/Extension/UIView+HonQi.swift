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



// MARK: - Layout
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
    public func left(_ value: CGFloat) { instance.frame.origin.x = value }
    
    public var top: CGFloat { return instance.frame.origin.y }
    public func top(_ value: CGFloat) { instance.frame.origin.y = value }
    
    public var width: CGFloat { return instance.frame.size.width }
    public func width(_ value: CGFloat) { instance.frame.size.width = value }
    
    public var height: CGFloat { return instance.frame.size.height }
    public func height(_ value: CGFloat) { instance.frame.size.height = value }
    
    public var right: CGFloat { return left + width }
    public func right(_ value: CGFloat) { instance.frame.origin.x = value - width }
    
    public var bottom: CGFloat { return instance.hq.top + instance.hq.height }
    public func bottom(_ value: CGFloat) { instance.frame.origin.y = value - height }
    
    public var origin: CGPoint { return instance.frame.origin }
    public func origin(_ value: CGPoint) { instance.frame.origin = value }
    
    public var size: CGSize { return instance.frame.size }
    public func size(_ value: CGSize) { instance.frame.size = value }
    
    public var centerX: CGFloat { return instance.center.x }
    public func centerX(_ value: CGFloat) { instance.center.x = value }
    
    public var centerY: CGFloat { return instance.center.y }
    public func centerY(_ value: CGFloat) { instance.center.y = value }
    
    public static func `init`() -> T {
        let view = T()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
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


// MARK: - Layer
extension Namespace where T: UIView {
    public func contents(_ image: UIImage) {
        instance.layer.contents = image.cgImage
    }
    
    
    /// Only display rect contents
    ///
    /// - Parameter contentsRect: rect range is (0, 1)
    public func contents(rect: CGRect) {
        instance.layer.contentsRect = rect
    }
    

    /// Define conents can resize area
    /// note: If contents bigger than container, the area will be squeezing and hidden; otherwise will be stretch
    public func contents(center: CGRect) {
        instance.layer.contentsCenter = center
    }
    
    
    /// Default corner radis only affect to background color,
    /// if you want affect to subviews and back image, set masks to true; and default is true
    public func corner(radis: CGFloat, masks: Bool = true) {
        instance.layer.cornerRadius = radis
        instance.layer.masksToBounds = true
    }
    
    
    /// Set border
    ///
    /// - Parameters:
    ///   - borderWidth: border width
    ///   - color: Default is white
    public func border(width: CGFloat, color: UIColor = UIColor.white) {
        instance.layer.borderWidth = width
        instance.layer.borderColor = color.cgColor
    }
    
    
    /// Set shadow
    ///
    /// - Parameters:
    ///   - color: shadow color, default is black
    ///   - offset: shadow offset size, default is (5,5), means x axis offset to right 5, y axis offset to bottom 5
    ///   - opacity: shadow opacity, default is 0.3
    ///   - radius: shadow edges radis, default is 3
    public func shadow(offset: CGSize = CGSize(width: 5, height: 5), opacity: Float = 0.3, radius: CGFloat = 3, color: UIColor = UIColor.black) {
        instance.layer.shadowColor = color.cgColor
        instance.layer.shadowOffset = offset
        instance.layer.shadowOpacity = opacity
        instance.layer.shadowRadius = radius
    }
    
    
    /// Set shadow shape from custom path; Performance better
    ///
    /// - Parameter rect: create CGPath with shadow shape rect
    public func shadow(path rect: CGRect) {
        instance.layer.shadowPath = UIBezierPath(rect: rect).cgPath
    }
    
    
    /// Package all subviews as a group and set alpha
    ///
    /// - Parameter uniteAlpha: alpha
    public func subviews(alpha: CGFloat) {
        instance.alpha = alpha
        // Prevent packaged view pixelation
        instance.layer.rasterizationScale = UIScreen.main.scale
        instance.layer.shouldRasterize = true
    }
    
    public func transform3D(_ value: CATransform3D) {
        instance.layer.transform = value
    }
    
    
    /// Set transform3D for all subviews
    public func subviews(transform3D: CATransform3D) {
        instance.layer.sublayerTransform = transform3D
    }
}
