//
//  Runtime.swift
//  HQFoundation
//
//  Created by Qi on 2018/4/19.
//  Copyright © 2018年 HQ.Personal.modules. All rights reserved.
//

public struct Runtime {
    
    /// Gets the Obj-C reference for the instance object within the UIView extension.
    /// If nil, initializer object and associated.
    @discardableResult
    public static func AssociatedObject<T: Any>(base: Any, key: UnsafePointer<UInt8>, initializer: () -> T, policy: objc_AssociationPolicy = .OBJC_ASSOCIATION_RETAIN_NONATOMIC) -> T {
        if let v = objc_getAssociatedObject(base, key) as? T { return v }
        
        let v = initializer()
        objc_setAssociatedObject(base, key, v, policy)
        return v
    }
    
    public static func SetAssociateObject<T: Any>(base: Any, key: UnsafePointer<UInt8>, value: T, policy: objc_AssociationPolicy = .OBJC_ASSOCIATION_RETAIN_NONATOMIC) {
        objc_setAssociatedObject(base, key, value, policy)
    }
}
