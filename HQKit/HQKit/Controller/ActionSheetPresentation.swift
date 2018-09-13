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

//        let pan = UIScreenEdgePanGestureRecognizer()
//        pan.hq.addEvent { [weak pan] in
//            
//        }
//        wrapperView?.addGestureRecognizer(<#T##gestureRecognizer: UIGestureRecognizer##UIGestureRecognizer#>)
        
        
        dimmingView = {
           let dimming = UIView(frame: containerView!.bounds)
            dimming.backgroundColor = UIColor.black
            dimming.isOpaque = false
            
            let tap = UITapGestureRecognizer()
            dimming.addGestureRecognizer(tap)
            tap.hq.addEvent({ [weak self] in
                self?.presentingViewController.dismiss(animated: true, completion: nil)
            })
            return dimming
        }()
        
        containerView?.addSubview(dimmingView!)
        
        dimmingView?.alpha = 0
        presentingViewController.transitionCoordinator?.animate(alongsideTransition: { [weak self] (_) in
            self?.dimmingView?.alpha = 0.5
        }, completion: nil)
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
            return container.preferredContentSize
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

extension ActionSheetController: UIViewControllerAnimatedTransitioning {
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return transitionContext?.isAnimated ?? false ? 0.35 : 0
    }
    
    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let fromVC = transitionContext.viewController(forKey: .from)!
        let toVC = transitionContext.viewController(forKey: .to)!
        
        let container = transitionContext.containerView
        
        let toView = transitionContext.view(forKey: .to)!
        let fromView = transitionContext.view(forKey: .from)!
        
        let isPresented = fromVC == presentedViewController

        var fromVFinalFrame = transitionContext.finalFrame(for: fromVC)
        
        var toVInitFrame = transitionContext.initialFrame(for: toVC)
        let toVFinalFrame = transitionContext.finalFrame(for: toVC)
        
        container.addSubview(toView)
        
        if isPresented {
            toVInitFrame.origin = CGPoint(x: container.bounds.minX, y: container.bounds.maxY)
            toVInitFrame.size = toVFinalFrame.size
            toView.frame = toVInitFrame
        }
        else {
            fromVFinalFrame = fromView.frame.offsetBy(dx: 0, dy: fromView.frame.height)
        }
        
        let duration = transitionDuration(using: transitionContext)
        UIView.animate(withDuration: duration, animations: {
            if isPresented {
                toView.frame = toVFinalFrame
            }
            else {
                fromView.frame = fromVFinalFrame
            }
        }) { (_) in
            transitionContext.completeTransition(transitionContext.transitionWasCancelled)
        }
    }
}

extension ActionSheetPresentation: UIViewControllerTransitioningDelegate {
    
    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return self
    }
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self as? UIViewControllerAnimatedTransitioning
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self as? UIViewControllerAnimatedTransitioning
    }
}
