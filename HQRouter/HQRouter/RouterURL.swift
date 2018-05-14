//
//  RouterURL.swift
//  HQRouter
//
//  Created by Magee Huang on 5/11/18.
//  Copyright © 2018 HQ.components.router. All rights reserved.
//

import Foundation

protocol RouterURLProtocol {
    func serialize() -> String
    static func unserialize(url: String) -> Self
}

// MARK: - Query item eg: key=value
public typealias RouterURLQueryItem = URLQueryItem
extension RouterURLQueryItem: RouterURLProtocol {
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


// MARK: - Component eg: component?k1=v1;k2=v2....
public struct RouterURLComponent: RouterURLProtocol, Equatable {
    public var path: String
    public var queryItems: [RouterURLQueryItem]?
    
    public func value(for name: String) -> String? {
        guard let items = queryItems, !items.isEmpty else { return "" }
        return items.filter{ $0.name == name }.first?.value
    }
    
    public func serialize() -> String {
        let pathSer = path.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlHostAllowed)
        guard let items = queryItems else { return pathSer! }
        return "\(pathSer!)?\(items.compactMap{ $0.serialize() }.joined(separator: ";"))"
    }
    
    public static func unserialize(url: String) -> RouterURLComponent {
        let components = url.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: true)
        guard components.count > 0 else { fatalError("Error: Router component string is empty") }
        
        let pathStr = components.first
        var items: [RouterURLQueryItem]? = nil
        if components.count > 1 {
            items = components.dropFirst().compactMap{ (item) -> RouterURLQueryItem? in
                if !item.isEmpty { return RouterURLQueryItem.unserialize(url: String(item)) }
                else { return nil }
            }
        }
        return RouterURLComponent(path: String(pathStr!), queryItems: items)
    }
    
    
    public subscript(name: String) -> String? {
        let item = queryItems?.filter{ $0.name == name }
        return item?.first?.value
    }
    
    public subscript(name: String) -> Int? {
        let item = queryItems?.filter{ $0.name == name }
        return Int(item?.first?.value ?? "")
    }
    
    public subscript(name: String) -> Double? {
        let item = queryItems?.filter{ $0.name == name }
        return Double(item?.first?.value ?? "")
    }
    
    public subscript(name: String) -> Bool {
        let item = queryItems?.filter{ $0.name == name }
        guard let v = item?.first?.value?.lowercased() else { return false }
        return v == "true" || v == "yes" || v == "1"
    }
}

// MARK: - URL eg: scheme://component1;k1=v1;k2=v2/component2;k3=v3;...
public struct RouterURL: RouterURLProtocol, Equatable {
    
    public var scheme: String
    public var components = [RouterURLComponent]()
    
    // MARK: - serialize
    public func serialize() -> String {
        return "\(scheme)://\(serializeComponents())"
    }
    
    public func serializeComponents() -> String {
        return components.compactMap{ $0.serialize() }.joined(separator: "/")
    }
    
    public static func splitComponents(url: String) -> [RouterURL] {
        let baseUrl = RouterURL.unserialize(url: url)
        if baseUrl.scheme == Router.default.appScheme {
            return baseUrl.components.compactMap { return RouterURL.unserialize(url: "\(Router.default.componentScheme):/\($0.serialize())" ) }
        }
        return [baseUrl]
    }
    
    static func unserialize(url: String) -> RouterURL {
        let components = url.components(separatedBy: "://")
        guard components.count == 2 else { fatalError("Error: Router uri must be xxxx://xxxx") }
        
        let schemeStr = components.first!
        let paths = components.last!.components(separatedBy: "/").compactMap { (path) -> RouterURLComponent? in
            if path.isEmpty { return nil }
            else { return RouterURLComponent.unserialize(url: path) }
        }
        
        return RouterURL(scheme: schemeStr, components: paths)
    }
    
    public subscript(name: String) -> RouterURLComponent? {
        return components.filter{ $0.path == name }.first
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
