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
    
    var components = [String: RegisterComponentClosure]()
    
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


open class Router {
    
    /// Url scheme
    public var scheme: String { return mainUrl.scheme }
    
    public private(set) weak var navigator: UINavigationController?

    public private(set) var mainUrl: RouterURL
    
    private var isTransitionInProgress: Bool = false
    
    /// Tasks and components
    private var pendingTasks = [RouterURLComponent]()
    private var finishedTasks = [Component]()
    
    public init(scheme: String, navigator: UINavigationController) {
        self.mainUrl = RouterURL(scheme: "\(scheme)://", components: [])
        self.navigator = navigator
    }
}

extension Router {
    
    /// Open new url, if has old url, will compare two url and execute new task
    public func open(url: String, animated: Bool = true, mode: RouterNavigateMode = .push) {
        let newUrl = RouterURL(url: url)
        guard newUrl.scheme == scheme else { fatalError("New url scheme is error, must be equal \(scheme)") }
        
        pendingTasks.append(contentsOf: newUrl.components)
        
        let idx = mainUrl.compare(other: newUrl)
        
        /// reset stack
        if idx == -1 { executeResetTask() }
        
        /// Update the remain componet state
        if idx > 0 { executeRemianTask(index: idx) }
        
        /// Close different component
        if !finishedTasks.isEmpty && idx + 1 < finishedTasks.count {
            executeCloseTask(count: finishedTasks.count - idx - 1)
        }
        
        /// Open new component
        executeOpenTask(animated: animated, mode: mode)
        
        mainUrl = newUrl
    }
    
    public func forward(component: String, animated: Bool = true, mode: RouterNavigateMode = .push) {
        let paths = RouterURLComponent.separate(url: component)
        guard !paths.isEmpty else { fatalError("Forward path is wrong \(component)") }
        pendingTasks.append(contentsOf: paths)
        executeOpenTask(animated: animated, mode: mode)

        mainUrl.components.append(contentsOf: paths)
    }
    
    public func back(steps: Int = 1, animated: Bool = true) {
        mainUrl.components.removeLast(steps)
        executeCloseTask(count: steps)
    }
    
    public func home(animated: Bool = true) {
        back(steps: mainUrl.components.count - 1, animated: animated)
    }
}


extension Router {
    private func executeOpenTask(animated: Bool, mode: RouterNavigateMode) {
        while !pendingTasks.isEmpty {
            let url = pendingTasks.removeFirst()
            guard let component = RouterConfigs.default[url] else {
                // 404
                return
            }
            finishedTasks.last?.componentWillInactive()
            
            component.componentWillMount()
            component.navigateMode = finishedTasks.isEmpty ? .none : mode
            component.urlComponent = url
            component.router = self
            component.componentWillActive()
            
            if component.navigateMode == .push {
                push(component: component, animated: animated, reset: finishedTasks.isEmpty)
            }
            else {
                present(component: component, animated: animated)
            }
            
            finishedTasks.append(component)
        }
    }

    private func executeCloseTask(count: Int) {
        var times = count
        while times > 0 {
            guard let component = finishedTasks.popLast() else { return }
            component.componentWillInactive()
            
            if component.navigateMode == .push {
                pop(component: component, animated: count == 1)
            }
            else {
                dismiss(component: component, animated: count == 1)
            }
            
            component.componentWillUnmount()
            finishedTasks.last?.componentWillActive()
            times -= 1
        }
        //        component?.rootViewController.pageTransitionDuration = task.
    }

    private func executeRemianTask(index: Int) {
        // Update target vc state and execute next task
        guard index > 0 else { return }
        for i in 0 ... index {
            finishedTasks[i].urlComponent = pendingTasks.removeFirst()
        }
    }

    private func executeResetTask() {
        while let component = finishedTasks.popLast() {
            component.componentWillInactive()
            component.componentWillUnmount()
        }
        
        // Dismiss all presented VC
        navigator?.presentedViewController?.dismiss(animated: false, completion: nil)
        navigator?.setViewControllers([], animated: false)
    }
}

extension Router {
    func push(component: Component, animated: Bool, reset: Bool) {
        component.navigateMode = .push
        let vc = component.viewController
        if reset {
            navigator?.setViewControllers([vc], animated: animated)
        }
        else {
            navigator?.pushViewController(vc, animated: animated)
        }
    }

    func pop(component: Component, animated: Bool) {
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

    func present(component: Component, animated: Bool) {
        //        component.navigateMode = .present
        var pController = UIApplication.shared.keyWindow?.rootViewController // current VC
        while pController?.presentedViewController != nil {
            pController = pController?.presentedViewController
        }
        pController?.present(component.viewController, animated: animated, completion: nil)
    }

    func dismiss(component: Component, animated: Bool) {
        component.viewController.dismiss(animated: animated, completion: nil)
    }
}
