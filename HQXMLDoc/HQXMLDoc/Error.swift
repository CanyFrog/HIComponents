//
//  Error.swift
//  HQXMLDoc
//
//  Created by HonQi on 8/16/18.
//  Copyright © 2018 HonQi Indie. All rights reserved.
//

public enum DocError: Error, CustomStringConvertible {
    case missingRootNode
    case dataEmpty
    case XMLError(Int32, String)
    case Unknown
    
    public var description: String {
        switch self {
        case .missingRootNode:
            return "Missing root node"
        case .dataEmpty:
            return "Data is empty or can not encode"
        case .XMLError(let code, let msg):
            return "Xml error: code is \(code) and message is \(msg)"
        default:
            return "Unknown error"
        }
    }
}
