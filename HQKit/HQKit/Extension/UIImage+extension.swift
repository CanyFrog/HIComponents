//
//  UIImage+extension.swift
//  HQKit
//
//  Created by Magee on 2018/5/17.
//  Copyright © 2018年 com.personal.HQ. All rights reserved.
//

import HQFoundation
import UIKit

extension Namespace where T: UIImage {
    
    /// Create new image with color and size
    public static func image(color: UIColor, size: CGSize) -> UIImage? {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContext(size)
        defer { UIGraphicsEndImageContext() }
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    
    /// Resize image to new size
    public func resize(size: CGSize) -> UIImage? {
        var w: CGFloat?
        var h: CGFloat?
        
        if 0 < size.width {
            h = instance.size.height * size.width / instance.size.width
        }
        else if 0 < size.height {
            w = instance.size.width * size.height / instance.size.height
        }
        
        let rect: CGRect = CGRect(x: 0, y: 0, width: w ?? size.width, height: h ?? size.height)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, UIScreen.main.scale)
        defer { UIGraphicsEndImageContext() }
        instance.draw(in: rect, blendMode: .normal, alpha: 1)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    
    /// Render color to current image
    public func render(color: UIColor) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(instance.size, false, UIScreen.main.scale)
        let context = UIGraphicsGetCurrentContext()
        defer { UIGraphicsEndImageContext() }
        
        context?.scaleBy(x: 1.0, y: -1.0)
        context?.translateBy(x: 0.0, y: -instance.size.height)
        
        context?.setBlendMode(.multiply)
        
        let rect = CGRect(x: 0, y: 0, width: instance.size.width, height: instance.size.height)
        context?.clip(to: rect, mask: instance.cgImage!)
        color.setFill()
        context?.fill(rect)
        
        return UIGraphicsGetImageFromCurrentImageContext()?.withRenderingMode(.alwaysOriginal)
    }
    
    /// Crops an image to a specified size
    public func crop(size: CGSize) -> UIImage? {
        let rate: CGFloat = min(size.height / instance.size.height, size.width / instance.size.width)
        let w = instance.size.width * rate
        let h = instance.size.height * rate
        
        UIGraphicsBeginImageContext(size)
        defer { UIGraphicsEndImageContext() }
        
        let rect = instance.size.width > instance.size.height ? CGRect(x: -1 * (w - size.width) / 2, y: 0, width: w, height: h) : CGRect(x: 0, y: -1 * (h - size.height) / 2, width: w, height: h)
        
        instance.draw(in: rect, blendMode: .normal, alpha: 1)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
