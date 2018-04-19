//
//  HQConvenienceAction.swift
//  HQFoundation
//
//  Created by Qi on 2018/4/19.
//  Copyright © 2018年 HQ.Personal.modules. All rights reserved.
//

private var eventClosureKey: UInt8 = 0
private protocol HQActionClosureProtocol: class {
    var eventClosure: (()->Void)? { get set }
    func eventTriggerFunction()
    
}

extension HQActionClosureProtocol {
    var eventClosure: (()->Void)? {
        set {
            objc_setAssociatedObject(self, &eventClosureKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &eventClosureKey) as? (() -> Void)
        }
    }
}

extension UIControl: HQActionClosureProtocol {
    @objc func eventTriggerFunction() {
        eventClosure?()
    }
    
    public func addEvent(_ closure: (() -> Void)?, _ events: UIControlEvents) {
        eventClosure = closure
        addTarget(self, action: #selector(UIControl.eventTriggerFunction), for: events)
    }
}

extension UIBarButtonItem: HQActionClosureProtocol {
    @objc func eventTriggerFunction() {
        eventClosure?()
    }
    
    public func addEvent(_ closure: (() -> Void)?) {
        eventClosure = closure
        target = self
        action = #selector(eventTriggerFunction)
    }
}

extension UIGestureRecognizer: HQActionClosureProtocol {
    @objc func eventTriggerFunction() {
        eventClosure?()
    }
    
    public func addEvent(_ closure: (() -> Void)?) {
        eventClosure = closure
        addTarget(self, action: #selector(eventTriggerFunction))
    }
}
