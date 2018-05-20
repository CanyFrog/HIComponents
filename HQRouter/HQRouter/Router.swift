//
//  Router.swift
//  HQRouter
//
//  Created by Magee Huang on 5/11/18.
//  Copyright © 2018 HQ.components.router. All rights reserved.
//

import Foundation

public typealias RegisterComponentClosure = (_ component: RouterURLComponent)-> Component

public enum RouterNavigateMode: String {
    case none       // Component is not presented or pushed in Main window, the initial state of Component
    case push       // Componnet is pushed in main window
    case present    // Component is presented in main window
}

public class RouterConfigs {
    public static let `default` = RouterConfigs()
    
    private var components = [String: RegisterComponentClosure]()
    
    public func register(name: String, closure: @escaping RegisterComponentClosure) {
        components[name] = closure
    }
    
    public subscript(name: String) -> RegisterComponentClosure? {
        return components[name]
    }
    
    public subscript(urlComponent: RouterURLComponent) -> Component? {
        let closure = components[urlComponent.path]
        return closure?(urlComponent)
    }
    
    private init() {}
}


open class Router: NSObject {
    
    /// Url scheme
    public var scheme: String { return mainUrl.scheme }
    
    public private(set) weak var navigator: UINavigationController?

    public private(set) var mainUrl: RouterURL!
    
    private var isTransitionInProgress: Bool = false
    
    /// Tasks and components
    private var finishedTasks = [Component]()
    
    private enum TaskOperation { case remain, reset, close, open(RouterNavigateMode)}
    private typealias Task = (TaskOperation, RouterURLComponent?, Bool)
    private var pendingTasks = [Task]()
    
    
    public init(uri: String, navigator: UINavigationController) {
        super.init()
        guard let scheme = uri.components(separatedBy: "://").first else {
            fatalError("Uri must be xxxx://xxxxx")
        }
        mainUrl = RouterURL(url: scheme)
        navigator.delegate = self
        self.navigator = navigator
        open(url: uri)
    }
}

extension Router {
    
    /// Open new url, if has old url, will compare two url and execute new task
    /// if need open multi component and animated is true, only for last animation
    public func open(url: String, mode: RouterNavigateMode = .push, animated: Bool = true) {
        let newUrl = RouterURL(url: url)
        guard newUrl.scheme == scheme else { fatalError("New url scheme is error, must be equal \(scheme)") }
        
        let idx = mainUrl.compare(other: newUrl)
        mainUrl = newUrl
        
        /// reset stack
        if idx < 1 { pendingTasks.append((.reset, nil, false))}
        else {
            /// Update the remain componet state
            pendingTasks.append(contentsOf: mainUrl.components[0...idx].compactMap{ (.remain, $0, false) })
            
            /// Close different component
            pendingTasks.append(contentsOf: mainUrl.components[idx...finishedTasks.count].compactMap{ (.close, $0, animated) })
        }
        
        /// Open new component
        pendingTasks.append(contentsOf: mainUrl.components[idx...].compactMap{ (.open(mode), $0, animated) })
        
        executeTask()
    }
    
    /// if need open multi component and animated is true, only for last animation
    public func forward(component: String, mode: RouterNavigateMode = .push, animated: Bool = true) {
        let paths = RouterURLComponent.separate(url: component)
        guard !paths.isEmpty else { fatalError("Forward path is wrong \(component)") }
        mainUrl.forward(path: paths)
        pendingTasks.append(contentsOf: paths.compactMap({ (path) -> Task? in
            return (.open(mode), path, animated)
        }))
        
        executeTask()
    }
    
    public func back(animated: Bool = true, steps: Int = 1) {
        let paths = mainUrl.back(steps: steps)
        pendingTasks.append(contentsOf: paths.compactMap{ (.close, $0, animated) })
        
        executeTask()
    }
    
    public func home(animated: Bool = true) {
        back(animated: animated, steps: mainUrl.components.count - 1)
    }
}


extension Router {
    
    private func asyncExecuteNextTask() {
        isTransitionInProgress = false
        DispatchQueue.main.async { self.executeTask() }
    }
    
    private func executeTask() {
        guard !isTransitionInProgress && !pendingTasks.isEmpty else { return }
        var task = pendingTasks.removeFirst()
        
        isTransitionInProgress = true
        // Only last task can animation
        if !pendingTasks.isEmpty { task.2 = false }
        switch task.0 {
        case .reset:
            executeResetTask(task: task)
        case .remain:
            executeRemianTask(task: task)
        case .close:
            executeCloseTask(task: task)
        case .open(let mode):
            executeOpenTask(task: task, mode: mode)
        }
    }
    
    private func executeResetTask(task: Task) {
        guard !finishedTasks.isEmpty else {
            asyncExecuteNextTask()
            return
        }
        while let component = finishedTasks.popLast() {
            component.componentWillInactive()
            component.componentWillUnmount()
        }
        
        // Dismiss all presented VC
        navigator?.presentedViewController?.dismiss(animated: false, completion: nil)
        navigator?.setViewControllers([], animated: false)
    }
    
    private func executeRemianTask(task: Task) {
        // Update target vc state and execute next task
        asyncExecuteNextTask()
    }
    
    private func executeCloseTask(task: Task) {
        guard let component = finishedTasks.popLast() else { return }
        component.componentWillInactive()
        if component.navigateMode == .push {
            pop(component: component, animated: task.2)
        }
        else {
            dismiss(component: component, animated: task.2)
        }
        component.componentWillUnmount()
        finishedTasks.last?.componentWillActive()
    }

    
    private func executeOpenTask(task: Task, mode: RouterNavigateMode) {
        guard let url = task.1, let component = RouterConfigs.default[url] else {
            // 404
            return
        }
        finishedTasks.last?.componentWillInactive()
        
        component.componentWillMount()
        component.uid = UUID().uuidString
        component.navigateMode = mode
        component.urlComponent = url
        component.router = self
        component.componentWillActive()
        
        if mode == .push {
            push(component: component, animated: task.2)
        }
        else if mode == .present {
            present(component: component, animated: task.2)
        }
        else {
            navigator?.setViewControllers([component.viewController], animated: task.2)
        }
        
        finishedTasks.append(component)
    }
}

extension Router {
    private func push(component: Component, animated: Bool) {
        navigator?.pushViewController(component.viewController, animated: animated)
    }

    private func pop(component: Component, animated: Bool) {
        guard navigator != nil else { fatalError("Navigator is deinit") }
        precondition(navigator!.viewControllers.contains(component.viewController), "NavigationStack is error")

        // find previous view controller before component
        var index = 0
        for idx in 0 ..< navigator!.viewControllers.count {
            if navigator?.viewControllers[idx] == component.viewController {
                index = idx
                break
            }
        }

        if(index == 0) {
            navigator?.setViewControllers([], animated: animated)
        } else {
            // dismiss all view controller until Componernt's rootViewController is dismissed
            navigator?.popToViewController(navigator!.viewControllers[index-1], animated: animated)
        }
    }

    private func present(component: Component, animated: Bool) {
        var pController = UIApplication.shared.keyWindow?.rootViewController // current VC
        while pController?.presentedViewController != nil {
            pController = pController?.presentedViewController
        }
        pController?.present(component.viewController, animated: animated, completion: {
            self.asyncExecuteNextTask()
        })
    }

    private func dismiss(component: Component, animated: Bool) {
        component.viewController.dismiss(animated: animated) {
            self.asyncExecuteNextTask()
        }
    }
}

extension Router: UINavigationControllerDelegate {
    public func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        asyncExecuteNextTask()
    }
}
