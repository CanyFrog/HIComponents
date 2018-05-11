//
//  RouterURL.swift
//  HQRouter
//
//  Created by Magee Huang on 5/11/18.
//  Copyright © 2018 HQ.components.router. All rights reserved.
//

import Foundation

//enum ValueType {
//    case String
//    case Int
//    case Float
//    case Long
//    case Double
//    case Bool
//    case Enum(String)
//    case Struct(String)
//    case Object(String)
//}


protocol RouterURIProtocol {
    func serialize() -> String
    static func unserialize(url: String) -> Self
}


// MARK: - Query item eg: key=value
public typealias RouterURLQueryItem = URLQueryItem
extension RouterURLQueryItem: RouterURIProtocol {
    public func serialize() -> String {
        if let value = value, !value.isEmpty {
            return "\(name.addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics)!)=\(value.addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics)!)"
        }
        else {
            return name.addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics)!
        }
    }
    
    public static func unserialize(url: String) -> RouterURLQueryItem {
        guard !url.isEmpty else { fatalError("Error: Router Query item string string is empty") }
        let pairs = url.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: true).map { String($0) }
        return RouterURLQueryItem(name: pairs.first!, value: pairs.last ?? "")
    }
}


// MARK: - Component eg: component;k1=v1;k2=v2....
public struct RouterURLComponent: RouterURIProtocol, Equatable {
    public var path: String
    public var queryItems: [RouterURLQueryItem]?
    
    public func value(for name: String) -> String? {
        guard let items = queryItems, !items.isEmpty else { return "" }
        return items.filter{ $0.name == name }.first?.value
    }
    
    public func serialize() -> String {
        let pathSer = path.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlHostAllowed)
        guard let items = queryItems else { return pathSer! }
        return "\(pathSer!);\(items.compactMap{ $0.serialize() }.joined(separator: ";"))"
    }
    
    public static func unserialize(url: String) -> RouterURLComponent {
        let components = url.components(separatedBy: ";")
        guard components.count > 0 else { fatalError("Error: Router component string is empty") }
        
        let pathStr = components.first
        var items: [RouterURLQueryItem]? = nil
        if components.count > 1 {
            items = components.dropFirst().compactMap{ (item) -> RouterURLQueryItem? in
                if !item.isEmpty { return RouterURLQueryItem.unserialize(url: item) }
                else { return nil }
            }
        }
        return RouterURLComponent(path: pathStr!, queryItems: items)
    }
}

// MARK: - Component url pattern eg: component;<key1Name:int>;<key2Name:string>....
public typealias RouterURLComponentPattern = RouterURLComponent
extension RouterURLComponentPattern {
    //    public
}

// MARK: - URL eg: scheme:/component1;k1=v1;k2=v2/component2;k3=v3;...
public struct RouterURL: RouterURIProtocol, Equatable {
    
    public var scheme: String
    public var components = [RouterURLComponent]()
    
    // MARK: - serialize
    public func serialize() -> String {
        let componentPaths = components.compactMap{ $0.serialize() }.joined(separator: "/")
        return "\(scheme):/\(componentPaths)"
    }
    
    static func unserialize(url: String) -> RouterURL {
        let components = url.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: true)
        guard components.count == 2 else { fatalError("Error: Router uri must be xxxx:/xxxx") }
        
        let schemeStr = String(components.first!)
        let paths = components.last!.components(separatedBy: "/").compactMap { (path) -> RouterURLComponent? in
            if path.isEmpty { return nil }
            else { return RouterURLComponent.unserialize(url: path) }
        }
        
        return RouterURL(scheme: schemeStr, components: paths)
    }
    
    public mutating func forward(path: String, parameters: [String: String]) -> RouterURL {
        let items = parameters.compactMap { (name, value) -> RouterURLQueryItem? in
            return RouterURLQueryItem(name: name, value: value)
        }
        let component = RouterURLComponent(path: path, queryItems: items)
        self.components.append(component)
        return self
    }
    
    public mutating func back(_ steps: Int = 1) -> RouterURL {
        self.components.removeLast(steps)
        return self
    }
    
    public mutating func home() -> RouterURL {
        self.components.removeLast(self.components.count-1)
        return self
    }
}
