import Foundation
import Security
import LocalAuthentication

/// Extension providing biometric authentication support for keychain operations
extension Keychain {
    
    // MARK: - Biometric Data Operations
    
    /// Store data in the keychain with biometric protection
    /// - Parameters:
    ///   - data: The data to store
    ///   - key: The key to associate with the data
    ///   - prompt: The prompt to display to the user during authentication
    /// - Throws: KeychainError if the operation fails
    public func setWithBiometric(_ data: Data, forKey key: String, prompt: String) throws {
        try validateKey(key)
        
        // Remove existing item if it exists
        try? remove(forKey: key)
        
        // Create new item with biometric protection
        let addQuery = try query.addBiometricQuery(account: key, data: data)
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        
        if status != errSecSuccess {
            throw KeychainError.from(status)
        }
    }
    
    /// Retrieve data from the keychain with biometric authentication
    /// - Parameters:
    ///   - key: The key associated with the data
    ///   - prompt: The prompt to display to the user during authentication
    /// - Returns: The data if found and authenticated, nil otherwise
    /// - Throws: KeychainError if the operation fails
    public func getWithBiometric(forKey key: String, prompt: String) async throws -> Data? {
        try validateKey(key)
        
        let context = LAContext()
        context.localizedReason = prompt
        
        let fetchQuery = query.fetchBiometricQuery(account: key, context: context)
        
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var result: AnyObject?
                let status = SecItemCopyMatching(fetchQuery as CFDictionary, &result)
                
                if status == errSecItemNotFound {
                    continuation.resume(returning: nil)
                    return
                }
                if status != errSecSuccess {
                    continuation.resume(throwing: KeychainError.from(status))
                    return
                }
                guard let data = result as? Data else {
                    continuation.resume(throwing: KeychainError.unexpectedData)
                    return
                }
                continuation.resume(returning: data)
            }
        }
    }
    
    // MARK: - Biometric Codable Convenience Methods
    
    /// Store a Codable value in the keychain with biometric protection
    /// - Parameters:
    ///   - value: The Codable value to store
    ///   - key: The key to associate with the value
    ///   - prompt: The prompt to display to the user during authentication
    /// - Throws: KeychainError or encoding errors
    public func setWithBiometric<T: Codable & Sendable>(_ value: T, forKey key: String, prompt: String) throws {
        try validateKey(key)
        
        let data = try JSONEncoder().encode(value)
        try setWithBiometric(data, forKey: key, prompt: prompt)
    }
    
    /// Retrieve a Codable value from the keychain with biometric authentication
    /// - Parameters:
    ///   - type: The type to decode
    ///   - key: The key associated with the value
    ///   - prompt: The prompt to display to the user during authentication
    /// - Returns: The decoded value if found and authenticated, nil otherwise
    /// - Throws: KeychainError or decoding errors
    public func getWithBiometric<T: Codable & Sendable>(_ type: T.Type, forKey key: String, prompt: String) async throws -> T? {
        try validateKey(key)
        
        let context = LAContext()
        context.localizedReason = prompt
        
        let fetchQuery = query.fetchBiometricQuery(account: key, context: context)
        
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var result: AnyObject?
                let status = SecItemCopyMatching(fetchQuery as CFDictionary, &result)
                
                if status == errSecItemNotFound {
                    continuation.resume(returning: nil)
                    return
                }
                if status != errSecSuccess {
                    continuation.resume(throwing: KeychainError.from(status))
                    return
                }
                guard let data = result as? Data else {
                    continuation.resume(throwing: KeychainError.unexpectedData)
                    return
                }
                
                do {
                    let decoded = try JSONDecoder().decode(type, from: data)
                    continuation.resume(returning: decoded)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Biometric String Convenience Methods
    
    /// Store a string in the keychain with biometric protection
    /// - Parameters:
    ///   - string: The string to store
    ///   - key: The key to associate with the string
    ///   - prompt: The prompt to display to the user during authentication
    /// - Throws: KeychainError if the operation fails
    public func setWithBiometric(_ string: String, forKey key: String, prompt: String) throws {
        try validateKey(key)
        
        guard let data = string.data(using: .utf8) else {
            throw KeychainError.unexpectedData
        }
        try setWithBiometric(data, forKey: key, prompt: prompt)
    }
    
    /// Retrieve a string from the keychain with biometric authentication
    /// - Parameters:
    ///   - key: The key associated with the string
    ///   - prompt: The prompt to display to the user during authentication
    /// - Returns: The string if found and authenticated, nil otherwise
    /// - Throws: KeychainError if the operation fails
    public func getStringWithBiometric(forKey key: String, prompt: String) async throws -> String? {
        try validateKey(key)
        
        let context = LAContext()
        context.localizedReason = prompt
        
        let fetchQuery = query.fetchBiometricQuery(account: key, context: context)
        
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var result: AnyObject?
                let status = SecItemCopyMatching(fetchQuery as CFDictionary, &result)
                
                if status == errSecItemNotFound {
                    continuation.resume(returning: nil)
                    return
                }
                if status != errSecSuccess {
                    continuation.resume(throwing: KeychainError.from(status))
                    return
                }
                guard let data = result as? Data else {
                    continuation.resume(throwing: KeychainError.unexpectedData)
                    return
                }
                guard let string = String(data: data, encoding: .utf8) else {
                    continuation.resume(throwing: KeychainError.unexpectedData)
                    return
                }
                continuation.resume(returning: string)
            }
        }
    }
    
    // MARK: - Biometric Availability
    
    /// Check if biometric authentication is available on this device
    /// - Returns: true if biometrics are available and enrolled, false otherwise
    public static func isBiometricAuthenticationAvailable() -> Bool {
        let context = LAContext()
        var error: NSError?
        
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    /// Get the type of biometric authentication available
    /// - Returns: A description of the available biometric type, or nil if none available
    public static func biometricType() -> String? {
        guard isBiometricAuthenticationAvailable() else {
            return nil
        }
        
        let context = LAContext()
        switch context.biometryType {
        case .none:
            return nil
        case .touchID:
            return "Touch ID"
        case .faceID:
            return "Face ID"
        case .opticID:
            return "Optic ID"
        @unknown default:
            return "Biometric Authentication"
        }
    }
}