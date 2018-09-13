//
//  UIScrollView+HonQi.swift
//  HQKit
//
//  Created by HonQi on 5/22/18.
//  Copyright © 2018 HonQi Indie. All rights reserved.
//

import HQFoundation

extension Namespace where T: UIScrollView {
    public var inset: UIEdgeInsets {
        if #available(iOS 11.0, *) { return instance.adjustedContentInset }
        return instance.contentInset
    }
    
    public var offsetY: CGFloat { return instance.contentOffset.y }
    public func offsetY(_ value: CGFloat) { instance.contentOffset.y = value }
    
    public var offsetX: CGFloat { return instance.contentOffset.x }
    public func offsetX(_ value: CGFloat) { instance.contentOffset.x = value }
    
    public var contentWidth: CGFloat { return instance.contentSize.width }
    public func contentWidth(_ value: CGFloat) { instance.contentSize.width = value }
    
    public var contentHeight: CGFloat { return instance.contentSize.height }
    public func contentHeight(_ value: CGFloat) { instance.contentSize.height = value }
}
