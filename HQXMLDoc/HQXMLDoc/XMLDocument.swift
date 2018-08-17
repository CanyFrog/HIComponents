//
//  XMLDocument.swift
//  HQXMLDoc
//
//  Created by HonQi on 8/16/18.
//  Copyright © 2018 HonQi Indie. All rights reserved.
//

import libxml2

public class XMLDocument {
    public lazy var rootNode = XMLNode(nodePtr: xmlDocGetRootElement(self.docPtr), doc: self)
    
    var docPtr: xmlDocPtr
    
    public lazy var version: String? = {
        if let ver = self.docPtr.pointee.version { return String(cString: ver) }
        return nil
    }()
    
    public lazy var encoding: String.Encoding? = {
        guard let encode = self.docPtr.pointee.encoding else { return nil }
        let encodeName = String(cString: encode)
        let encodeCode = CFStringConvertIANACharSetNameToEncoding(encodeName as CFString)
        guard encodeCode != kCFStringEncodingInvalidId else { return nil }
        return String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(encodeCode))
    }()
    
    public init?(xml data: Data) throws {
        let documentPtr = xmlReadMemory(data.withUnsafeBytes{$0}, Int32(data.count), nil, nil, Int32(UInt8(XML_PARSE_NOWARNING.rawValue) | UInt8(XML_PARSE_NOERROR.rawValue)))
        
        guard let ptr = documentPtr else { throw XMLError(xmlGetLastError()) }
        xmlResetLastError()
        docPtr = ptr
    }
    
    public init?(html data: Data) throws {
        let htmlPtr = htmlReadMemory(data.withUnsafeBytes{$0}, Int32(data.count), nil, nil, Int32(UInt8(HTML_PARSE_NOWARNING.rawValue) | UInt8(HTML_PARSE_NOERROR.rawValue)))
        guard let ptr = htmlPtr else { throw XMLError(xmlGetLastError()) }
        xmlResetLastError()
        docPtr = ptr
    }
    
    public convenience init?(html str: String, encodeing: String.Encoding = .utf8) throws {
        guard let data = str.data(using: encodeing) else { return nil }
        try self.init(html: data)
    }
    
    public convenience init?(xml str: String, encodeing: String.Encoding = .utf8) throws {
        guard let data = str.data(using: encodeing) else { return nil }
        try self.init(xml: data)
    }
    
    deinit {
        xmlFreeDoc(docPtr)
    }
}

extension XMLDocument: XMLQuery {
    public func xpath(_ xpath: String) -> [XMLNode]? {
        return rootNode.xpath(xpath)
    }
}


extension XMLDocument: CustomStringConvertible {
    public var description: String {
        return rootNode.description
    }
}

extension XMLDocument: Equatable {
    public static func == (lhs: XMLDocument, rhs: XMLDocument) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

extension XMLDocument: Hashable {
    public var hashValue: Int {
        return docPtr.hashValue
    }
}
