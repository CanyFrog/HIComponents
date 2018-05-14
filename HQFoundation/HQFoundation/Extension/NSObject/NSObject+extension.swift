//
//  NSObject+extension.swift
//  HQFoundation
//
//  Created by Qi on 2018/4/19.
//  Copyright © 2018年 HQ.Personal.modules. All rights reserved.
//

extension NSObject: Namespaceable {}
extension Namespace where T == String {
    public var className: String {
        return String(describing: type(of: self)).components(separatedBy: ".").last!
    }
    
    public static var className: String {
        return String(describing: self).components(separatedBy: ".").last!
    }
}
