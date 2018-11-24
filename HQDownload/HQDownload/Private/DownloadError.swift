//
//  DownloadError.swift
//  HQDownload
//
//  Created by HonQi on 8/13/18.
//  Copyright © 2018 HonQi Indie. All rights reserved.
//

import UIKit

// TODO: Adding callback multiple times causes an error
// MARK: - Error
public enum DownloadError: Error, CustomStringConvertible {
    case statusCodeInvalid(Int)
    case noCache304
    case error(Error)
    case cancel(String)
    case cacheError
    
    public var description: String {
        switch self {
        case .statusCodeInvalid(let code):
            return "Response status code \(code) is invalid!"
        case .noCache304:
            return "URLSession current behavior will return 200 status code when the server respond 304 and URLCache hit. But this is not cache."
        case .cancel(let reason):
            return "Task be canceled, because \(reason)"
        case .error(let err):
            return "Task is error, \(err.localizedDescription)"
        case .cacheError:
            return "Cache error: SQLite saved cache info is empty!"
        }
    }
}

