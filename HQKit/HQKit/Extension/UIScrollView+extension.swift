//
//  UIScrollView+extension.swift
//  HQKit
//
//  Created by Magee Huang on 5/22/18.
//  Copyright © 2018 com.personal.HQ. All rights reserved.
//

import HQFoundation

extension Namespace where T: UIScrollView {
    public var inset: UIEdgeInsets {
        get {
            if #available(iOS 11.0, *) {
                return instance.adjustedContentInset
            }
            return instance.contentInset
        }
    }
    
    public var offsetY: CGFloat {
        get { return instance.contentOffset.y }
        set { instance.contentOffset.y = newValue }
    }
    
    public var offsetX: CGFloat {
        get { return instance.contentOffset.x }
        set { instance.contentOffset.x = newValue }
    }
    
    public var contentWidth: CGFloat {
        get { return instance.contentSize.width }
        set { instance.contentSize.width = newValue }
    }
    
    public var contentHeight: CGFloat {
        get { return instance.contentSize.height }
        set { instance.contentSize.height = newValue }
    }
}
