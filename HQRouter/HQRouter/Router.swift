//
//  Router.swift
//  HQRouter
//
//  Created by Magee Huang on 5/11/18.
//  Copyright © 2018 HQ.components.router. All rights reserved.
//

import Foundation

struct RouterTask {
    enum Operate {
        case push
        case pop
        case remain
        case reset
    }
    
    var operate: Operate = .push
    var componentUrl: RouterURL
}

struct RouterTaskQueue {
    private var queue = [RouterTask]()
    
    mutating func insert(uri: String) {
        // Step 1: Check url scheme
        let newUrl = RouterURL.unserialize(url: uri)
        let router = Router.default
        guard newUrl.scheme == router.appScheme || newUrl.scheme == router.componentScheme else {
            fatalError("Error: new url scheme must be app scheme or component scheme!")
        }
        
        // Step 2: Prepare two state url
        let fromAppUri = router.serialize()
        var toAppUri = newUrl.serialize()
        if newUrl.scheme == Router.default.componentScheme {
            toAppUri = "\(fromAppUri)/\(newUrl.serializeComponents())"
        }
        
        // Step 3: Compare two state, pick up and set task operation
        /// split url to multi component
        let fromTasks = RouterURL.splitComponents(url: fromAppUri)
        let toTasks = RouterURL.splitComponents(url: toAppUri)
        
        var sameIdx = -1
        for (idx, fromUri) in fromTasks.enumerated() {
            if idx >= toTasks.count { break }
            
            let toUri = toTasks[idx]
            if fromUri.scheme == router.componentScheme && fromUri.components.count == 1 && fromUri == toUri {
                // If two uri is equal, sameIdx ++
                sameIdx = idx
            }
            else {
                break
            }
        }
        
        
        // Step 4: Prepare to open / close / remain tasks
        
        /// Fill the open tasks
        if sameIdx + 1 < toTasks.count {
            toTasks[sameIdx+1 ..< toTasks.count].reversed().forEach { (taskUrl) in
                // if no vc, 404 not found
                self.queue.append(RouterTask(operate: .push, componentUrl: taskUrl))
            }
        }
        
        // No same task, reset satck and reopen new stack
        if sameIdx == -1 && sameIdx+1 < toTasks.count {
            // Setting last task type reset
            var task = queue.popLast()!
            task.operate = .reset
            queue.append(task)
            return
        }
        
        /// Fill the close stack
        if sameIdx + 1 < fromTasks.count {
            fromTasks[sameIdx+1 ..< fromTasks.count].forEach { (taskUrl) in
                self.queue.append(RouterTask(operate: .pop, componentUrl: taskUrl))
            }
        }
        
        /// Fill the remain stack
        if sameIdx > 0 {
            toTasks[0 ... sameIdx].reversed().forEach { (taskUrl) in
                self.queue.append(RouterTask(operate: .remain, componentUrl: taskUrl))
            }
        }
    }
    
    mutating func next() -> RouterTask? {
        return queue.popLast()
    }
}

//struct RouterOptions: OptionSet {
//    public let rawValue: UInt
//
//    public static let none          = RouterOptions(rawValue: 1 << 0)
//
//    public static let animated      = RouterOptions(rawValue: 1 << 1)
//
//    public static let resetStack    = RouterOptions(rawValue: 1 << 2)
//
//    public init(rawValue: RouterOptions.RawValue) {
//        self.rawValue = rawValue
//    }
//}

//typealias PendingTask = (uri: String, options: RouterOptions)

typealias RouterComponentList = [String: UIViewController]
public typealias RouterRegisterClosure = (_ component: RouterURLComponent)-> UIViewController

open class Router {
    static let `default` = Router()
    
    public var componentScheme: String = "component"
    public var appScheme: String = "app"
    public var window = UIApplication.shared.keyWindow
    
    private var taskQueue = RouterTaskQueue()
    private var registeredComponents = [String: RouterRegisterClosure]()
    private var url: RouterURL!
    private var isTransitionInProgress = false
    
    
    func open(url: String) {
        precondition(Thread.current == Thread.main, "Open event must be invoked in main thread!")
        precondition(!RouterURL.unserialize(url: url).components.isEmpty, "Can not open a empty url: \(url)")
        taskQueue.insert(uri: url)
        if !isTransitionInProgress { // Previous task executed completed
            executeNextTask()
        }
    }
    
    func pop() {
        
    }
    
    
    /// Get current state serialize string
    func serialize() -> String {
        return "holder"
    }
}

extension Router {
    func register(name: String, closure: @escaping RouterRegisterClosure) {
        registeredComponents[name] = closure
    }
}

extension Router {
    func executeNextTask() {
        precondition(!isTransitionInProgress, "Only when the previous navigation tranisition task is completed, we can perform next navigation task!!!")
        guard let task = taskQueue.next() else { return }
        switch task.operate {
        case .push:
            executePushTask()
        case .pop:
            executePopTask()
        case .remain:
            executeRemianTask()
        case .reset:
            executeResetTask()
        }
    }
    
    func executePushTask() {
        // If push
        window?.rootViewController?.navigationController?.setViewControllers([], animated: true)
        
        window?.rootViewController?.navigationController?.pushViewController(UIViewController(), animated: true)
    }
    
    func executePopTask() {
        
    }
    
    func executeRemianTask() {
        // Update target vc state and execute next task
        
        DispatchQueue.main.async {
            self.executeNextTask()
        }
    }
    
    func executeResetTask() {

    }
}
