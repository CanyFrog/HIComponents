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
    public func set(offsetY: CGFloat) { instance.contentOffset.y = offsetY }
    
    public var offsetX: CGFloat { return instance.contentOffset.x }
    public func set(offsetX: CGFloat) { instance.contentOffset.x = offsetX }
    
    public var contentWidth: CGFloat { return instance.contentSize.width }
    public func set(contentWidth: CGFloat) { instance.contentSize.width = contentWidth }
    
    public var contentHeight: CGFloat { return instance.contentSize.height }
    public func set(contentHeight: CGFloat) { instance.contentSize.height = contentHeight }
}
