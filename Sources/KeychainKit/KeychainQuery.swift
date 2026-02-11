import Foundation
import Security
import LocalAuthentication

/// Internal query builder for keychain operations
struct KeychainQuery: Sendable {
    let service: String
    let accessGroup: String?
    let accessibility: KeychainAccessibility
    let synchronizable: Bool
    
    /// Creates a query for adding an item to the keychain
    func addQuery(account: String, data: Data) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: accessibility.cfString
        ]
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        if synchronizable {
            query[kSecAttrSynchronizable as String] = kCFBooleanTrue
        }
        
        return query
    }
    
    /// Creates a query for adding an item with biometric protection
    func addBiometricQuery(account: String, data: Data) throws -> [String: Any] {
        var error: Unmanaged<CFError>?
        guard let accessControl = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            .biometryCurrentSet,
            &error
        ) else {
            throw KeychainError.unhandled(errSecParam)
        }
        
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessControl as String: accessControl
        ]
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        if synchronizable {
            query[kSecAttrSynchronizable as String] = kCFBooleanTrue
        }
        
        return query
    }
    
    /// Creates a query for searching keychain items
    func searchQuery(account: String? = nil) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        
        if let account = account {
            query[kSecAttrAccount as String] = account
        }
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        if synchronizable {
            query[kSecAttrSynchronizable as String] = kCFBooleanTrue
        }
        
        return query
    }
    
    /// Creates a query for fetching a single item's data
    func fetchQuery(account: String) -> [String: Any] {
        var query = searchQuery(account: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        return query
    }
    
    /// Creates a query for fetching a single item's data with biometric authentication
    func fetchBiometricQuery(account: String, context: LAContext) -> [String: Any] {
        var query = searchQuery(account: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecUseAuthenticationContext as String] = context
        return query
    }
    
    /// Creates a query for checking if an item exists
    func existsQuery(account: String) -> [String: Any] {
        var query = searchQuery(account: account)
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        return query
    }
    
    /// Creates a query for fetching all account names (keys)
    func allKeysQuery() -> [String: Any] {
        var query = searchQuery()
        query[kSecReturnAttributes as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitAll
        return query
    }
    
    /// Creates a query for deleting a specific item
    func deleteQuery(account: String) -> [String: Any] {
        return searchQuery(account: account)
    }
    
    /// Creates a query for deleting all items for this service
    func deleteAllQuery() -> [String: Any] {
        return searchQuery()
    }
}