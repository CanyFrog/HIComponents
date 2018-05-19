//
//  RotaryCircleView.swift
//  HQKit
//
//  Created by Magee on 2018/5/19.
//  Copyright © 2018年 com.personal.HQ. All rights reserved.
//

import UIKit

public class RotaryCircleView: UIView {
    private let circleDia: CGFloat = 4
    
    override public init(frame: CGRect) {
        super.init(frame: CGRect(x: 0, y: 0, width: circleDia, height: circleDia))
        layer.cornerRadius = circleDia / 2
        layer.masksToBounds = true
        backgroundColor = UIColor.hq.disable
        alpha = 0.0
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public func draw(_ rect: CGRect) {
        let radius = circleDia / 8
        let offset = radius * 1.2
        let centerX = (rect.width - radius) / 2
        let centerY = (rect.height - radius) / 2
        let ovalSize = CGSize(width: radius, height: radius)
        
        func createPoint(origin: CGPoint) -> CAShapeLayer {
            let s = CAShapeLayer()
            s.fillColor = UIColor.white.cgColor
            s.path = UIBezierPath.init(ovalIn: CGRect(origin: origin, size: ovalSize)).cgPath
            return s
        }
        layer.addSublayer(createPoint(origin: CGPoint(x: centerX - offset, y: centerY - offset)))
        layer.addSublayer(createPoint(origin: CGPoint(x: centerX - offset, y: centerY + offset)))
        layer.addSublayer(createPoint(origin: CGPoint(x: centerX + offset, y: centerY - offset)))
        layer.addSublayer(createPoint(origin: CGPoint(x: centerX + offset, y: centerY + offset)))
    }
}

extension RotaryCircleView {
    /// Auto increase to biggest
    public func show(_ rotate: Bool = true) {
        show(ratio: 1.0, time: 1.0)
        if !rotate { return }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.99) { self.rotate() }
    }
    
    /// Set view size and increase time
    public func show(ratio: CGFloat, time: CFTimeInterval = 0.25) {
        let rs = min(1.0, max(0.0, ratio)) * 10
        let group = CAAnimationGroup()
        group.animations = [rotateAnimation(to: rs), scaleAnimation(to: rs), alphaAnimation(to: rs)]
        group.isRemovedOnCompletion = false
        group.fillMode = kCAFillModeForwards
        group.duration = time
        layer.add(group, forKey: nil)
    }
    
    public func rotate() {
        let rotate = self.rotateAnimation(to: 20, clockWise: false)
        rotate.repeatCount = HUGE
        rotate.autoreverses = false
        rotate.isRemovedOnCompletion = false
        rotate.fillMode = kCAFillModeForwards
        rotate.duration = 1.0
        self.layer.add(rotate, forKey: nil)
    }
    
    /// Audo hidden
    public func hide() {
        show(ratio: 0.0, time: 1.0)
    }
}


// MARK: - Animation
extension RotaryCircleView {
    private func alphaAnimation(to ratio: CGFloat) -> CABasicAnimation {
        let basic = CABasicAnimation(keyPath: "opacity")
        basic.toValue = ratio
        return basic
    }
    
    private func rotateAnimation(to ratio: CGFloat, clockWise: Bool = true) -> CABasicAnimation {
        let basic = CABasicAnimation(keyPath: "transform.rotation.z")
        basic.toValue = CGFloat(Float.pi) / 10 * ratio * (clockWise ? -1 : 1)
        return basic
        
    }
    
    private func scaleAnimation(to ratio: CGFloat) -> CABasicAnimation {
        let basic = CABasicAnimation(keyPath: "transform.scale")
        basic.toValue = ratio
        return basic
    }
}


