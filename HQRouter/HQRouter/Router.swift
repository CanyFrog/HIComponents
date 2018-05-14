//
//  Router.swift
//  HQRouter
//
//  Created by Magee Huang on 5/11/18.
//  Copyright © 2018 HQ.components.router. All rights reserved.
//

import Foundation

public enum RouterType {
    case remain
    case push
    case pop
    case reset
}

protocol Component {
    
}

struct RouterOptions: OptionSet {
    public let rawValue: UInt
    
    public static let none          = RouterOptions(rawValue: 1 << 0)
    
    public static let animated      = RouterOptions(rawValue: 1 << 1)
    
    public static let resetStack    = RouterOptions(rawValue: 1 << 2)
    
    public init(rawValue: RouterOptions.RawValue) {
        self.rawValue = rawValue
    }
}

typealias PendingTask = (uri: String, options: RouterOptions)
struct RouterTask {
    var type: RouterType = .push
    var componentUri: String?
    var targetVC: UIViewController?
    var animated: Bool = true
    var componentTranisitionDuration: TimeInterval = 0.5
    
    init() { }
}

public typealias RouterRegisterClosure = (_ component: RouterURLComponent)-> UIViewController

open class Router {
    static let `default` = Router()
    public var window: UIWindow?
    public var componentScheme: String = "component"
    public var appScheme: String = "app"
    
    private var components = [String: RouterRegisterClosure]()
    private var taskQueue = [RouterTask]()
    private var pendingTasks = [PendingTask]()
    
    
    func open(uri: String, options: RouterType = .push) {
        
    }
    
    func pop() {
        
    }
    
    
    /// Get current state serialize string
    func serializeUrls() -> String {
        return "holder"
    }
}

extension Router {
    func register(name: String, closure: @escaping RouterRegisterClosure) {
        components[name] = closure
    }
}

extension Router {
    func perform(task: PendingTask) {
        pendingTasks.append(task)
    }
    
    func nextTask() -> RouterTask? {
        guard taskQueue.isEmpty else { return taskQueue.popLast() }
        guard !pendingTasks.isEmpty else { return nil }
        
        /// Step 1: Get next task info
        let info = pendingTasks.popLast()!
        
        /// Step 2: Prepare two state's uri
        let targetUri = RouterURL.unserialize(url: info.uri)
        
        let currentUri = info.options.contains(.resetStack) ? "" : serializeUrls()
        var nextUri = targetUri.serialize()
        /// APP internel router
        if targetUri.scheme == "Component URI holder" {
            nextUri = "\(currentUri)/\(targetUri.serializeComponents())"
        }
        
        /// Step 3: Prepare the navigation task
        var pageAnimationCount = 0
        let newTasks = diffState(current: currentUri, new: nextUri)
//        newTasks.forEach { (task) in
//            task.animated = info.options.contains(.animated)
//            if task.type == .pop || task.type == .push {
//                pageAnimationCount += 1
//            }
//        }
        
        taskQueue.append(contentsOf: newTasks)
        
        return taskQueue.popLast()
    }
    
    /// Get two state different component
    func diffState(current: String, new: String) -> [RouterTask] {
        let fromStack = RouterURL.splitComponents(url: current)
        let toStack = RouterURL.splitComponents(url: new)
        
        var sameIdx = -1
        for (idx, fromUri) in fromStack.enumerated() {
            if idx >= toStack.count { break }
            
            let toUri = toStack[idx]
            if fromUri.scheme != componentScheme && fromUri == toUri && fromUri.components.count == 1 {
                sameIdx = idx
            }
            else {
                break
            }
        }
        
        /// Fill the remain stack
        let remainStack = toStack[0...sameIdx]
        
        /// Fill the close stack
        var closeStack = toStack[sameIdx+1...fromStack.count]
        
        /// Fill the open stack
        let openStack = toStack[sameIdx+1...toStack.count]

        
        /// Add open task
        var tasks = openStack.reversed().compactMap { (uri) -> RouterTask? in
            var task = RouterTask()
            task.componentUri = uri.serialize()
            task.targetVC = UIViewController()
            task.type = .push
            return task
        }
        
        /// If all task will be removed, reset the component task and close stack and convert open task to reset task
        if sameIdx == -1 && !openStack.isEmpty {
            closeStack.removeAll()
            var task = tasks.popLast()
            task?.type = .reset
            tasks.append(task!)
        }
        
        /// Add close task
        closeStack.forEach { (uri) in
            var task = RouterTask()
            task.type = .pop
            task.componentUri = uri.serialize()
            tasks.append(task)
        }
        
        /// Add remain task
        remainStack.forEach { (uri) in
            var task = RouterTask()
            task.type = .remain
            task.componentUri = uri.serialize()
            task.targetVC = UIViewController()
            tasks.append(task)
        }
        return tasks
    }
    

}
