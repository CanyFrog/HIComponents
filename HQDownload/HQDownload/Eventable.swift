//
//  Eventable.swift
//  HQDownload
//
//  Created by HonQi on 8/13/18.
//  Copyright © 2018 HonQi Indie. All rights reserved.
//

import HQFoundation

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
