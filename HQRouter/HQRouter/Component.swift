//
//  Component.swift
//  HQRouter
//
//  Created by Magee Huang on 5/17/18.
//  Copyright © 2018 HQ.components.router. All rights reserved.
//

import Foundation

public enum NavigateMode {
    case none       // Component is not presented or pushed in Main window, the initial state of Component
    case push       // Componnet is pushed in main window
    case present    // Component is presented in main window
}

public protocol Component: class {
    /// Component's unqiue identifier
    var uid: String! { get set }
    
    /// Component's uri
    var urlComponent: RouterURLComponent! { get set }
    
    /// Router object
    var router: Router? { get set }
    
    /// Component instance's navigate mode
    var navigateMode: RouterNavigateMode { get set }
    
    /// Component's main entry UIViewController
    var viewController: UIViewController { get set }
    
    /// Component's data provider
    var dataProvider: DataProvider { get set }
    
    
    /// componentWIllMount() is invoked immediately before a component is mounted into component hierarchy tree
    /// At that moment, perform any necessarily initialize things, setup component's state. Just remember the componentWillMount is only called once during the component lifecycle.
    /// Avoid introducing any UI rendering related things in this methods.
    func componentWillMount()
    
    /// componetWillUmount() is invoked before a component is umounted from the component hierarchy tree.
    /// At that moment, perform any necessary cleanup for the component at this method, such as invalidating timers, cancelling network requests, cleanup used resources.
    /// This method is only called once during the component's while lifecycle.
    func componentWillUnmount()
    
    /// componentWillActive() is invoked before a component is presented at top of the component hierarchy tree.
    /// Use this as an opportunity to operate any things when the component is active for user
    func componentWillActive()
    
    /// componentWillInactive is invoked before a component is no more at the top of the component hierarchy tree.
    /// There're two cases
    ///     1) The component is removed from the hierarchy tree.
    ///     2) Another component is pushed into the tree, the component is at the second top of the tree.
    func componentWillInactive()
}

extension Component {
    public func componentWillMount() {}
    public func componentWillUnmount() {}
    public func componentWillActive() {}
    public func componentWillInactive() {}
}
