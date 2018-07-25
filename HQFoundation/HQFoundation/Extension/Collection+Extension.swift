//
//  Collection+Extension.swift
//  HQFoundation
//
//  Created by HonQi on 2018/5/16.
//  Copyright © 2018年 HonQi Indie. All rights reserved.
//

import Foundation

// MARK: - Collection
extension Namespace where T: Collection {
    
    /// Get collection whether or not at least one element pass predicate
    public func any(match predicate: (T.Iterator.Element) -> Bool) -> Bool {
        for elem in instance where predicate(elem) { return true }
        return false
    }
    
    /// Get collection whether or not all element pass predicate
    public func all(match predicate: (T.Iterator.Element) -> Bool) -> Bool {
        return !any{ !predicate($0) }
    }
}



// MARK: - Array
extension Array: Namespaceable {}
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



// MARK: - NSPointerArray
extension Namespace where T: NSPointerArray {
    public func addObject(_ object: AnyObject?) {
        guard let strongObject = object else { return }
        
        let pointer = Unmanaged.passUnretained(strongObject).toOpaque()
        instance.addPointer(pointer)
    }
    
    public func insertObject(_ object: AnyObject?, at index: Int) {
        guard index < instance.count, let strongObject = object else { return }
        
        let pointer = Unmanaged.passUnretained(strongObject).toOpaque()
        instance.insertPointer(pointer, at: index)
    }
    
    public func replaceObject(at index: Int, withObject object: AnyObject?) {
        guard index < instance.count, let strongObject = object else { return }
        
        let pointer = Unmanaged.passUnretained(strongObject).toOpaque()
        instance.replacePointer(at: index, withPointer: pointer)
    }
    
    public func object(at index: Int) -> AnyObject? {
        guard index < instance.count, let pointer = instance.pointer(at: index) else { return nil }
        return Unmanaged<AnyObject>.fromOpaque(pointer).takeUnretainedValue()
    }
    
    public func removeObject(at index: Int) {
        guard index < instance.count else { return }
        
        instance.removePointer(at: index)
    }
}
