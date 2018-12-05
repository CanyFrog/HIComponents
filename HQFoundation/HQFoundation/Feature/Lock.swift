//
//  Lock.swift
//  HQFoundation
//
//  Created by HonQi on 4/2/18.
//  Copyright © 2018 HonQi Indie. All rights reserved.
//


/// Protocol
public protocol HQLocking {
    /// Auto lock & unlock
    func autoLock(_ closure: () -> Void)
    
    /// Auto lock & unlock and return value
    func autoLock<T>(_ closure: () -> T) -> T
    
    /// Auto lock & unlock and return value, If happen error, can throw error
    func autoLock<T>(_ closure: () throws -> T) rethrows -> T
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



extension DispatchSemaphore: HQLocking {
    public func autoLock(_ closure: () -> Void) {
        wait()
        defer { signal() }
        closure()
    }

    public func autoLock<T>(_ closure: () -> T) -> T {
        wait()
        defer { signal() }
        return closure()
    }

    public func autoLock<T>(_ closure: () throws -> T) rethrows -> T {
        wait()
        defer { signal() }
        return try closure()
    }
}

/// Wrapper for os_unfair_lock
@available(iOS 10.0, *)
public class Spin: Locking {
    private let _unfair: os_unfair_lock_t
    
    public init() {
        _unfair = UnsafeMutablePointer<os_unfair_lock_s>.allocate(capacity: 1)
    }
    public func lock() {
        os_unfair_lock_lock(_unfair)
    }
    
    public func unlock() {
        os_unfair_lock_unlock(_unfair)
    }
    
    public func `try`() -> Bool {
        return os_unfair_lock_trylock(_unfair)
    }
}


// MARK: - Mutex
/// PTHREAD_MUTEX_ERRORCHECK attribute of pthread_mutex_t is NSLock
public typealias MutexError = NSLock
extension MutexError: HQLocking {}

/// PTHREAD_MUTEX_RECURSIVE attribute of pthread_mutex_t is NSRecursiveLock
public typealias MutexRecursive = NSRecursiveLock
extension MutexRecursive: HQLocking {}

/// Mutex is a PTHREAD_MUTEX_NORMAL attribute of pthread_mutex_t OO wrapper
public class Mutex: Locking {
    private let _mutex = UnsafeMutablePointer<pthread_mutex_t>.allocate(capacity: 1)

    public init() {
        pthread_mutex_init(_mutex, nil)
    }

    public func lock() {
        pthread_mutex_lock(_mutex)
    }
    
    public func unlock() {
        pthread_mutex_unlock(_mutex)
    }
    
    public func `try`() -> Bool {
        return pthread_mutex_trylock(_mutex) == 0
    }
    
    deinit {
        pthread_mutex_destroy(_mutex)
        _mutex.deallocate()
    }
}


// MARK: - Synchronized
public func Synchronized(_ lock: AnyObject, closure: () -> Void) {
    objc_sync_enter(lock)
    defer { objc_sync_exit(lock) }
    closure()
}


public func Synchronized<T>(_ lock: AnyObject, closure: () -> T) -> T {
    objc_sync_enter(lock)
    defer { objc_sync_exit(lock) }
    return closure()
}

public func Synchronized<T>(_ lock: AnyObject, closure: () throws -> T) rethrows -> T {
    objc_sync_enter(lock)
    defer { objc_sync_exit(lock) }
    return try closure()
}
