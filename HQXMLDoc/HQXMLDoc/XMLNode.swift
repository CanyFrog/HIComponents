//
//  XMLNode.swift
//  HQXMLDoc
//
//  Created by HonQi on 8/16/18.
//  Copyright © 2018 HonQi Indie. All rights reserved.
//

import libxml2

public class XMLNode {
    var nodePtr: xmlNodePtr
    weak var doc: XMLDocument?
    
    public lazy var name = String(cString: self.nodePtr.pointee.name)
    public lazy var lineNumber = Int(xmlGetLineNo(self.nodePtr))
    
    public lazy var attributes: [String: String] = {
        var attrs = [String: String]()
        var cursor = self.nodePtr.pointee.properties
        while let attr = cursor {
            let key = String(cString: attr.pointee.name)
            attrs[key] = self[key]
            cursor = attr.pointee.next
        }
        return attrs
    }()
    
    public lazy var children: [XMLNode] = {
        var arr = [XMLNode]()
        var childPtr = nodePtr.pointee.children
        while let ptr = childPtr {
            if ptr.pointee.type == XML_ELEMENT_NODE {
                arr.append(XMLNode(nodePtr: ptr, doc: self.doc!))
            }
            childPtr = ptr.pointee.next
        }
        return arr
    }()
    
    public lazy var parent: XMLNode? = {
        guard let d = self.doc, let p = self.nodePtr.pointee.parent else { return nil }
        return XMLNode(nodePtr: p, doc: d)
    }()
    
    public lazy var prevSibling: XMLNode? = {
        guard let d = self.doc, let p = self.nodePtr.pointee.prev else { return nil }
        return XMLNode(nodePtr: p, doc: d)
    }()
    
    public lazy var nextSibling: XMLNode? = {
        guard let d = self.doc, let n = self.nodePtr.pointee.next else { return nil }
        return XMLNode(nodePtr: n, doc: d)
    }()
    
    public lazy var isBlank = self.content.count == 0
    
    public lazy var content: String = {
        guard let c = xmlNodeGetContent(self.nodePtr) else { return "" }
        defer { xmlFree(c) }; return String(cString: c)
    }()
    
    public lazy var path: String = {
        guard let x = xmlGetNodePath(self.nodePtr) else { return "" }
        defer { xmlFree(x) }; return String(cString: x)
    }()
    
    init(nodePtr: xmlNodePtr, doc: XMLDocument) {
        self.nodePtr = nodePtr
        self.doc = doc
    }
    
    public subscript<V>(key: String) -> V? {
        guard let data = key.data(using: .utf8, allowLossyConversion: false),
            let xmlValue = xmlGetProp(nodePtr, [UInt8](data)) else { return nil }
        defer { free(xmlValue) }
        return String(cString: xmlValue) as? V
    }
    
    public subscript(set: IndexSet) -> [XMLNode] {
        var children = [XMLNode]()
        var idx = 0
        var childPtr = nodePtr.pointee.children
        while let ptr = childPtr {
            if set.contains(idx) && ptr.pointee.type == XML_ELEMENT_NODE {
                children.append(XMLNode(nodePtr: ptr, doc: doc!))
            }
            childPtr = ptr.pointee.next
            idx += 1
        }
        return children
    }
    
    deinit {
        xmlFreeNode(nodePtr)
    }
}


extension XMLNode: XMLQuery {
    public func xpath(_ xpath: String) -> [XMLNode]? {
        if xpath.isEmpty { return nil }
        
        let data = xpath.data(using: .utf8)
        if data == nil { return nil }
        
        let context = xmlXPathNewContext(nodePtr.pointee.doc)
        if context == nil { return nil }
        defer { xmlXPathFreeContext(context) }
        
        let xpathPtr = xmlXPathEvalExpression([UInt8](data!), context)
        if xpathPtr == nil { return nil }
        defer { xmlXPathFreeObject(xpathPtr) }
        
        guard let val = xpathPtr!.pointee.nodesetval,
            let tab = val.pointee.nodeTab else { return nil }
        
        var nodes = [XMLNode]()
        for idx in 0 ..< Int(val.pointee.nodeNr) {
            if let ptr = tab[idx] {
                nodes.append(XMLNode(nodePtr: ptr, doc: doc!))
            }
        }
        return nodes
    }
}


extension XMLNode: CustomStringConvertible {
    public var description: String {
        let buffer = xmlBufferCreate()
        xmlNodeDump(buffer, doc?.docPtr, nodePtr, 0, 0)
        defer { xmlBufferFree(buffer) }
        return String(cString: xmlBufferContent(buffer))
    }
}

extension XMLNode: Equatable {
    public static func == (lhs: XMLNode, rhs: XMLNode) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

extension XMLNode: Hashable {
    public var hashValue: Int {
        return nodePtr.hashValue
    }
}

