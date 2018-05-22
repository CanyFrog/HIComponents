//
//  UINavigationBar+extension.swift
//  HQKit
//
//  Created by Magee on 2018/5/20.
//  Copyright © 2018年 com.personal.HQ. All rights reserved.
//

import HQFoundation

extension Namespace where T: UINavigationBar {
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
