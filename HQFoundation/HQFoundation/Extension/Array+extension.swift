//
//  Array+extension.swift
//  HQFoundation
//
//  Created by Magee on 2018/5/17.
//  Copyright © 2018年 HQ.Personal.modules. All rights reserved.
//

import Foundation

extension Namespace where T == Array<Any> {
    public func shuffle() -> T {
        var list = instance
        for index in 0..<list.count {
            let newIndex = Int(arc4random_uniform(UInt32(list.count-index))) + index
            if index != newIndex { list.swapAt(index, newIndex) }
        }
        return list
    }
}
