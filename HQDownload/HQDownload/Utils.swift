//
//  Utils.swift
//  HQDownload
//
//  Created by HonQi on 6/12/18.
//  Copyright © 2018 HonQi Indie. All rights reserved.
//

import HQFoundation

// MARK: - Error
public enum DownloadError: Error, CustomStringConvertible {
    case statusCodeInvalid(Int)
    case noCache304
    case error(Error)
    case cancel(String)
    case cacheError
    
    public var description: String {
        switch self {
        case .statusCodeInvalid(let code):
            return "Response status code \(code) is invalid!"
        case .noCache304:
            return "URLSession current behavior will return 200 status code when the server respond 304 and URLCache hit. But this is not cache."
        case .cancel(let reason):
            return "Task be canceled, because \(reason)"
        case .error(let err):
            return "Task is error, \(err.localizedDescription)"
        case .cacheError:
            return "Cache error: SQLite saved cache info is empty!"
        }
    }
}


// MARK: - Event
protocol Eventable: class {
    typealias EventWrap = (URL, EventClosure.Event) -> Void
    
    var eventsMap: InnerKeyMap<EventWrap> {get set}
    var eventsLock: DispatchSemaphore {get set}
    
    @discardableResult func subscribe(_ events: EventClosure ...) -> UInt64
    func unsubscribe(_ key: UInt64)
    func trigger( _ url: URL, _ event: EventClosure.Event)
}

extension Eventable {
    @discardableResult
    public func subscribe(_ events: EventClosure ...) -> UInt64 {
        let wrap: EventWrap = { (url, event) in
            events.forEach { $0.trigger(url: url, event: event) }
        }
        
        return Lock.semaphore(eventsLock) { () -> UInt64 in
            return eventsMap.insert(wrap)
        }
    }
    
    @discardableResult
    public func subscribe(url: URL, _ events: EventClosure ...) -> UInt64 {
        let wrap: EventWrap = { (source, event) in
            guard source == url else { return }
            events.forEach { $0.trigger(url: source, event: event) }
        }
        
        return Lock.semaphore(eventsLock) { () -> UInt64 in
            return eventsMap.insert(wrap)
        }
    }
    
    public func unsubscribe(_ key: UInt64) {
        Lock.semaphore(eventsLock) {
            eventsMap.remove(key)
        }
    }
    
    func trigger( _ url: URL, _ event: EventClosure.Event) {
        DispatchQueue.main.async {
            self.eventsMap.forEach({ (wrap) in
                wrap(url, event)
            })
        }
    }
}



public enum EventClosure {
    case start((URL, String, Int64)->Void)
    case progress((URL, Progress)->Void)
    case data((URL, Data)->Void)
    case completed((URL, URL)->Void)
    case error((URL, DownloadError)->Void)
    
    internal func trigger(url: URL, event: Event) {
        switch (self, event) {
        case (.start(let closure), .start(let name, let size)):
            closure(url, name, size)
        case (.progress(let closure), .progress(let rate)):
            closure(url, rate)
        case (.data(let closure), .data(let d)):
            closure(url, d)
        case (.completed(let closure), .completed(let file)):
            closure(url, file)
        case (.error(let closure), .error(let err)):
            closure(url, err)
        default:
            break
        }
    }
    
    enum Event {
        case start(String, Int64) // start Name and size
        case progress(Progress)
        case data(Data)
        case completed(URL) // completion file url
        case error(DownloadError)
    }
}



// MARK: - Extension
extension Namespace where T: URLSession {
    internal static func create(_ options: OptionsInfo, delegate: URLSessionDelegate) -> T {
        var config: URLSessionConfiguration! = nil
        if options.backgroundSession {
            config = URLSessionConfiguration.background(withIdentifier: UUID().uuidString)
            // TODO: Pass identifier to other object
        }
        else {
            config = URLSessionConfiguration.default
        }
        
        config.allowsCellularAccess = !options.onlyWifiAccess
        //        config.timeoutIntervalForRequest = options.taskTimeout
        //        config.timeoutIntervalForResource = options.taskTimeout
        return T(configuration: config, delegate: delegate, delegateQueue: nil)
    }
}

extension URLRequest: Namespaceable {}
extension Namespace where T == URLRequest {
    internal static func create(_ options: OptionsInfo) -> T? {
        guard let url = options.sourceUrl else {
            return nil
        }
        var request = URLRequest(url: url,
                                 cachePolicy: options.useUrlCache ? .useProtocolCachePolicy : .reloadIgnoringLocalCacheData,
                                 timeoutInterval: options.taskTimeout)
        //        request.httpShouldUsePipelining = true // 不必等到response， 就可以再次请求。但是取决于服务器响应的顺序和客户端请求顺序一致，否则容易出问题
        request.httpShouldHandleCookies = options.handleCookies
        
        let rangeStart = options.completedCount
        let rangeEnd = options.exceptedCount
        
        if let start = rangeStart, let end = rangeEnd {
            request.setValue("bytes=\(start)-\(end)", forHTTPHeaderField: "Range")
        }
        else if let start = rangeStart {
            request.setValue("bytes=\(start)-", forHTTPHeaderField: "Range")
        }
        else if let end = rangeEnd {
            request.setValue("bytes=0-\(end)", forHTTPHeaderField: "Range")
        }
        return request
    }
}


// MARK: - InnerKeyMap
struct InnerKeyMap<T> {
    struct UIntKey: Hashable, Equatable {
        fileprivate let rawValue: UInt64
        var hashValue: Int { return rawValue.hashValue }
        public static func == (lhs: UIntKey, rhs: UIntKey) -> Bool {
            return lhs.rawValue == rhs.rawValue
        }
    }
    
    let ArrayMaxSize: Int = 30
    
    typealias Key = UIntKey
    
    private var _nextKey: Key = Key(rawValue: 0)
    
    /// Save first key, value pairs
    private var key_0: Key?
    private var value_0: T?
    private var singleValue = true
    
    /// Save 2th - 31th pairs to array
    typealias Pairs = (key: Key, value: T)
    private var pairs = ContiguousArray<Pairs>()
    
    /// Save 31th - ∞ pairs to dictionary
    private var dict: [Key: T]?
    
    var count: Int {
        return pairs.count + (dict?.count ?? 0) + (key_0 != nil ? 1 : 0)
    }
    
    init() {
    }
    
    @discardableResult
    mutating func insert(_ element: T) -> UInt64 {
        let key = _nextKey
        _nextKey = Key(rawValue: _nextKey.rawValue &+ 1) // 溢出加 1
        
        guard let _ = key_0 else {
            key_0 = key
            value_0 = element
            return key.rawValue
        }
        
        singleValue = false
        
        guard dict == nil else {
            dict![key] = element
            return key.rawValue
        }
        
        guard pairs.count >= ArrayMaxSize else {
            pairs.append((key: key, value: element))
            return key.rawValue
        }
        
        dict = [key: element]
        return key.rawValue
    }
    
    mutating func removeAll() {
        key_0 = nil
        value_0 = nil
        
        pairs.removeAll(keepingCapacity: false)
        
        dict?.removeAll(keepingCapacity: false)
    }
    
    @discardableResult
    mutating func remove(_ key: UInt64) -> T? {
        let _key = Key(rawValue: key)
        if key_0 == _key {
            key_0 = nil
            let value = value_0
            value_0 = nil
            return value
        }
        
        if let obj = dict?.removeValue(forKey: _key) {
            return obj
        }
        
        for i in 0 ..< pairs.count {
            if pairs[i].key == _key {
                let value = pairs[i].value
                pairs.remove(at: i)
                return value
            }
        }
        
        return nil
    }
    
    func forEach(_ action: (T) -> Void) {
        if let v = value_0 { action(v) }
        
        pairs.forEach{ action($1) }
        
        dict?.forEach{ action($1) }
    }
}

