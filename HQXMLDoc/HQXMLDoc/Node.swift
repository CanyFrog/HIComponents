//
//  Node.swift
//  HQXMLDoc
//
//  Created by HonQi on 8/16/18.
//  Copyright © 2018 HonQi Indie. All rights reserved.
//

import libxml2

public class Node {
    let nodePtr: xmlNodePtr
    
    /// common
    public var name: String { return String(cString: nodePtr.pointee.name) }
    public var lineNumber: Int { return Int(xmlGetLineNo(nodePtr)) }
    public lazy var isBlank = self.content.count == 0
    
    
    /// content
    /// contains all child string
    public var content: String {
        guard let c = xmlNodeGetContent(self.nodePtr) else { return "" }
        defer { xmlFree(c) }; return String(cString: c)
    }
    
    public var rawStringValue: String? {
        guard let content = nodePtr.pointee.content else { return nil }
        return String(cString: content)
    }
    
    public var stringValue: String? { return rawStringValue?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
    
    /// contains tag name
    public var htmlString: String? {
        guard let buffer = xmlBufferCreate() else { return nil }
        xmlNodeDump(buffer, nodePtr.pointee.doc, nodePtr, 0, 0)
        defer { xmlBufferFree(buffer) }
        return String(cString: xmlBufferContent(buffer))
    }
    
    
    /// relationship chain
    public var parent: Node? { return Node(nodePtr: nodePtr.pointee.parent) }
    public var prevSibling: Node? { return Node(nodePtr: nodePtr.pointee.prev) }
    public var nextSibling: Node? { return Node(nodePtr: nodePtr.pointee.next) }
    public var firstChild: Node? { return Node(nodePtr: nodePtr.pointee.children) }
    public var lastChild: Node? { return Node(nodePtr: nodePtr.pointee.last) }
    public var childCount: Int { return Int(xmlChildElementCount(nodePtr)) }
    public var children: [Node] {
        var arr = [Node]()
        var child = nodePtr.pointee.children
        while let c = child, xmlNodeIsText(c) == 0 {
            arr.append(Node(nodePtr: c))
            child = c.pointee.next
        }
        return arr
    }
    
    public func child(at idx: Int) -> Node? {
        let arr = children
        return idx < arr.count ? arr[idx] : nil
    }

    
    /// attribute
    public var attributes: [String: String] {
        var dicts = [String: String]()
        var props = nodePtr.pointee.properties
        while let p = props {
            if let c = xmlGetProp(nodePtr, p.pointee.name) {
                dicts[String(cString: p.pointee.name)] = String(cString: c)
                xmlFree(c)
            }
            props = p.pointee.next
        }
        return dicts
    }
    
    public func attribute(for name: String) -> String? {
        let xmlstr = name.utf8CString.map { xmlChar(bitPattern: $0) }
        return xmlstr.withUnsafeBufferPointer {
            if let attrValue = xmlGetProp(nodePtr, $0.baseAddress!) {
                let value = String(cString: attrValue)
                xmlFree(attrValue)
                return value
            }
            return nil
        }
    }
    
    
    /// type
    public var isAttributeNode: Bool { return nodePtr.pointee.type == xmlElementType(rawValue: 2) }
    public var isDocumentNode: Bool { return nodePtr.pointee.type == xmlElementType(rawValue: 13) }
    public var isElementNode: Bool { return nodePtr.pointee.type == xmlElementType(rawValue: 1) }
    public var isTextNode: Bool { return nodePtr.pointee.type == xmlElementType(rawValue: 3) }
    
    
    init(nodePtr: xmlNodePtr) {
        self.nodePtr = nodePtr
    }

    deinit {
//        xmlFreeNode(nodePtr)
    }
}

extension Node {
    public func xpath(_ path: String) -> [Node]? {
        guard let context = xmlXPathNewContext(nodePtr.pointee.doc) else { return nil }
        defer { xmlXPathFreeContext(context) }
        context.pointee.node = nodePtr
        
        guard let xpathPtr = xmlXPathEvalExpression(path, context) else { return nil }
        defer { xmlXPathFreeObject(xpathPtr) }

        guard let val = xpathPtr.pointee.nodesetval,
            let tab = val.pointee.nodeTab else { return nil }
        
        var nodes = [Node]()
        for idx in 0 ..< Int(val.pointee.nodeNr) {
            if let ptr = tab[idx] {
                nodes.append(Node(nodePtr: ptr))
            }
        }
        return nodes
    }
}


extension Node: CustomStringConvertible {
    public var description: String { return htmlString ?? "" }
}

extension Node: Equatable {
    public static func == (lhs: Node, rhs: Node) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

extension Node: Hashable {
    public var hashValue: Int {
        return nodePtr.hashValue
    }
}

extension Node: IteratorProtocol {
    public typealias Element = Node
    public func next() -> Node? {
        return nextSibling
    }
}
