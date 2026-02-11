import Foundation
import Security

/// A Swift wrapper around the iOS/macOS Keychain Services
/// - Note: Individual operations are thread-safe, but compound operations like `set` 
/// (which attempts update then add) are not atomic. If you need to perform multiple 
/// operations atomically, synchronize access externally.
public final class Keychain: Sendable {
    /// The service name for this keychain instance
    public let service: String
    /// The access group for shared keychain access (optional)
    public let accessGroup: String?
    /// The accessibility level for keychain items
    public let accessibility: KeychainAccessibility
    /// Whether keychain items should be synchronized with iCloud
    public let synchronizable: Bool
    
    /// Internal query builder
    internal let query: KeychainQuery
    
    /// Default shared keychain instance
    public static let `default` = Keychain()
    
    /// Validate a key for keychain operations
    /// - Parameter key: The key to validate
    /// - Throws: KeychainError.invalidKey if the key is invalid
    internal func validateKey(_ key: String) throws {
        guard !key.isEmpty else {
            throw KeychainError.invalidKey
        }
        guard key.count <= 512 else {
            throw KeychainError.invalidKey
        }
    }
    
    /// Initialize a new Keychain instance
    /// - Parameters:
    ///   - service: The service name to use for keychain items (defaults to bundle identifier)
    ///   - accessGroup: Optional access group for shared keychain access
    ///   - accessibility: When the keychain items should be accessible (defaults to whenUnlocked)
    ///   - synchronizable: Whether keychain items should be synchronized with iCloud (defaults to false)
    public init(
        service: String = Bundle.main.bundleIdentifier ?? "KeychainKit",
        accessGroup: String? = nil,
        accessibility: KeychainAccessibility = .whenUnlocked,
        synchronizable: Bool = false
    ) {
        self.service = service
        self.accessGroup = accessGroup
        self.accessibility = accessibility
        self.synchronizable = synchronizable
        self.query = KeychainQuery(
            service: service,
            accessGroup: accessGroup,
            accessibility: accessibility,
            synchronizable: synchronizable
        )
    }
    
    // MARK: - Data Operations
    
    /// Store data in the keychain
    /// - Parameters:
    ///   - data: The data to store
    ///   - key: The key to associate with the data
    /// - Throws: KeychainError if the operation fails
    public func set(_ data: Data, forKey key: String) throws {
        try validateKey(key)
        
        // First try to update existing item
        let searchQuery = query.searchQuery(account: key)
        let updateAttributes: [String: Any] = [
            kSecValueData as String: data
        ]
        
        let updateStatus = SecItemUpdate(searchQuery as CFDictionary, updateAttributes as CFDictionary)
        
        if updateStatus == errSecSuccess {
            return // Successfully updated existing item
        }
        
        if updateStatus != errSecItemNotFound {
            throw KeychainError.from(updateStatus)
        }
        
        // Item doesn't exist, create new one
        let addQuery = query.addQuery(account: key, data: data)
        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        
        if addStatus != errSecSuccess {
            throw KeychainError.from(addStatus)
        }
    }
    
    /// Retrieve data from the keychain
    /// - Parameter key: The key associated with the data
    /// - Returns: The data if found, nil otherwise
    /// - Throws: KeychainError if the operation fails (except for item not found)
    public func get(forKey key: String) throws -> Data? {
        try validateKey(key)
        
        let fetchQuery = query.fetchQuery(account: key)
        
        var result: AnyObject?
        let status = SecItemCopyMatching(fetchQuery as CFDictionary, &result)
        
        if status == errSecItemNotFound {
            return nil
        }
        
        if status != errSecSuccess {
            throw KeychainError.from(status)
        }
        
        guard let data = result as? Data else {
            throw KeychainError.unexpectedData
        }
        
        return data
    }
    
    /// Remove an item from the keychain
    /// - Parameter key: The key of the item to remove
    /// - Throws: KeychainError if the operation fails
    public func remove(forKey key: String) throws {
        try validateKey(key)
        
        let deleteQuery = query.deleteQuery(account: key)
        let status = SecItemDelete(deleteQuery as CFDictionary)
        
        if status != errSecSuccess && status != errSecItemNotFound {
            throw KeychainError.from(status)
        }
    }
    
    /// Remove all items for this service from the keychain
    /// - Warning: This permanently removes ALL items stored under this service name.
    /// This operation cannot be undone. Consider using `remove(forKey:)` for targeted removal.
    /// - Throws: KeychainError if the operation fails
    public func removeAll() throws {
        let deleteAllQuery = query.deleteAllQuery()
        // On macOS, SecItemDelete may only remove one item per call.
        // Loop until all items are deleted.
        var status = SecItemDelete(deleteAllQuery as CFDictionary)
        while status == errSecSuccess {
            status = SecItemDelete(deleteAllQuery as CFDictionary)
        }
        
        if status != errSecItemNotFound {
            throw KeychainError.from(status)
        }
    }
    
    /// Check if an item exists in the keychain
    /// - Parameter key: The key to check for
    /// - Returns: true if the item exists, false otherwise
    /// - Throws: KeychainError if the operation fails
    public func contains(key: String) throws -> Bool {
        try validateKey(key)
        
        let existsQuery = query.existsQuery(account: key)
        let status = SecItemCopyMatching(existsQuery as CFDictionary, nil)
        
        if status == errSecItemNotFound {
            return false
        }
        
        if status == errSecSuccess {
            return true
        }
        
        throw KeychainError.from(status)
    }
    
    /// Get all keys for this service
    /// - Returns: An array of all keys stored for this service
    /// - Throws: KeychainError if the operation fails
    public func keys() throws -> [String] {
        let allKeysQuery = query.allKeysQuery()
        
        var result: AnyObject?
        let status = SecItemCopyMatching(allKeysQuery as CFDictionary, &result)
        
        if status == errSecItemNotFound {
            return []
        }
        
        if status != errSecSuccess {
            throw KeychainError.from(status)
        }
        
        guard let items = result as? [[String: Any]] else {
            throw KeychainError.unexpectedData
        }
        
        let keys = items.compactMap { item in
            item[kSecAttrAccount as String] as? String
        }
        
        return keys
    }
    
    // MARK: - Codable Convenience Methods
    
    /// Store a Codable value in the keychain
    /// - Parameters:
    ///   - value: The Codable value to store
    ///   - key: The key to associate with the value
    /// - Throws: KeychainError or encoding errors
    public func set<T: Codable & Sendable>(_ value: T, forKey key: String) throws {
        try validateKey(key)
        
        let data = try JSONEncoder().encode(value)
        try set(data, forKey: key)
    }
    
    /// Retrieve a Codable value from the keychain
    /// - Parameters:
    ///   - type: The type to decode
    ///   - key: The key associated with the value
    /// - Returns: The decoded value if found, nil otherwise
    /// - Throws: KeychainError or decoding errors
    public func get<T: Codable & Sendable>(_ type: T.Type, forKey key: String) throws -> T? {
        try validateKey(key)
        
        guard let data = try get(forKey: key) else {
            return nil
        }
        
        return try JSONDecoder().decode(type, from: data)
    }
    
    // MARK: - String Convenience Methods
    
    /// Store a string in the keychain
    /// - Parameters:
    ///   - string: The string to store
    ///   - key: The key to associate with the string
    /// - Throws: KeychainError if the operation fails
    public func set(_ string: String, forKey key: String) throws {
        try validateKey(key)
        
        guard let data = string.data(using: .utf8) else {
            throw KeychainError.unexpectedData
        }
        try set(data, forKey: key)
    }
    
    /// Retrieve a string from the keychain
    /// - Parameter key: The key associated with the string
    /// - Returns: The string if found, nil otherwise
    /// - Throws: KeychainError if the operation fails
    public func getString(forKey key: String) throws -> String? {
        try validateKey(key)
        
        guard let data = try get(forKey: key) else {
            return nil
        }
        
        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.unexpectedData
        }
        
        return string
    }
}