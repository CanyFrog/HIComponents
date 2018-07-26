//
//  NSObject+Extension.swift
//  HQFoundation
//
//  Created by HonQi on 2018/4/19.
//  Copyright © 2018年 HonQi Indie. All rights reserved.
//

import ObjectiveC

extension NSObject: Namespaceable {}
extension Namespace where T: NSObject {
    /// Gets the Obj-C reference for the instance object within the UIView extension.
    /// If nil, initializer object and associated.
    @discardableResult
    public func associatedObject<C: Any>(key: UnsafePointer<UInt8>) -> C? {
        return objc_getAssociatedObject(instance, key) as? C
    }
    
    public func setAssociateObject<C: Any>(key: UnsafePointer<UInt8>, value: C, policy: objc_AssociationPolicy = .OBJC_ASSOCIATION_RETAIN_NONATOMIC) {
        objc_setAssociatedObject(instance, key, value, policy)
    }
}
