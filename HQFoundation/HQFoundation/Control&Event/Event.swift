//
//  Event.swift
//  HQFoundation
//
//  Created by HonQi on 2018/4/19.
//  Copyright © 2018年 HonQi Indie. All rights reserved.
//

private var EventClosureKey: UInt8 = 0
private protocol Eventable: class {
    var eventClosure: (()->Void)? { get set }
    func eventTriggerFunction()
    
}

extension Eventable {
    var eventClosure: (()->Void)? {
        set {
            objc_setAssociatedObject(self, &EventClosureKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &EventClosureKey) as? (() -> Void)
        }
    }
}

// MARK: - UIControl
extension UIControl: Eventable {
    @objc func eventTriggerFunction() {
        eventClosure?()
    }
}
extension Namespace where T : UIControl {
    public func addEvent(_ closure: (() -> Void)?, _ events: UIControlEvents) {
        instance.eventClosure = closure
        instance.addTarget(self, action: #selector(UIControl.eventTriggerFunction), for: events)
    }
}


// MARK: - UIBarButtonItem

extension UIBarButtonItem: Eventable {
    @objc func eventTriggerFunction() {
        eventClosure?()
    }
}

extension Namespace where T : UIBarButtonItem {
    public func addEvent(_ closure: (() -> Void)?) {
        instance.eventClosure = closure
        instance.target = instance
        instance.action = #selector(UIBarButtonItem.eventTriggerFunction)
    }
}


// MARK: - UIGestureRecognizer
extension UIGestureRecognizer: Eventable {
    @objc func eventTriggerFunction() {
        eventClosure?()
    }
}
extension Namespace where T: UIGestureRecognizer {
    public func addEvent(_ closure: (() -> Void)?) {
        instance.eventClosure = closure
        instance.addTarget(self, action: #selector(UIGestureRecognizer.eventTriggerFunction))
    }
}
