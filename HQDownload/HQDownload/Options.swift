//
//  Options.swift
//  HQDownload
//
//  Created by Magee Huang on 5/31/18.
//  Copyright © 2018 com.personal.HQ. All rights reserved.
//

public typealias OptionsInfo = [OptionItem]
public enum OptionItem {
    // MARK: - Cache options
    /// The directory of files and cached databases, default is Cache directory
    case cacheDirectory(URL)

    /// Maximum cache count, if exceeded, will delete the oldest item, default is UInt.max
    case maxCacheCount(UInt)
    
    /// Maximum cache time, if exceeded, item will be deleted, default is 30 days
    case maxCacheAge(TimeInterval)
    
    /// ignore cache and download new data
    case forceRefresh

    // MARK: - Download queue options
    /// Downloader concurrent download task number, defaulr is 6
    case maxConcurrentTask(UInt)
    
    /// Task executed order, Default is first in first out
    public enum TaskOrder: Int, Codable { case FIFO, LIFO }
    case taskOrder(TaskOrder)
    
    
    // MARK: - Operation Task
    /// continue the download of the data if the app goes to background, default not containes
    case taskInBackground
    
    case fileName(String)
    
    /// Enable to allow untrusted SSL certificates. Useful for testing purposes. Use with caution in production.
    case allowInvalidSSLCert

    /// Download operator priority, the value shoule be between 0.0 ~ 1.0; URLSessionTask.defaultPriority
    case priority(Float)
    
    /// Url authentic credential, default is nil
    case urlCredential(URLCredential)
    
    /// Url authentic username and password, defaule is nil
    case userPassAuth(String, String)
    
    /// Task failure auto retry count, default is 0
    case retryCount(UInt)
    
    
    
    // MARK: - Request
    case sourceUrl(URL)
    
    /// Handles cookies stored in NSHTTPCookieStore by setting NSMutableURLRequest.HTTPShouldHandleCookies = YES;
    case handleCookies
    
    /// By default, request prevent the use of NSURLCache. With this flag, NSURLCache is used with default policies
    case useUrlCache
    
    /// Download task timeout, default is 15 seconds
    case taskTimeout(TimeInterval)
    
    case completedCount(Int64)
    
    case exceptedCount(Int64)
}

precedencegroup ItemComparisonPrecedence {
    associativity: none
    higherThan: LogicalConjunctionPrecedence
}

infix operator ~~ : ItemComparisonPrecedence

// This operator returns true if two `OptionItem` enum is the same, without considering the associated values.
func ~~ (lhs: OptionItem, rhs: OptionItem) -> Bool {
    switch (lhs, rhs) {
    case (.cacheDirectory(_), .cacheDirectory(_)):              return true
    case (.maxCacheCount(_), .maxCacheCount(_)):                return true
    case (.maxCacheAge(_), .maxCacheAge(_)):                    return true
    case (.maxConcurrentTask(_), .maxConcurrentTask(_)):        return true
    case (.taskOrder(_), .taskOrder(_)):                        return true
    case (.forceRefresh, .forceRefresh):                        return true

    
       
    /// Operation
    case (.taskInBackground, .taskInBackground):                return true
    case (.fileName(_), .fileName(_)):                          return true
    case (.allowInvalidSSLCert, .allowInvalidSSLCert):          return true
    case (.priority(_), .priority(_)):                          return true
    case (.urlCredential(_), .urlCredential(_)):                return true
    case (.userPassAuth(_), .userPassAuth(_)):                  return true
    case (.retryCount(_), .retryCount(_)):                      return true

        
    /// Request
    case (.sourceUrl(_), .sourceUrl(_)):                        return true
    case (.handleCookies, .handleCookies):                      return true
    case (.useUrlCache, .useUrlCache):                          return true
    case (.taskTimeout(_), .taskTimeout(_)):                    return true
    case (.completedCount(_), .completedCount(_)):              return true
    case (.exceptedCount(_), .exceptedCount(_)):                return true

    default: return false
    }

}

extension Collection where Iterator.Element == OptionItem {
    // 先将顺序翻转再查找，保证使用的是最新的
    func lastMatchIgnoringAssociatedValue(_ target: Iterator.Element) -> Iterator.Element? {
        return reversed().first { $0 ~~ target }
    }
    
    func removeAllMatchesIgnoringAssociatedValue(_ target: Iterator.Element) -> [Iterator.Element] {
        return filter { !($0 ~~ target) }
    }
}


let holderUrl = URL(string: "https://httpbin.org/")!
public extension Collection where Iterator.Element == OptionItem {
    public var cacheDirectory: URL {
        if let item = lastMatchIgnoringAssociatedValue(.cacheDirectory(holderUrl)),
            case .cacheDirectory(let directory) = item {
            return directory
        }
        return URL(fileURLWithPath: "", isDirectory: true)
    }
    
    public var forceRefresh: Bool {
        return contains{ $0 ~~ .forceRefresh }
    }
    
    /// Operation
    public var taskInBackground: Bool {
        return contains{ $0 ~~ .taskInBackground }
    }
    
    public var fileName: String? {
        if let item = lastMatchIgnoringAssociatedValue(.fileName(" ")),
            case .fileName(let name) = item {
            return name
        }
        return nil
    }

    public var allowInvalidSSLCert: Bool {
        return contains{ $0 ~~ .allowInvalidSSLCert }
    }
    
    public var priority: Float {
        if let item = lastMatchIgnoringAssociatedValue(.priority(0)),
            case .priority(let num) = item {
            return num
        }
        return URLSessionDataTask.defaultPriority
    }
    
    public var urlCredential: URLCredential? {
        let holderCred = URLCredential(user: "", password: "", persistence: .none)
        if let item = lastMatchIgnoringAssociatedValue(.urlCredential(holderCred)),
            case .urlCredential(let cred) = item {
            return cred
        }
        
        if let item = lastMatchIgnoringAssociatedValue(.userPassAuth("", "")),
            case .userPassAuth(let user, let pass) = item {
            return URLCredential(user: user, password: pass, persistence: .forSession)
        }
        return nil
    }
    
    public var retryCount: UInt {
        if let item = lastMatchIgnoringAssociatedValue(.retryCount(0)),
            case .retryCount(let num) = item {
            return num
        }
        return 0
    }

    
    /// Request
    public var sourceUrl: URL? {
        if let item = lastMatchIgnoringAssociatedValue(.sourceUrl(holderUrl)),
            case .sourceUrl(let source) = item {
            return source
        }
        return nil
    }
    
    public var handleCookies: Bool {
        return contains{ $0 ~~ .handleCookies }
    }
    
    public var useUrlCache: Bool {
        return contains{ $0 ~~ .useUrlCache }
    }
    
    public var taskTimeout: TimeInterval {
        if let item = lastMatchIgnoringAssociatedValue(.taskTimeout(0)),
            case .taskTimeout(let time) = item {
            return time
        }
        return 15
    }
    
    public var completedCount: Int64? {
        if let item = lastMatchIgnoringAssociatedValue(.completedCount(0)),
            case .completedCount(let count) = item {
            return count
        }
        return nil
    }
    
    public var exceptedCount: Int64? {
        if let item = lastMatchIgnoringAssociatedValue(.exceptedCount(0)),
            case .exceptedCount(let count) = item {
            return count
        }
        return nil
    }
}


