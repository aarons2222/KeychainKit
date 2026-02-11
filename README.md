# KeychainKit

A modern Swift library providing a simple, type-safe interface to the iOS and macOS Keychain Services. KeychainKit wraps the Security framework's C APIs with a clean Swift interface, including support for Codable types, SwiftUI property wrappers, and biometric authentication.

## Features

- **Type-safe API** - Store and retrieve `String`, `Data`, and any `Codable` type
- **SwiftUI Integration** - `@KeychainValue` property wrapper for seamless SwiftUI integration
- **Biometric Authentication** - Built-in Touch ID, Face ID, and Optic ID support
- **Thread-safe** - All operations use the thread-safe Security framework
- **iCloud Sync** - Optional iCloud Keychain synchronization
- **Comprehensive Error Handling** - Detailed error types with recovery suggestions

## Requirements

- **iOS 15.0+** / **macOS 12.0+**
- **Swift 6.2+**
- **Xcode 15.0+**

## Installation

### Swift Package Manager

Add KeychainKit to your project using Xcode:

1. File → Add Package Dependencies...
2. Enter the package URL
3. Select your desired version

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yourname/KeychainKit", from: "1.0.0")
]
```

## Quick Start

### Basic String Storage

```swift
import KeychainKit

let keychain = Keychain.default

// Store a string
try keychain.set("my-secret-password", forKey: "user_password")

// Retrieve a string
let password = try keychain.getString(forKey: "user_password")
```

### Codable Types

```swift
struct User: Codable {
    let id: String
    let name: String
    let email: String
}

let user = User(id: "123", name: "John Doe", email: "john@example.com")

// Store a Codable object
try keychain.set(user, forKey: "current_user")

// Retrieve a Codable object
let retrievedUser = try keychain.get(User.self, forKey: "current_user")
```

### SwiftUI Property Wrapper

```swift
import SwiftUI
import KeychainKit

struct LoginView: View {
    @KeychainValue(key: "username") private var username = ""
    @KeychainValue(key: "remember_me") private var rememberMe = false
    
    var body: some View {
        VStack {
            TextField("Username", text: $username)
            Toggle("Remember Me", isOn: $rememberMe)
        }
    }
}
```

### Biometric Authentication

```swift
// Store with biometric protection
try keychain.setWithBiometric("sensitive-data", forKey: "secure_key", prompt: "Access secure data")

// Retrieve with biometric authentication
let data = try await keychain.getStringWithBiometric(forKey: "secure_key", prompt: "Authenticate to access data")
```

### Custom Configuration

```swift
let keychain = Keychain(
    service: "com.myapp.keychain",
    accessibility: .whenUnlockedThisDeviceOnly,
    synchronizable: true  // Enable iCloud sync
)
```

## Security Notes

KeychainKit provides secure storage using the iOS/macOS Keychain Services. However, please review our [security documentation](SECURITY.md) for important considerations about memory security in Swift applications.

Key points:
- Keychain storage is encrypted and secure
- Swift String/Data objects in memory are not automatically zeroed
- Consider biometric protection for highly sensitive data
- Use appropriate accessibility levels for your use case

## Error Handling

KeychainKit provides detailed error information:

```swift
do {
    try keychain.set("value", forKey: "")  // Invalid empty key
} catch KeychainError.invalidKey {
    print("Key must not be empty and under 512 characters")
} catch {
    print("Keychain error: \(error.localizedDescription)")
}
```

## Thread Safety

Individual keychain operations are thread-safe, but compound operations (like `set()` which performs update-then-add) are not atomic. For atomic multi-step operations, synchronize access externally.

## License

MIT License. See [LICENSE](LICENSE) for details.