//
//  Refreshable.swift
//  HQKit
//
//  Created by Magee on 2018/5/19.
//  Copyright © 2018年 com.personal.HQ. All rights reserved.
//

import Foundation


// MARK: - Header refresh protocol
public protocol HeaderRefreshable: Refreshable {}
extension HeaderRefreshable {
    public mutating func scrollViewContentOffset(didChange change: [NSKeyValueChangeKey : Any]) {
        if state == .refreshing { return }
        guard let scroll = scrollView, let _ = window else { return }
        
        // offset is minus if scroll to down; so when current offset value more than origin offset, must be scroll to up
        let currentOffsetY = scroll.contentOffset.y // current content offset in vertical
        let originOffsetY = originInset!.top // origin content offset in vertical
        let realOffsetY = abs(currentOffsetY - originOffsetY) // scroll offset delta
        
        //        setOriginInset() // handle open other viewcontroller lead to insert change
        
        if currentOffsetY >= originOffsetY { return } // scroll to up and not display refreshing view
        
        pullPercent = min(realOffsetY / pullLimit, 1)
        pullDelta = realOffsetY
        
        if scroll.isDragging {
            state = currentOffsetY < originOffsetY ? .ready : .idle
        }
        else {
            if state == .ready {
                state = realOffsetY >= pullLimit ? .refreshing : .idle
            }
            else {
                state = realOffsetY >= pullLimit ? .ready : .idle
            }
        }
    }
}


// MARK: - Footer refresh protocol
public protocol FooterRefreshable: Refreshable {
    var footerTop: CGFloat { get set }
}
extension FooterRefreshable {
    public mutating func scrollViewContentOffset(didChange change: [NSKeyValueChangeKey : Any]) {
        if state == .refreshing { return }
        guard let scroll = scrollView, let _ = window else { return }
        
        // offset is minus if scroll to down; so when current offset value more than origin offset, must be scroll to up
        let currentOffsetY = scroll.contentOffset.y // current content offset in vertical
        
        if currentOffsetY <= 0 { return } // pull to down
        
        let maxOffsetY = scroll.contentSize.height - (scroll.bounds.height - originInset!.bottom - originInset!.top)
        let realOffsetY = abs(currentOffsetY - maxOffsetY) // scroll offset delta
        
        pullDelta = realOffsetY
        pullPercent = min(realOffsetY / pullLimit, 1)
        
        if scroll.isDragging {
            state = .ready
        }
        else if state == .ready {
            state = realOffsetY >= pullLimit ? .refreshing : .idle
        }
    }
    
    
    public mutating func scrollViewContentSize(didChange change: [NSKeyValueChangeKey : Any]) {
        guard let height = (change[NSKeyValueChangeKey.newKey] as? CGSize)?.height else { return }
        footerTop = height
    }
}

// MARK: - Base refresh protocol
public enum RefreshState {
    case idle, ready, refreshing
}

public protocol Refreshable where Self: UIView {
    
    var state: RefreshState { get set }
    
    /// Scroll origin inset
    var originInset: UIEdgeInsets? { get set }
    
    /// Scroll View
    var scrollView: UIScrollView? { get set }
    
    /// Pulling limit of trigger refresh
    var pullLimit: CGFloat { get set }
    
    /// Current pulling value
    var pullDelta: CGFloat { get set }
    
    /// Current pulling percent, equal delta / limit
    var pullPercent: CGFloat { get set }
    
    /// Begin refresh callback
    var beginRefreshClosure: (()->Void)? { get set }
    
    func beginRefresh()
    
    func endRefresh()
    
    mutating func scrollViewContentOffset(didChange change: [NSKeyValueChangeKey: Any])
    
    mutating func scrollViewContentSize(didChange change: [NSKeyValueChangeKey: Any])
    
    /// When user click navigation bar, VC will scroll to top
    /// listen pan state can catch this event
    mutating func scrollViewPanState(didChange change: [NSKeyValueChangeKey: Any])
}

// MARK: - Optional func
extension Refreshable {
    public func scrollViewContentOffset(didChange change: [NSKeyValueChangeKey: Any]) {}
    public func scrollViewContentSize(didChange change: [NSKeyValueChangeKey: Any]) {}
    public func scrollViewPanState(didChange change: [NSKeyValueChangeKey: Any]) {}
    
    public mutating func endRefreshing() { state = .idle }
}

extension Refreshable {
    mutating func resetOriginInset() {
        if #available(iOS 11.0, *) {
            originInset = scrollView?.adjustedContentInset
        } else {
            originInset = scrollView?.contentInset
        }
    }
    
    mutating func injectView(superView: UIView?) {
        guard let superScroll = superView as? UIScrollView  else { return }
        removeObservers() // remove old observers
        
        scrollView = superScroll
        // config self
        superScroll.alwaysBounceVertical = true
        scrollView = superScroll
        resetOriginInset()
        
        addObservers()
    }
    
    func addObservers() {
        guard let scroll = scrollView else { return }
        let options = NSKeyValueObservingOptions.new.union(.old)
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
