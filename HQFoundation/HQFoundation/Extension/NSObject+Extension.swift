//
//  NSObject+Extension.swift
//  HQFoundation
//
//  Created by HonQi on 2018/4/19.
//  Copyright © 2018年 HonQi Indie. All rights reserved.
//

import ObjectiveC

public typealias KVOClosure = (_ observer: NSObject, _ object: NSObject?, _ change: [String: Any]?) -> Void

extension NSObject: Namespaceable {}
extension Namespace where T: NSObject {
    /// Gets the Obj-C reference for the instance object within the UIView extension.
    /// If nil, initializer object and associated.
    @discardableResult
    public func associatedObject<C: Any>(key: UnsafePointer<UInt8>, policy: objc_AssociationPolicy = .OBJC_ASSOCIATION_RETAIN_NONATOMIC) -> C? {
        return objc_getAssociatedObject(instance, key) as? C
    }
    
    public func setAssociateObject<C: Any>(key: UnsafePointer<UInt8>, value: C, policy: objc_AssociationPolicy = .OBJC_ASSOCIATION_RETAIN_NONATOMIC) {
        objc_setAssociatedObject(instance, key, value, policy)
    }
}



/// A register info encapsulates the observer's callback information: the observer itself with either a block or a selector.
public struct KVORegisterInfo {
    /// Identifier can be nil if the RegInfo is invalid.
    var identifier: String?
    weak var observer: NSObject?
    var closure: KVOClosure?
    
    init(observer: NSObject, closure: @escaping KVOClosure) {
        self.observer = observer
        self.closure = closure
        identifier = "\(observer.hashValue)\(CFAbsoluteTimeGetCurrent()*1000)"
    }
    
    
    func trigger(host: NSObject, change: [String: Any]) {
        guard let observer = observer, let closure = closure else { return }
        closure(observer, host, change)
    }
}


struct KVOInfo {
    
}

private struct KVOHostWrapper {
    weak var host: NSObject?
}



