//
//  DOC.swift
//  HQXMLDoc
//
//  Created by HonQi on 8/16/18.
//  Copyright © 2018 HonQi Indie. All rights reserved.
//

import libxml2

public class DOC {
    let docPtr: xmlDocPtr

    public let rootNode: Node
    
    public var version: String? {
        if let ver = docPtr.pointee.version { return String(cString: ver) }
        return nil
    }
    
    public var encoding: String.Encoding? {
        guard let encode = docPtr.pointee.encoding else { return nil }
        let encodeName = String(cString: encode)
        let encodeCode = CFStringConvertIANACharSetNameToEncoding(encodeName as CFString)
        guard encodeCode != kCFStringEncodingInvalidId else { return nil }
        return String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(encodeCode))
    }
    
    public convenience init(xml data: Data, encoding: String.Encoding? = nil) throws {
        try self.init(xml: true, data: data, encoding: encoding)
    }
    
    public convenience init(html data: Data, encoding: String.Encoding? = nil) throws {
        try self.init(xml: false, data: data, encoding: encoding)
    }
    
    public convenience init(html str: String, encoding: String.Encoding = .utf8) throws {
        guard let data = str.data(using: encoding) else { throw DocError.dataEmpty }
        try self.init(html: data, encoding: encoding)
    }
    
    public convenience init(xml str: String, encoding: String.Encoding = .utf8) throws {
        guard let data = str.data(using: encoding) else { throw DocError.dataEmpty }
        try self.init(xml: data, encoding: encoding)
    }
    
    init(xml: Bool, data: Data, encoding: String.Encoding? = nil) throws {
        guard !data.isEmpty else { throw DocError.dataEmpty }
        
        var encode: UnsafePointer<Int8>? = nil
        if let e = encoding {
            let cfEncoding = CFStringConvertNSStringEncodingToEncoding(e.rawValue)
            let cfEncodingAsString = CFStringConvertEncodingToIANACharSetName(cfEncoding)
            encode = CFStringGetCStringPtr(cfEncodingAsString, 0)
        }
        
        let options: Int32 = 1 << 0 | 1 << 5 | 1 << 6
        
        let cDatas = data.withUnsafeBytes { (bytes: UnsafePointer<Int8>) -> [CChar] in
            return [CChar](UnsafeBufferPointer(start: bytes, count: data.count))
        }
        
        var DOCPtr: xmlDocPtr!
        if xml {
            DOCPtr = xmlReadMemory(cDatas, Int32(data.count), nil, encode, options)
        }
        else {
            DOCPtr = htmlReadMemory(cDatas, Int32(data.count), nil, encode, options)
        }
        
        guard let ptr = DOCPtr else {
            if let err = xmlGetLastError() {
                defer { xmlResetLastError() }
                throw DocError.XMLError(err.pointee.code, String(cString: err.pointee.message).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))
            }
            throw DocError.Unknown
        }
        
        docPtr = ptr
        guard let root = xmlDocGetRootElement(ptr) else { throw DocError.missingRootNode }
        rootNode = Node(nodePtr: root)
    }
    
    deinit {
        xmlFreeDoc(docPtr)
    }
}

extension DOC {
    public func xpath(_ path: String) -> [Node]? {
        return rootNode.xpath(path)
    }
}

extension DOC: CustomStringConvertible {
    public var description: String {
        return rootNode.description
    }
}

extension DOC: Equatable {
    public static func == (lhs: DOC, rhs: DOC) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

extension DOC: Hashable {
    public var hashValue: Int {
        return docPtr.hashValue
    }
}
