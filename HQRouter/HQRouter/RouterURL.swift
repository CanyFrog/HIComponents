//
//  RouterURL.swift
//  HQRouter
//
//  Created by Magee Huang on 5/11/18.
//  Copyright © 2018 HQ.components.router. All rights reserved.
//

import Foundation

protocol RouterURLProtocol: Equatable, CustomStringConvertible {}

// MARK: - Query item eg: key=value
public struct RouterURLQueryItem: RouterURLProtocol {
    public private(set) var key: String
    public private(set) var value: String?
    
    public var description: String {
        if let value = value, !value.isEmpty {
            return "\(key.addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics)!)=\(value.addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics)!)"
        }
        else {
            return key.addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics)!
        }
    }
    
    public init(key: String, value: String?) {
        self.key = key
        self.value = value
    }
    
    public init(pair: String) {
        guard !pair.isEmpty else { fatalError("Error: Router Query item string is empty") }
        var para = pair.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: true).map { String($0) }
        self.init(key: para.removeFirst(), value: para.first)
    }
}


// MARK: - Component eg: component?k1=v1;k2=v2....
public struct RouterURLComponent: RouterURLProtocol {
    
    public private(set) var path: String
    public private(set) var queryItems: [RouterURLQueryItem]?
    
    public var description: String {
        let pathSer = path.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlHostAllowed)
        guard let items = queryItems else { return pathSer! }
        return "\(pathSer!)?\(items.compactMap{ $0.description }.joined(separator: ";"))"
    }
    
    public init(path: String, queryItems: [RouterURLQueryItem]?) {
        self.path = path
        self.queryItems = queryItems
    }
    
    public init(component: String) {
        var components = component.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: true)
        guard components.count > 0 else { fatalError("Error: Router component string is empty") }
        
        let pathStr = String(components.removeFirst())
        guard let params = components.last else { self.init(path: pathStr, queryItems: nil); return }

        let items = String(params).components(separatedBy: ";").compactMap{ (item) -> RouterURLQueryItem? in
            if !item.isEmpty { return RouterURLQueryItem(pair: String(item)) }
            else { return nil }
        }
        self.init(path: pathStr, queryItems: items)
    }
    
    public static func separate(url: String) -> [RouterURLComponent] {
        let uris = url.components(separatedBy: "/")
        guard !uris.isEmpty else { return [] }
        return uris.compactMap{ RouterURLComponent(component: $0) }
    }
    
    
    /// Index
    public subscript(key: String) -> String? {
        let item = queryItems?.filter{ $0.key == key }
        return item?.first?.value
    }
    
    public subscript(key: String) -> Int? {
        let item = queryItems?.filter{ $0.key == key }
        return Int(item?.first?.value ?? "")
    }
    
    public subscript(key: String) -> Double? {
        let item = queryItems?.filter{ $0.key == key }
        return Double(item?.first?.value ?? "")
    }
    
    public subscript(key: String) -> Bool {
        let item = queryItems?.filter{ $0.key == key }
        guard let v = item?.first?.value?.lowercased() else { return false }
        return v == "true" || v == "yes" || v == "1"
    }
}

// MARK: - URL eg: scheme://component1;k1=v1;k2=v2/component2;k3=v3;...
public struct RouterURL: RouterURLProtocol {
    
    public private(set) var scheme: String
    public private(set) var components = [RouterURLComponent]()
    
    public var description: String {
        return "\(scheme)://\(components.compactMap{ $0.description }.joined(separator: "/"))"
    }
    
    public init(scheme: String, components: [RouterURLComponent]) {
        self.scheme = scheme
        self.components = components
    }
    
    public init(url: String) {
        let paths = url.components(separatedBy: "://")
        guard paths.count == 2 else { fatalError("Error: Router uri must be xxxx://xxxx") }
        
        let schemeStr = paths.first!
        let components = paths.last!.components(separatedBy: "/").compactMap { (path) -> RouterURLComponent? in
            if path.isEmpty { return nil }
            else { return RouterURLComponent(component: path) }
        }
        self.init(scheme: schemeStr, components: components)
    }
    
    
    public mutating func forward(path: [RouterURLComponent]) {
        components.append(contentsOf: path)
    }
    
    public mutating func back(steps: Int = 1) {
        components.removeLast(steps)
    }
    
    /// Compare two url, if scheme is different, return -1; otherwise return path equal count
    public func compare(other: RouterURL) -> Int {
        guard scheme == other.scheme else { return -1 }
        let count = min(components.count, other.components.count)
        for idx in 0 ..< count {
            if components[idx] != other.components[idx] {
                return idx
            }
        }
        return count
    }
    
    /// Index
    public subscript(name: String) -> RouterURLComponent? {
        return components.filter{ $0.path == name }.first
    }
}
