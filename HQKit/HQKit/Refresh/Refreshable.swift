//
//  Refreshable.swift
//  HQKit
//
//  Created by HonQi on 2018/5/19.
//  Copyright © 2018年 HonQi Indie. All rights reserved.
//

import Foundation


public enum RefreshState: Equatable {
    case idle
    case pulling(CGFloat)   // Pulling state, parameters is pulling delta
    case ready              // Pulling offset more than limit, if let go, trigger refreshing
    case refreshing
}

// MARK: - Header refresh protocol
public protocol HeaderRefreshable: Refreshable {}
extension HeaderRefreshable where Self: UIView {
    public func scrollViewContentOffset(didChange change: [NSKeyValueChangeKey : Any]) {
        guard let scroll = scrollView, scroll.hq.contentHeight > 0, state != .refreshing else { return }
        
        // If offset.y less than 0, means pull to down, didn't handle
        guard let newOffset: CGPoint = change[NSKeyValueChangeKey.newKey] as? CGPoint, newOffset.y < 0 else { return }
        
        // Scroll real content offset height
        // inset.top auto minus
        let offsetSizeY = -scroll.hq.inset.top
        
        guard offsetSizeY > newOffset.y else { return }
        // offset
        let offsetDelta = offsetSizeY - newOffset.y
        if scroll.isDragging {
            state = offsetDelta >= pullLimit ? .ready : .pulling(offsetDelta)
        }
        else {
            state = state == .ready ? .refreshing : .idle
        }
    }
}


// MARK: - Footer refresh protocol
public protocol FooterRefreshable: Refreshable {}
extension FooterRefreshable where Self: UIView {
    public func scrollViewContentOffset(didChange change: [NSKeyValueChangeKey : Any]) {
        // Scrollview exist, and content size > 0
        // scroll.hq.inset.top + scroll.hq.contentHeight > scroll.hq.height
        guard let scroll = scrollView, scroll.hq.contentHeight > 0, state != .refreshing else { return }
        
        // If offset.y less than 0, means pull to down, didn't handle
        guard let newOffset: CGPoint = change[NSKeyValueChangeKey.newKey] as? CGPoint, newOffset.y > 0 else { return }
        
        // Scroll real content offset height
        // inset.top auto minus
        let offsetSizeY = max(0, scroll.hq.contentHeight + scroll.hq.inset.bottom - scroll.hq.height)
        
        // offset
        let offsetDelta = newOffset.y - offsetSizeY
        guard offsetDelta > 0 else { return }
        
        if scroll.isDragging {
            state = offsetDelta >= pullLimit ? .ready : .pulling(offsetDelta)
        }
        else {
            state = state == .ready ? .refreshing : .idle
        }
    }
    
    public func scrollViewContentSize(didChange change: [NSKeyValueChangeKey : Any]) {
        guard let height = (change[NSKeyValueChangeKey.newKey] as? CGSize)?.height else { return }
        frame.origin.y = height  // update footer origin.y equal scroll view height
    }
}




// MARK: - Base refresh protocol
public protocol Refreshable: class {
    
    var state: RefreshState { get set }
    
    /// Scroll origin inset
    var originInset: UIEdgeInsets? { get set }
    
    /// Scroll View
    var scrollView: UIScrollView? { get set }
    
    /// Pulling limit of trigger refresh
    var pullLimit: CGFloat { get set }
    
    /// Begin refresh callback
    var beginRefreshClosure: (()->Void)? { get set }
    var endRefreshClosure: (()->Void)? { get set }
    
    init(container: UIScrollView, limit: CGFloat)
    
    func beginRefresh()
    
    func endRefresh()
    
    func scrollViewContentOffset(didChange change: [NSKeyValueChangeKey: Any])
    
    func scrollViewContentSize(didChange change: [NSKeyValueChangeKey: Any])
    
    /// When user click navigation bar, VC will scroll to top
    /// listen pan state can catch this event
    func scrollViewPanState(didChange change: [NSKeyValueChangeKey: Any])
}

// MARK: - Optional func
extension Refreshable {
    public func scrollViewContentOffset(didChange change: [NSKeyValueChangeKey: Any]) {}
    public func scrollViewContentSize(didChange change: [NSKeyValueChangeKey: Any]) {}
    public func scrollViewPanState(didChange change: [NSKeyValueChangeKey: Any]) {}
    
    public func beginRefresh() {
        state = .pulling(pullLimit)
        state = .refreshing
    }
    public func endRefresh() { state = .idle }
}

extension Refreshable where Self: UIView {
    func resetOriginInset() {
        if #available(iOS 11.0, *) {
            originInset = scrollView?.adjustedContentInset
        } else {
            originInset = scrollView?.contentInset
        }
    }
    
    func injectView(superView: UIView?) {
        guard let superScroll = superView as? UIScrollView  else { return }
        
        removeObservers() // remove old observers
        
        scrollView = superScroll
        
        frame.size.width = superScroll.hq.width
        if #available(iOS 11.0, *) {
            frame.origin.x = superScroll.adjustedContentInset.left
        }
        else {
            frame.origin.x = superScroll.contentInset.left
        }
        
        
        // config self
        superScroll.alwaysBounceVertical = true
        
        resetOriginInset()
        
        addObservers() // add new observers
    }
    
    func addObservers() {
        guard let scroll = scrollView else { return }
        let options: NSKeyValueObservingOptions = [.new, .old]
        scroll.addObserver(self, forKeyPath: "contentOffset", options: options, context: nil)
        scroll.addObserver(self, forKeyPath: "contentSize", options: options, context: nil)
        scroll.panGestureRecognizer.addObserver(self, forKeyPath: "state", options: options, context: nil)
    }
    
    func removeObservers() {
        scrollView?.removeObserver(self, forKeyPath: "contentOffset")
        scrollView?.removeObserver(self, forKeyPath: "contentSize")
        scrollView?.panGestureRecognizer.removeObserver(self, forKeyPath: "state")
    }
    
    func observeValueFor(keyPath: String, change: [NSKeyValueChangeKey: Any]) {
        if !isUserInteractionEnabled { return }
        
        // hidden alway handle
        if keyPath == "contentSize" {
            scrollViewContentSize(didChange: change)
        }
        
        if isHidden { return }
        
        if keyPath == "contentOffset" {
            scrollViewContentOffset(didChange: change)
        }
        else if keyPath == "state" {
            scrollViewPanState(didChange: change)
        }
    }
}
