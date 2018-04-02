//
//  HQLock.swift
//  HQFoundation
//
//  Created by Magee Huang on 4/2/18.
//  Copyright © 2018 HQ.Personal.modules. All rights reserved.
//

import Foundation

// MARK: - Object lock
public struct HQObjectLock {
    
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
}




// MARK: - Pthread lock
class HQMutexLock {
    private let _mutex = UnsafeMutablePointer<pthread_mutex_t>.allocate(capacity: 1)
    init() {
        pthread_mutex_init(_mutex, nil)
    }
    
    static func autoLock(_ mutex: HQMutexLock, closure: () -> Void) {
        mutex.lock()
        defer { mutex.unlock() }
        closure()
    }
    
    static func autoLock<T>(_ mutex: HQMutexLock, closure: () throws -> T) rethrows -> T {
        mutex.lock()
        defer { mutex.unlock() }
        return try closure()
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
