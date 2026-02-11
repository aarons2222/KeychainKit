import Foundation
import Security

/// Errors that can occur when working with the keychain
public enum KeychainError: Error, Sendable {
    /// The requested keychain item was not found
    case itemNotFound
    /// A duplicate item already exists in the keychain
    case duplicateItem
    /// Authentication failed (e.g., biometric authentication)
    case authFailed
    /// The data returned from the keychain was in an unexpected format
    case unexpectedData
    /// The provided key is invalid (empty or too long)
    case invalidKey
    /// An unhandled OSStatus error from the Security framework
    case unhandled(OSStatus)
}

extension KeychainError: LocalizedError {
    /// A localized description of the error
    public var errorDescription: String? {
        switch self {
        case .itemNotFound:
            return "The requested keychain item was not found"
        case .duplicateItem:
            return "A duplicate item already exists in the keychain"
        case .authFailed:
            return "Authentication failed"
        case .unexpectedData:
            return "The data returned from the keychain was in an unexpected format"
        case .invalidKey:
            return "The provided key is invalid"
        case .unhandled(let status):
            return "Keychain operation failed with status: \(status)"
        }
    }
    
    /// A localized failure reason for the error
    public var failureReason: String? {
        switch self {
        case .itemNotFound:
            return "The specified key does not exist in the keychain"
        case .duplicateItem:
            return "An item with this key already exists"
        case .authFailed:
            return "User authentication was required but failed"
        case .unexpectedData:
            return "The keychain returned data that could not be processed"
        case .invalidKey:
            return "The key is either empty or exceeds the maximum length of 512 characters"
        case .unhandled(let status):
            return "Security framework returned error code \(status)"
        }
    }
    
    /// A localized recovery suggestion for the error
    public var recoverySuggestion: String? {
        switch self {
        case .itemNotFound:
            return "Check that the key is correct and the item exists"
        case .duplicateItem:
            return "Use a different key or update the existing item"
        case .authFailed:
            return "Ensure biometric authentication is available and retry"
        case .unexpectedData:
            return "The stored data may be corrupted"
        case .invalidKey:
            return "Provide a non-empty key with 512 characters or fewer"
        case .unhandled:
            return "Check the Security framework documentation for this error code"
        }
    }
}

extension KeychainError {
    /// Create a KeychainError from an OSStatus
    /// - Parameter status: The OSStatus returned from a Security framework function
    /// - Returns: An appropriate KeychainError
    static func from(_ status: OSStatus) -> KeychainError {
        switch status {
        case errSecItemNotFound:
            return .itemNotFound
        case errSecDuplicateItem:
            return .duplicateItem
        case errSecAuthFailed:
            return .authFailed
        default:
            return .unhandled(status)
        }
    }
}