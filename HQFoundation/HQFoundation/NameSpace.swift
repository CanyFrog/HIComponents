//
//  NameSpace.swift
//  HQFoundation
//
//  Created by HonQi on 5/14/18.
//  Copyright © 2018 HonQi Indie. All rights reserved.
//

import Foundation

public protocol Namespaceable {
    associatedtype WrapperType
    var hq: WrapperType { get }
    static var hq: WrapperType.Type { get }
}

public extension Namespaceable {
    var hq: Namespace<Self> { return Namespace(value: self) }
    static var hq: Namespace<Self>.Type { return Namespace.self }
}

public struct Namespace<T> {
    public let instance: T
    public init(value: T) { self.instance = value }
}
