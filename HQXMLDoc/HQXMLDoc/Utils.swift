//
//  Utils.swift
//  HQXMLDoc
//
//  Created by HonQi on 8/16/18.
//  Copyright © 2018 HonQi Indie. All rights reserved.
//

import libxml2

protocol XMLQuery {
    func xpath(_ xpath: String) -> [XMLNode]?
}

public struct XMLError: Error {
    var code: Int32
    var message: String
    
    public init(_ errorPtr: xmlErrorPtr) {
        message = String(cString: errorPtr.pointee.message).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        code = errorPtr.pointee.code
    }
}
