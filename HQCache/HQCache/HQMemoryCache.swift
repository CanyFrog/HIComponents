//
//  HQMemoryCache.swift
//  HQCache
//
//  Created by qihuang on 2018/3/26.
//  Copyright © 2018年 com.personal.HQ. All rights reserved.
//

import HQFoundation

public final class HQMemoryCache: HQCacheProtocol {
    
    // MARK: - Public property
    public var countLimit: Int = Int.max
    
    public var costLimit: Int = Int.max
    
    public var ageLimit: TimeInterval = TimeInterval(INTMAX_MAX)
    
    public var autoTrimInterval: TimeInterval = 5.0
    
    public var autoEmptyCacheOnMemoryWarning = true
    
    public var autoEmptyCacheWhenEnteringBackground = true
    
    public var didReceiveMemoryWarningClosure: ((HQMemoryCache)->Void)?
    
    public var didEnterBackgroundClosure: ((HQMemoryCache)->Void)?
    
    public var releaseAsynchronously: Bool {
        get {
            mutex.lock()
            let release = cacheMap.releaseAsynchronously
            mutex.unlock()
            return release
        }
        set {
            mutex.lock()
            cacheMap.releaseAsynchronously = newValue
            mutex.unlock()
        }
    }
    
    public var releaseOnMainThread: Bool {
        get {
            mutex.lock()
            let release = cacheMap.releaseOnMainThread
            mutex.unlock()
            return release
        }
        set {
            mutex.lock()
            cacheMap.releaseOnMainThread = newValue
            mutex.unlock()
        }
    }
    
    // MARK: - Private property
    private var cacheMap = HQCacheLinkMap()
    private let queue = DispatchQueue(label: "com.memory.cache.personal.HQ", qos: .default, attributes: DispatchQueue.Attributes.concurrent)
    private let mutex = HQMutexLock()
    
    // MARk: - Life cycle
    public init() {
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveMemoryWarning), name: NSNotification.Name.UIApplicationDidReceiveMemoryWarning, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AppDidEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        clearCacheTiming()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidReceiveMemoryWarning, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        deleteAllCache()
    }
    
}


// MARK: - Query and Check
extension HQMemoryCache {
    public func exist(forKey key: String) -> Bool {
        mutex.lock()
        let contains = cacheMap.dict.keys.contains(key)
        mutex.unlock()
        return contains
    }
    
    public func query<T>(objectForKey key: String) -> T? {
        mutex.lock()
        defer { mutex.unlock() }
        guard let node = cacheMap.dict[key] else { return nil }
        node.time = CACurrentMediaTime()
        cacheMap.toHead(node: node)
        return node.value as? T
    }
    
    public func getTotalCount() -> Int {
        mutex.lock()
        let count = cacheMap.totalCount
        mutex.unlock()
        return count
    }
    
    public func getTotalCost() -> Int {
        mutex.lock()
        let cost = cacheMap.totalCost
        mutex.unlock()
        return cost
    }
    
}


// MARK: - Insert & update
extension HQMemoryCache {
    public func insertOrUpdate<T>(object obj: T, forKey key: String, cost: Int = 0) {
        mutex.lock()
        let now = CACurrentMediaTime()
        if let node = cacheMap.dict[key] {
            cacheMap.totalCost -= node.cost
            cacheMap.totalCost += cost
            node.cost = cost
            node.time = now
            node.value = obj
            cacheMap.toHead(node: node)
        }
        else {
            let node = HQCacheLinkNode()
            node.cost = cost
            node.value = obj
            node.time = now
            node.key = key
            cacheMap.insert(node: node)
        }
        mutex.unlock()
        
        if getTotalCount() > countLimit {
            clearCacheCondition(cond: cacheMap.totalCount > countLimit)
        }
        if getTotalCost() > costLimit {
            clearCacheCondition(cond: cacheMap.totalCost > costLimit)
        }
    }
}


// MARK: - Delete
extension HQMemoryCache {
    public func delete(objectForKey key: String) {
        mutex.lock()
        guard let node = cacheMap.dict[key] else {
            mutex.unlock()
            return
        }
        cacheMap.remove(node: node)
        mutex.unlock()
        
        if releaseAsynchronously {
            let queue = releaseOnMainThread ? DispatchQueue.main : DispatchQueue.global(qos: .utility)
            queue.async { let _ = node.self }
        }
        else if releaseOnMainThread && pthread_main_np() == 0 { // back to main thread release
            DispatchQueue.main.async { let _ = node.self }
        }
    }
    
    public func deleteAllCache() {
        mutex.lock()
        cacheMap.removeAll()
        mutex.unlock()
    }
    
    public func deleteCache(exceedToCost cost: Int) {
        if cost <= 0 {
            deleteAllCache()
            return
        }
        if getTotalCost() <= cost { return }
        
        clearCacheCondition(cond: cacheMap.totalCost > cost)
    }
    
    public func deleteCache(exceedToCount count: Int) {
        if count <= 0 {
            deleteAllCache()
            return
        }
        if getTotalCount() <= count { return }
        
        clearCacheCondition(cond: cacheMap.totalCount > count)
    }
    
    public func deleteCache(exceedToAge age: TimeInterval) {
        if age <= 0 {
            deleteAllCache()
            return
        }
        
        var finish = false
        mutex.lock()
        let now = CACurrentMediaTime()
        if cacheMap.tail == nil || (now - cacheMap.tail!.time) <= age {
            finish = true
        }
        mutex.unlock()
        if finish { return }
        
        clearCacheCondition(cond: cacheMap.tail != nil && (now - cacheMap.tail!.time) > age )
    }

}


// MARK: - Private clear cache helper
private extension HQMemoryCache {
    
    func clearCacheCondition(cond: @autoclosure () -> Bool) {
        var finish = false
        var holders = [HQCacheLinkNode]()
        
        while !finish {
            if mutex.tryLock() == 0 { // lock success
                if cond() {
                    if let node = cacheMap.removeTail() {
                        holders.append(node)
                    }
                }
                else {
                    finish = true
                }
                mutex.unlock()
            }
            else { // lock failure
                usleep(10 * 1000) // waiting 10 ms and try again
            }
        }
        
        if !holders.isEmpty {
            if releaseAsynchronously {
                let queue = releaseOnMainThread ? DispatchQueue.main : DispatchQueue.global(qos: .utility)
                queue.async { holders.removeAll() }
            }
            else if releaseOnMainThread && pthread_main_np() == 0 { // back to main thread release
                DispatchQueue.main.async { holders.removeAll() }
            }
        }
    }
    
    func clearCacheTiming() {
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: DispatchTime.now() + autoTrimInterval) {[weak self] in
            guard let wself = self else { return }
            wself.clearInBackground()
            wself.clearCacheTiming() // cycle execute
        }
    }
    
    func clearInBackground() {
        queue.async { [weak self] in
            guard let wself = self else { return }
            wself.deleteCache(exceedToAge: wself.ageLimit)
            wself.deleteCache(exceedToCost: wself.costLimit)
            wself.deleteCache(exceedToCount: wself.countLimit)
        }
    }
    
    @objc func didReceiveMemoryWarning() {
        if let did = didReceiveMemoryWarningClosure { did(self) }
        if autoEmptyCacheOnMemoryWarning { deleteAllCache() }
    }
    
    @objc func AppDidEnterBackground() {
        if let did = didEnterBackgroundClosure { did(self) }
        if autoEmptyCacheWhenEnteringBackground { deleteAllCache() }
    }
}


// MARK: - Data Struct -- Link table
fileprivate class HQCacheLinkNode {
    weak var prev: HQCacheLinkNode?
    weak var next: HQCacheLinkNode?
    var key: String!
    var value: Any!
    var cost: Int = 0
    var time: TimeInterval!
}

extension HQCacheLinkNode: Equatable {
    static func ==(lhs: HQCacheLinkNode, rhs: HQCacheLinkNode) -> Bool {
        return lhs.key == rhs.key
    }
}

fileprivate struct HQCacheLinkMap {
    var dict = Dictionary<String, HQCacheLinkNode>()
    var totalCost: Int = 0
    var totalCount: Int = 0
    var head: HQCacheLinkNode?
    var tail: HQCacheLinkNode?
    
    var releaseOnMainThread = false
    var releaseAsynchronously = true
    
    mutating func insert(node: HQCacheLinkNode) {
        dict[node.key] = node
        totalCost += node.cost
        totalCount += 1
        if let h = head {
            node.next = h
            h.prev = node
            head = node
        }
        else {
            head = node
            tail = node
        }
    }
    
    mutating func toHead(node: HQCacheLinkNode) {
        guard let h = head, h != node else { return }
        if tail! == node {
            tail = node.prev
            tail?.next = nil
        }
        else {
            node.next?.prev = node.prev
            node.prev?.next = node.next
        }
        
        node.next = head
        node.prev = nil
        head?.prev = node
        head = node
    }
    
    mutating func remove(node: HQCacheLinkNode) {
        dict.removeValue(forKey: node.key)
        totalCost -= node.cost
        totalCount -= 1
        if let n = node.next { n.prev = node.prev }
        if let p = node.prev { p.next = node.next }
        if head! == node { head = node.next }
        if tail! == node { tail = node.prev }
    }
    
    mutating func removeTail() -> HQCacheLinkNode? {
        guard let t = tail else { return nil }
        remove(node: t)
        return t
    }
    
    mutating func removeAll() {
        totalCost = 0
        totalCount = 0
        tail = nil
        head = nil
        
        if !dict.isEmpty {
            var holder = dict
            dict = Dictionary()
            
            if releaseAsynchronously {
                let queue = releaseOnMainThread ? DispatchQueue.main : DispatchQueue.global(qos: .utility)
                queue.async { holder.removeAll() }
            }
            else if releaseOnMainThread && pthread_main_np() == 0 { // back to main thread release
                DispatchQueue.main.async { holder.removeAll() }
            }
            // auto release
        }
    }
}
