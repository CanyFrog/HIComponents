//
//  HQCacheUtil.swift
//  HQCache
//
//  Created by qihuang on 2018/3/26.
//  Copyright © 2018年 com.personal.HQ. All rights reserved.
//




/// Object lock
func synchronized(_ lock: AnyObject, closure: () -> ()) {
    objc_sync_enter(lock)
    defer { objc_sync_exit(lock) }
    closure()
}

func synchronized<T>(_ lock: AnyObject, closure: () throws -> T) rethrows -> T {
    objc_sync_enter(lock)
    defer { objc_sync_exit(lock) }
    return try closure()
}


/// pthread lock
class Mutex {
    private let _mutex = UnsafeMutablePointer<pthread_mutex_t>.allocate(capacity: 1)
    init() {
        pthread_mutex_init(_mutex, nil)
    }
    
    static func autoLock(mutex: Mutex, closure: () -> Void) {
        mutex.lock()
        defer { mutex.unlock() }
        closure()
    }
    
    @discardableResult
    func lock() -> Int32 {
        return pthread_mutex_lock(_mutex)
    }
    
    @discardableResult
    func unlock() -> Int32 {
        return pthread_mutex_unlock(_mutex)
    }
    
    @discardableResult
    func tryLock() -> Int32 {
        return pthread_mutex_trylock(_mutex)
    }
    
    deinit {
        pthread_mutex_destroy(_mutex)
        _mutex.deallocate(capacity: 1)
    }
}
