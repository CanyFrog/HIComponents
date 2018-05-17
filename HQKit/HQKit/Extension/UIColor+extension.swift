
//
//  UIColor+extension.swift
//  HQKit
//
//  Created by Magee on 2018/5/17.
//  Copyright © 2018年 com.personal.HQ. All rights reserved.
//

import UIKit
import HQFoundation

extension Namespace where T: UIColor {
    public static func color(rgbHexValue: String, alpha: CGFloat = 1.0) -> UIColor {
        var value: UInt64 = 0
        Scanner(string: rgbHexValue).scanHexInt64(&value)
        return color(rgbHexValue: value, alpha: alpha)
    }
    
    public static func color(rgbHexValue: UInt64, alpha: CGFloat = 1.0) -> UIColor {
        return UIColor(red: CGFloat((rgbHexValue & 0xFF0000) >> 16)/255.0,
                       green: CGFloat((rgbHexValue & 0xFF00) >> 8)/255.0,
                       blue: CGFloat((rgbHexValue & 0xFF))/255.0,
                       alpha: alpha)
    }
}
