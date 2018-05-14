//
//  NSPointerArray+extension.swift
//  HQFoundation
//
//  Created by qihuang on 2018/4/13.
//  Copyright © 2018年 HQ.Personal.modules. All rights reserved.
//

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
