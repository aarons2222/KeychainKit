# Changelog

All notable changes to KeychainKit will be documented in this file.

## [1.0.0] — 2026-02-11

### Added
- Core `Keychain` class with full CRUD operations (set, get, remove, removeAll, contains, keys)
- `Data`, `String`, and `Codable` convenience methods
- `@KeychainValue` SwiftUI property wrapper with auto-sync
- Biometric authentication support (Face ID / Touch ID / Optic ID)
- `KeychainAccessibility` enum for controlling item accessibility
- Access group support for sharing between apps and extensions
- iCloud Keychain sync option (`synchronizable`)
- Key validation (non-empty, max 512 chars)
- Comprehensive test suite (21+ tests)
- Full documentation and README
- Security audit documentation (SECURITY.md)
- Demo app showcasing all features
