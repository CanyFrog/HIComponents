//
//  Options.swift
//  HQDownload
//
//  Created by Magee Huang on 5/31/18.
//  Copyright © 2018 com.personal.HQ. All rights reserved.
//

public typealias OptionsInfo = [OptionItem]
public enum OptionItem {
    // MARK: - Global options, for downloader configuration

    /// The directory of files and cached databases, default is Cache directory
    case cacheDirectory(URL)

    /// Maximum cache count, if exceeded, will delete the oldest item, default is UInt.max
    case maxCacheCount(UInt)
    
    /// Maximum cache time, if exceeded, item will be deleted, default is 30 days
    case maxCacheAge(TimeInterval)
    
    /// Downloader concurrent download task number, defaulr is 6
    case maxConcurrentTask(UInt)
    
    /// Task executed order, Default is first in first out
    public enum TaskOrder: Int, Codable { case FIFO, LIFO }
    case taskOrder(TaskOrder)
    
    /// By default, request prevent the use of NSURLCache. With this flag, NSURLCache is used with default policies
    case useUrlCache
    
    /// Handles cookies stored in NSHTTPCookieStore by setting NSMutableURLRequest.HTTPShouldHandleCookies = YES;
    case handleCookies
    
    /// Enable to allow untrusted SSL certificates. Useful for testing purposes. Use with caution in production.
    case allowInvalidSSLCert
    
    
    
    // MARK: - Intermediate Options, if single task does not have an option, the global option is used
    
    /// Download operator priority, the value shoule be between 0.0 ~ 1.0; URLSessionTask.defaultPriority
    case priority(Float)
    
    /// Url authentic credential, default is nil
    case urlCredential(URLCredential)
    
    /// Url authentic username and password, defaule is nil
    case userPassAuth(String, String)

    /// Download task timeout, default is 15 seconds
    case taskTimeout(TimeInterval)
    
    /// Task failure auto retry count, default is 0
    case retryCount(UInt)
    
    /// continue the download of the data if the app goes to background, default not containes
    case taskInBackground
    
    
    // MARK: - Single task options, only use for single task
    case fileName(String)
    
    case sourceUrl(URL)
    
    case completedCount(Int64)
    
    case exceptedCount(Int64)
    
    /// ignore cache and download new data
    case forceRefresh
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
    case (.useUrlCache, .useUrlCache):                          return true
    case (.handleCookies, .handleCookies):                      return true
    case (.allowInvalidSSLCert, .allowInvalidSSLCert):          return true
        
    case (.priority(_), .priority(_)):                          return true
    case (.urlCredential(_), .urlCredential(_)):                return true
    case (.userPassAuth(_), .userPassAuth(_)):                  return true
    case (.taskTimeout(_), .taskTimeout(_)):                    return true
    case (.retryCount(_), .retryCount(_)):                      return true
    case (.taskInBackground, .taskInBackground):                return true
        
    case (.fileName(_), .fileName(_)):                          return true
    case (.sourceUrl(_), .sourceUrl(_)):                        return true
    case (.completedCount(_), .completedCount(_)):              return true
    case (.exceptedCount(_), .exceptedCount(_)):                return true
    case (.forceRefresh, .forceRefresh):                        return true
        
    default: return false
    }
}

extension Collection where Iterator.Element == OptionItem {
    func lastMatchIgnoringAssociatedValue(_ target: Iterator.Element) -> Iterator.Element? {
        return reversed().first { $0 ~~ target }
    }
    
    func removeAllMatchesIgnoringAssociatedValue(_ target: Iterator.Element) -> [Iterator.Element] {
        return filter { !($0 ~~ target) }
    }
}

public extension Collection where Iterator.Element == OptionItem {
    public var cacheDirectory: URL {
        if let item = lastMatchIgnoringAssociatedValue(.cacheDirectory(URL(string: "https://default.com")!)),
            case .cacheDirectory(let directory) = item {
            return directory
        }
        return URL(fileURLWithPath: "", isDirectory: true)
    }
}


