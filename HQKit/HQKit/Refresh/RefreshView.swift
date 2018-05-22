//
//  RefreshView.swift
//  HQKit
//
//  Created by Magee Huang on 5/22/18.
//  Copyright © 2018 com.personal.HQ. All rights reserved.
//

import UIKit


public class HeaderRefreshView: UIView, HeaderRefreshable {
    public var state: RefreshState = .idle { willSet{ update(state: newValue, toState: state) }}
    
    public var originInset: UIEdgeInsets?
    
    public weak var scrollView: UIScrollView?
    
    public var pullLimit: CGFloat = 0
    
    public var beginRefreshClosure: (() -> Void)?
    
    public var endRefreshClosure: (() -> Void)?
    
    let circle = RotaryCircleView()
    
    public required init(container: UIScrollView, limit: CGFloat) {
        super.init(frame: CGRect(origin: .zero, size: .init(width: container.hq.width, height: limit)))
        addSubview(circle)
        container.insertSubview(self, at: 0)
        pullLimit = limit
        circle.center = CGPoint(x: center.x, y: -center.y)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        injectView(superView: newSuperview)
    }
    
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let k = keyPath, let c = change else { return }
        observeValueFor(keyPath: k, change: c)
    }
    
    func update(state: RefreshState, toState: RefreshState) {
        guard state != toState else { return }
        switch state {
        case .idle:
            circle.hide()
            endRefreshClosure?()
            UIView.animate(withDuration: 0.4, animations: {
                self.scrollView?.contentInset.top = self.originInset!.top
            })
        case .pulling(let delta):
            circle.show(ratio: min(delta/pullLimit, 1.0))
        case .ready:
            circle.show(ratio: 1.0)
        case .refreshing:
            circle.rotate()
            beginRefreshClosure?()
            UIView.animate(withDuration: 0.3, animations: {
                self.scrollView?.contentInset.top += self.hq.height
            })
        }
    }
}

// MARK: Footer refresh view
public class FooterRefreshView: UIView, FooterRefreshable {
    public var pullLimit: CGFloat = 0
    
    public var state: RefreshState = .idle { willSet{update(state: newValue, toState: state) }}
    
    public var originInset: UIEdgeInsets?
    
    public weak var scrollView: UIScrollView?
    
    public var beginRefreshClosure: (() -> Void)?
    
    public var endRefreshClosure: (() -> Void)?
    
    let circle = RotaryCircleView()
    
    public required init(container: UIScrollView, limit: CGFloat = 80) {
        super.init(frame: CGRect(origin: container.hq.origin, size: CGSize(width: container.hq.width, height: limit)))
        pullLimit = limit
        addSubview(circle)
        container.insertSubview(self, at: 0)
        circle.center = center
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        injectView(superView: newSuperview)
        backgroundColor = scrollView?.backgroundColor
    }

    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let k = keyPath, let c = change else { return }
        observeValueFor(keyPath: k, change: c)
    }

    func update(state: RefreshState, toState: RefreshState) {
        guard state != toState else { return }
        switch state {
        case .idle:
            circle.hide()
            endRefreshClosure?()
            UIView.animate(withDuration: 0.4, animations: {
                self.scrollView?.contentInset.bottom = self.originInset!.bottom
            })
        case .pulling(let delta):
            circle.show(ratio: min(delta/pullLimit, 1.0))
        case .ready:
            circle.show(ratio: 1.0)
        case .refreshing:
            circle.rotate()
            beginRefreshClosure?()
            UIView.animate(withDuration: 0.3, animations: {
                self.scrollView?.contentInset.bottom += self.hq.height
            })
        }
    }
}
