//
//  Lock.swift
//  HQFoundation
//
//  Created by Magee Huang on 4/2/18.
//  Copyright © 2018 HQ.Personal.modules. All rights reserved.
//

public struct Lock {
    // MARK: - Dispatch lock
    public static func semaphore(_ lock: DispatchSemaphore, closure: () -> Void) {
        let _ = lock.wait(timeout: .distantFuture)
        defer { lock.signal() }
        closure()
    }
    
    @discardableResult
    public static func semaphore<T>(_ lock: DispatchSemaphore, closure: () -> T) -> T {
        let _ = lock.wait(timeout: .distantFuture)
        defer { lock.signal() }
        return closure()
    }
    
    @discardableResult
    public static func semaphore<T>(_ lock: DispatchSemaphore, closure: () throws -> T) rethrows -> T {
        let _ = lock.wait(timeout: .distantFuture)
        defer { lock.signal() }
        return try closure()
    }
    
    
    // MARK: - Object lock
    public static func synchronized(_ lock: AnyObject, closure: () -> ()) {
        objc_sync_enter(lock)
        defer { objc_sync_exit(lock) }
        closure()
    }
    
    @discardableResult
    public static func synchronized<T>(_ lock: AnyObject, closure: () -> T) -> T {
        objc_sync_enter(lock)
        defer { objc_sync_exit(lock) }
        return closure()
    }
    
    @discardableResult
    public static func synchronized<T>(_ lock: AnyObject, closure: () throws -> T) rethrows -> T {
        objc_sync_enter(lock)
        defer { objc_sync_exit(lock) }
        return try closure()
    }
    
    
    
    // MARK: - Pthread lock
    public final class Mutex {
        private let _mutex = UnsafeMutablePointer<pthread_mutex_t>.allocate(capacity: 1)
        public init() {
            pthread_mutex_init(_mutex, nil)
        }
        
        public static func autoLock(_ mutex: Mutex, closure: () -> Void) {
            mutex.lock()
            defer { mutex.unlock() }
            closure()
        }
        
        public static func autoLock<T>(_ mutex: Mutex, closure: () throws -> T) rethrows -> T {
            mutex.lock()
            defer { mutex.unlock() }
            return try closure()
        }
        
        @discardableResult
        public func lock() -> Int32 {
            return pthread_mutex_lock(_mutex)
        }
        
        @discardableResult
        public func unlock() -> Int32 {
            return pthread_mutex_unlock(_mutex)
        }
        
        @discardableResult
        public func tryLock() -> Int32 {
            return pthread_mutex_trylock(_mutex)
        }
        
        deinit {
            pthread_mutex_destroy(_mutex)
            _mutex.deallocate()
        }
    }
}



