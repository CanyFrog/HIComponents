//
//  NSObject+Extension.swift
//  HQFoundation
//
//  Created by Qi on 2018/4/19.
//  Copyright © 2018年 HQ.Personal.modules. All rights reserved.
//

extension NSObject: Namespaceable {}
extension Namespace where T: NSObject {
    /// Gets the Obj-C reference for the instance object within the UIView extension.
    /// If nil, initializer object and associated.
    @discardableResult
    public static func associatedObject<C: Any>(base: Any, key: UnsafePointer<UInt8>, initializer: () -> C, policy: objc_AssociationPolicy = .OBJC_ASSOCIATION_RETAIN_NONATOMIC) -> C {
        if let v = objc_getAssociatedObject(base, key) as? C { return v }
        
        let v = initializer()
        objc_setAssociatedObject(base, key, v, policy)
        return v
    }
    
    public static func setAssociateObject<C: Any>(base: Any, key: UnsafePointer<UInt8>, value: C, policy: objc_AssociationPolicy = .OBJC_ASSOCIATION_RETAIN_NONATOMIC) {
        objc_setAssociatedObject(base, key, value, policy)
    }

}

