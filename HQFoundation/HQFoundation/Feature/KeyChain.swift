//
//  KeyChain.swift
//  HQFoundation
//
//  Created by HonQi on 2018/5/8.
//  Copyright © 2018年 HonQi Indie. All rights reserved.
//

import Security
import Foundation

public struct KeyChain {
    public static let service = "KeyChain.Foundation.me.HonQi"
    public static let accessGroup: String? = nil
    
    public enum KeychainError: Error {
        case noItem
        case unexpectedData
        case unexpectedItemData
        case unhandledError(status: OSStatus)
    }
    
    /// creaste keychain query dict
    public static func keychainQuery(service: String = KeyChain.service, account: String? = nil, accessGroup: String? = KeyChain.accessGroup) -> [String: AnyObject] {
        var query = [String: AnyObject]()
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecAttrService as String] = service as AnyObject?
        
        if let account = account {
            query[kSecAttrAccount as String] = account as AnyObject?
        }
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup as AnyObject?
        }
        
        return query
    }
}

extension KeyChain {
    
    public static func readItem(account: String) throws -> String {
        var query = KeyChain.keychainQuery(account: account)
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnAttributes as String] = kCFBooleanTrue
        query[kSecReturnData as String] = kCFBooleanTrue
        
        // Try to fetch the existing keychain item that matches the query.
        var queryResult: AnyObject?
        let status = withUnsafeMutablePointer(to: &queryResult) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }
        
        // Check the return status and throw an error if appropriate.
        guard status != errSecItemNotFound else { throw KeychainError.noItem }
        guard status == noErr else { throw KeychainError.unhandledError(status: status) }
        
        // Parse the password string from the query result.
        guard let existingItem = queryResult as? [String : AnyObject],
            let data = existingItem[kSecValueData as String] as? Data,
            let item = String(data: data, encoding: String.Encoding.utf8)
            else {
                throw KeychainError.unexpectedData
        }
        
        return item
    }
    
    
    public static func saveOrUpdateItem(account: String, item: String) throws {
        // Encode the password into an Data object.
        let encodedValue = item.data(using: String.Encoding.utf8)!
        
        do {
            // Check for an existing item in the keychain.
            try _ = readItem(account: account)
            
            // Update the existing item with the new password.
            var attributesToUpdate = [String : AnyObject]()
            attributesToUpdate[kSecValueData as String] = encodedValue as AnyObject?
            
            let query = KeyChain.keychainQuery(account: account)
            let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
            
            // Throw an error if an unexpected status was returned.
            guard status == noErr else { throw KeychainError.unhandledError(status: status) }
        }
        catch KeychainError.noItem {
            /*
             No password was found in the keychain. Create a dictionary to save
             as a new keychain item.
             */
            var newItem = KeyChain.keychainQuery(account: account)
            newItem[kSecValueData as String] = encodedValue as AnyObject?
            
            // Add a the new item to the keychain.
            let status = SecItemAdd(newItem as CFDictionary, nil)
            
            // Throw an error if an unexpected status was returned.
            guard status == noErr else { throw KeychainError.unhandledError(status: status) }
        }
    }
    
    public static func renameItemKey(oldKey: String, to newKey: String) throws {
        // Try to update an existing item with the new account name.
        var attributesToUpdate = [String : AnyObject]()
        attributesToUpdate[kSecAttrAccount as String] = newKey as AnyObject?
        
        let query = KeyChain.keychainQuery(account: oldKey)
        let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
        
        // Throw an error if an unexpected status was returned.
        guard status == noErr || status == errSecItemNotFound else { throw KeychainError.unhandledError(status: status) }
    }
    
    public static func delete(key: String) throws {
        // Delete the existing item from the keychain.
        let query = KeyChain.keychainQuery(account: key)
        let status = SecItemDelete(query as CFDictionary)
        
        // Throw an error if an unexpected status was returned.
        guard status == noErr || status == errSecItemNotFound else { throw KeychainError.unhandledError(status: status) }
    }
    
    public static func readAllItems(forService service: String = KeyChain.service, accessGroup: String? = KeyChain.accessGroup) throws -> [String]? {
        // Build a query for all items that match the service and access group.
        var query = KeyChain.keychainQuery(service: service, accessGroup: accessGroup)
        query[kSecMatchLimit as String] = kSecMatchLimitAll
        query[kSecReturnAttributes as String] = kCFBooleanTrue
        query[kSecReturnData as String] = kCFBooleanFalse
        
        // Fetch matching items from the keychain.
        var queryResult: AnyObject?
        let status = withUnsafeMutablePointer(to: &queryResult) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }
        
        // If no items were found, return an empty array.
        guard status != errSecItemNotFound else { return nil }
        
        // Throw an error if an unexpected status was returned.
        guard status == noErr else { throw KeychainError.unhandledError(status: status) }
        
        // Cast the query result to an array of dictionaries.
        guard let resultData = queryResult as? [[String : AnyObject]] else { throw KeychainError.unexpectedItemData }
        
        // Create a `KeychainPasswordItem` for each dictionary in the query result.
        var items = [String]()
        for result in resultData {
            guard let account  = result[kSecAttrAccount as String] as? String else { throw KeychainError.unexpectedItemData }
            items.append(account)
        }
        
        return items
    }
}
