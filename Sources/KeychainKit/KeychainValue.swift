import Foundation
import SwiftUI

/// A SwiftUI property wrapper that automatically syncs values with the keychain
@propertyWrapper
public struct KeychainValue<T: Codable & Sendable>: DynamicProperty, Sendable {
    
    /// The keychain instance to use
    private let keychain: Keychain
    
    /// The key to use for storing/retrieving the value
    private let key: String
    
    /// The default value to use when the key doesn't exist in the keychain
    private let defaultValue: T
    
    /// Internal state that triggers SwiftUI updates
    @State private var internalValue: T
    
    /// Initialize a KeychainValue property wrapper
    /// - Parameters:
    ///   - key: The keychain key to associate with this value
    ///   - keychain: The keychain instance to use (defaults to Keychain.default)
    ///   - defaultValue: The default value to use when the key doesn't exist
    public init(
        key: String,
        keychain: Keychain = .default,
        defaultValue: T
    ) {
        self.key = key
        self.keychain = keychain
        self.defaultValue = defaultValue
        
        // Initialize internal state with value from keychain or default
        let initialValue: T
        do {
            initialValue = try keychain.get(T.self, forKey: key) ?? defaultValue
        } catch {
            initialValue = defaultValue
        }
        
        self._internalValue = State(initialValue: initialValue)
    }
    
    /// The current value, reading from and writing to the keychain
    public var wrappedValue: T {
        get {
            // Return the current internal value
            // SwiftUI will handle updates through the binding
            return internalValue
        }
        nonmutating set {
            // Update keychain
            do {
                try keychain.set(newValue, forKey: key)
            } catch {
                #if DEBUG
                print("[KeychainKit] ⚠️ Failed to write key '\(key)': \(error)")
                #endif
                // Even if keychain write fails, we should update internal state
                // for immediate UI feedback
            }
            
            // Update internal state to trigger SwiftUI refresh
            internalValue = newValue
        }
    }
    
    /// A binding to the value, useful for two-way data binding in SwiftUI
    public var projectedValue: Binding<T> {
        let keychain = self.keychain
        let key = self.key
        
        return Binding(
            get: {
                // Try to get the latest value from keychain
                do {
                    if let value = try keychain.get(T.self, forKey: key) {
                        return value
                    }
                } catch {
                    // If there's an error reading from keychain, return current internal value
                }
                return self.internalValue
            },
            set: { newValue in
                // Update keychain
                do {
                    try keychain.set(newValue, forKey: key)
                } catch {
                    #if DEBUG
                    print("[KeychainKit] ⚠️ Failed to write key '\(key)': \(error)")
                    #endif
                    // Even if keychain write fails, we should update internal state
                }
                
                // Update internal state to trigger SwiftUI refresh
                self.internalValue = newValue
            }
        )
    }
    
}

// MARK: - Convenience Initializers

extension KeychainValue where T: ExpressibleByNilLiteral {
    /// Initialize a KeychainValue with a nil default value
    /// - Parameters:
    ///   - key: The keychain key to associate with this value
    ///   - keychain: The keychain instance to use (defaults to Keychain.default)
    public init(
        key: String,
        keychain: Keychain = .default
    ) {
        self.init(key: key, keychain: keychain, defaultValue: nil)
    }
}

extension KeychainValue where T == String {
    /// Initialize a KeychainValue for String with empty string default
    /// - Parameters:
    ///   - key: The keychain key to associate with this value
    ///   - keychain: The keychain instance to use (defaults to Keychain.default)
    public init(
        key: String,
        keychain: Keychain = .default
    ) {
        self.init(key: key, keychain: keychain, defaultValue: "")
    }
}

extension KeychainValue where T == Bool {
    /// Initialize a KeychainValue for Bool with false default
    /// - Parameters:
    ///   - key: The keychain key to associate with this value
    ///   - keychain: The keychain instance to use (defaults to Keychain.default)
    public init(
        key: String,
        keychain: Keychain = .default
    ) {
        self.init(key: key, keychain: keychain, defaultValue: false)
    }
}

extension KeychainValue where T == Int {
    /// Initialize a KeychainValue for Int with zero default
    /// - Parameters:
    ///   - key: The keychain key to associate with this value
    ///   - keychain: The keychain instance to use (defaults to Keychain.default)
    public init(
        key: String,
        keychain: Keychain = .default
    ) {
        self.init(key: key, keychain: keychain, defaultValue: 0)
    }
}

extension KeychainValue where T == Double {
    /// Initialize a KeychainValue for Double with zero default
    /// - Parameters:
    ///   - key: The keychain key to associate with this value
    ///   - keychain: The keychain instance to use (defaults to Keychain.default)
    public init(
        key: String,
        keychain: Keychain = .default
    ) {
        self.init(key: key, keychain: keychain, defaultValue: 0.0)
    }
}