//
//  Lock.swift
//  HQFoundation
//
//  Created by HonQi on 4/2/18.
//  Copyright © 2018 HonQi Indie. All rights reserved.
//

public protocol HQLocking {
    func tryLock(_ closure: () -> Void) -> Bool
    
    /// Auto lock & unlock
    func autoLock(_ closure: () -> Void)
    
    /// Auto lock & unlock and return value
    func autoLock<T>(_ closure: () -> T) -> T
    
    /// Auto lock & unlock and return value, If happen error, can throw error
    func autoLock<T>(_ closure: () throws -> T) rethrows -> T
}
extension HQLocking {
    public func tryLock(_ closure: () -> Void) -> Bool {
        return false
    }
}

extension HQLocking where Self: NSLocking {
    public func autoLock(_ closure: () -> Void) {
        lock()
        defer { unlock() }
        closure()
    }
    
    public func autoLock<T>(_ closure: () -> T) -> T {
        lock()
        defer { unlock() }
        return closure()
    }

    public func autoLock<T>(_ closure: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try closure()
    }
}

typealias Locking = NSLocking & HQLocking

extension NSLock: HQLocking {}
extension DispatchSemaphore: HQLocking {
    public func autoLock(_ closure: () -> Void) {
        let _ = wait(timeout: .distantFuture)
        defer { signal() }
        closure()
    }
    
    public func autoLock<T>(_ closure: () -> T) -> T {
        let _ = wait(timeout: .distantFuture)
        defer { signal() }
        return closure()
    }
    
    public func autoLock<T>(_ closure: () throws -> T) rethrows -> T {
        let _ = wait(timeout: .distantFuture)
        defer { signal() }
        return try closure()
    }
}

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



