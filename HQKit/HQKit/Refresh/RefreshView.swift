//
//  RefreshView.swift
//  HQKit
//
//  Created by Magee Huang on 5/22/18.
//  Copyright © 2018 com.personal.HQ. All rights reserved.
//

import UIKit


//public class HeaderRefreshView: UIView, HeaderRefreshable {
//
//    public var state: RefreshState = .idle { willSet { update(state: newValue) }}
//
//    public var originInset: UIEdgeInsets?
//
//    public weak var scrollView: UIScrollView?
//
//    public var pullLimit: CGFloat = 80
//
//    public var pullDelta: CGFloat = 0
//
//    public var pullPercent: CGFloat = 0
//
//    public var beginRefreshClosure: (() -> Void)?
//
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//    }
//
//    required public init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    convenience public init(container: UIScrollView) {
//        self.init(frame: .init(origin: .zero, size: .init(width: 2, height: 2)))
//        container.insertSubview(self, at: 0)
//    }
//
//
//    public func beginRefresh() {
//        center.x = scrollView!.center.x
//        state = .ready
//
//        let perMove = pullLimit / 5
//        let timeIntevel = 0.1
//
//        Timer.hq.every(interval: timeIntevel) { (timer) in
//            if self.pullDelta < self.pullLimit {
//                UIView.animate(withDuration: timeIntevel, animations: { self.scrollView?.contentOffset.y -= perMove })
//            }
//            else {
//                self.state = .refreshing
//                timer.invalidate()
//            }
//        }
//    }
//
//    public override func willMove(toSuperview newSuperview: UIView?) {
//        injectView(superView: newSuperview)
//        center.x = scrollView!.center.x
//    }
//
//    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
//        guard let k = keyPath, let c = change else { return }
//        observeValueFor(keyPath: k, change: c)
//    }
//
//    func update(state: RefreshState) {
//        switch state {
//        case .refreshing:
//            rotate()
//            beginRefreshClosure?()
//            UIView.animate(withDuration: 0.3, animations: {
//                self.scrollView?.contentInset.top = self.originInset!.top + self.pullLimit
//            })
//        case .ready:
//            guard let scroll = scrollView else { return }
//            show(ratio: pullPercent)
//            center.x = scroll.center.x
//            center.y = min(pullDelta, pullLimit) / -2
//        case .idle:
//            UIView.animate(withDuration: 0.4, animations: {
//                self.hide()
//                self.scrollView?.contentInset.top = self.originInset!.top
//            })
//        }
//    }
//}

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
        print(state)
        switch state {
        case .idle:
            circle.hide()
            endRefreshClosure?()
//            UIView.animate(withDuration: 0.4, animations: {
//                self.scrollView?.contentInset.bottom = self.originInset!.bottom
//            }) { (_) in
//
//            }
        case .pulling(let delta):
            circle.show(ratio: min(delta/pullLimit, 1.0))
        case .ready:
            circle.show(ratio: 1.0)
        case .refreshing:
            circle.rotate()
            beginRefreshClosure?()
//            UIView.animate(withDuration: 0.3, animations: {
//                self.scrollView?.contentInset.bottom += self.hq.height
//            }) { (_) in
//            }
        }
    }
}
