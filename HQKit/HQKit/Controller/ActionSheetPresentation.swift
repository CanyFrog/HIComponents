//
//  ActionSheetPresentation.swift
//  DemoApp
//
//  Created by HonQi on 9/12/18.
//  Copyright © 2018 HonQi Indie. All rights reserved.
//

import UIKit

class ActionSheetPresentation: UIPresentationController {
    var dimmingView: UIView?
    var wrapperView: UIView?
    var preferredHeight: CGFloat = UIScreen.main.bounds.height - 64
    
    /// Return the wrapping view created in -presentationTransitionWillBegin.
    override var presentedView: UIView? { return wrapperView }
    
    override func presentationTransitionWillBegin() {
        // The default implementation of presentedView returns self.presentedViewController.view
        wrapperView = {
           let wrapper = UIView(frame: frameOfPresentedViewInContainerView)
            wrapper.hq.shadow(offset: CGSize(width: 0, height: -6.0), opacity: 0.44, radius: 13.0)
            let cornerRadis: CGFloat = 16.0
            
            wrapper.addSubview({
                let rounder = UIView(frame: UIEdgeInsetsInsetRect(wrapper.bounds, UIEdgeInsetsMake(0, 0, -cornerRadis, 0)))
                rounder.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                rounder.hq.corner(radis: cornerRadis)
                
                rounder.addSubview({
                    let container = UIView(frame: UIEdgeInsetsInsetRect(rounder.bounds, UIEdgeInsetsMake(0, 0, cornerRadis, 0)))
                    container.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                    
                    container.addSubview({
                        let presentedVCView = super.presentedView
                        presentedVCView?.autoresizingMask = [.flexibleHeight, .flexibleWidth]
                        presentedVCView?.frame = container.frame
                        return presentedVCView!
                        }())

                    return container
                }())
                
                return rounder
            }())
            
            return wrapper
        }()
        
        
        dimmingView = { [weak self] in
           let dimming = UIView(frame: containerView!.bounds)
            dimming.backgroundColor = UIColor.black
            dimming.isOpaque = false
            dimming.isUserInteractionEnabled = true
            dimming.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dimmingTap)))
            return dimming
        }()
        
        containerView?.addSubview(dimmingView!)
        
        dimmingView?.alpha = 0
        presentingViewController.transitionCoordinator?.animate(alongsideTransition: { [weak self] (_) in
            self?.dimmingView?.alpha = 0.4
        }, completion: nil)
    }
    
    @objc private func dimmingTap() {
        presentedViewController.dismiss(animated: true, completion: nil)
    }
    
    open override func presentationTransitionDidEnd(_ completed: Bool) {
        guard completed else { return }
        wrapperView = nil
        dimmingView = nil
    }
    
    open override func dismissalTransitionWillBegin() {
        presentingViewController.transitionCoordinator?.animate(alongsideTransition: { [weak self] (_) in
            self?.dimmingView?.alpha = 0
        }, completion: nil)
    }
    
    open override func dismissalTransitionDidEnd(_ completed: Bool) {
        if completed {
            wrapperView = nil
            dimmingView = nil
        }
    }
    
    /// Layout
    open override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)
        if container as? UIViewController == presentedViewController {
            containerView?.setNeedsLayout()
        }
    }
    
    open override func size(forChildContentContainer container: UIContentContainer, withParentContainerSize parentSize: CGSize) -> CGSize {
        if container as? UIViewController == presentedViewController {
            var size = container.preferredContentSize
            size.height = preferredHeight
            return size
        }
        return super.size(forChildContentContainer: container, withParentContainerSize: parentSize)
    }
    
    open override var frameOfPresentedViewInContainerView: CGRect {
        let containerBounds = containerView!.bounds
        
        let presentedSize = size(forChildContentContainer: presentedViewController, withParentContainerSize: containerBounds.size)
        
        var frame = containerBounds
        frame.size.height = presentedSize.height
        frame.origin.y = containerBounds.maxY - presentedSize.height
        return frame
    }
    
    open override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        dimmingView?.frame = containerView!.bounds
        wrapperView?.frame = frameOfPresentedViewInContainerView
    }
}

extension ActionSheetPresentation: UIViewControllerAnimatedTransitioning {
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return transitionContext?.isAnimated ?? false ? 0.4 : 0
    }
    
    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        // For a Presentation:
        //      fromView = The presenting view.
        //      toView   = The presented view.
        // For a Dismissal:
        //      fromView = The presented view.
        //      toView   = The presenting view.
        
        guard let toVC = transitionContext.viewController(forKey: .to),
            let fromVC = transitionContext.viewController(forKey: .from) else { return }
        
        let completion = { (completed: Bool) in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
        
        if toVC == presentedViewController { // is presenting
            let toView = transitionContext.view(forKey: .to)! // Only presenting can get view from view(forkey:) function, this view can present in container
            let container = transitionContext.containerView
            container.addSubview(toView)
            
            let toFrame = transitionContext.finalFrame(for: toVC)
            toView.frame = CGRect(origin: .init(x: container.hq.left, y: container.hq.bottom), size: toFrame.size)
            
            UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
                toView.frame = toFrame
            }, completion: completion)
        }
        else {
            UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
                fromVC.view.frame.origin = CGPoint(x: toVC.view.hq.left, y: toVC.view.hq.bottom)
            }, completion: completion)
        }
    }
}

extension ActionSheetPresentation: UIViewControllerTransitioningDelegate {
    
    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return self
    }
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }
}
