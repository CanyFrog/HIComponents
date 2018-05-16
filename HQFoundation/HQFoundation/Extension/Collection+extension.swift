//
//  Collection+extension.swift
//  HQFoundation
//
//  Created by Magee on 2018/5/16.
//  Copyright © 2018年 HQ.Personal.modules. All rights reserved.
//

import Foundation

extension Collection {
    
    /// Get collection whether or not at least one element pass predicate
    public func any(match predicate: (Iterator.Element) -> Bool) -> Bool {
        for elem in self where predicate(elem) { return true }
        return false
    }
    
    /// Get collection whether or not all element pass predicate
    public func all(match predicate: (Iterator.Element) -> Bool) -> Bool {
        return !any{ !predicate($0) }
    }
}
