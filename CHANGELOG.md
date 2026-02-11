# Changelog

All notable changes to KeychainKit will be documented in this file.

## [1.0.1] — 2026-02-11

### Fixed
- **Biometric error capture** — `SecItemCopyMatching` errors now properly caught and thrown instead of silently returning nil
- **Async dispatch** — all Keychain operations dispatched to background queue to avoid blocking main thread
- **`removeAll()` on macOS** — `SecItemDelete` only removes one item per call on macOS; now loops until `errSecItemNotFound`
- **`@KeychainValue` nonmutating setter** — `wrappedValue` setter is now `nonmutating` for SwiftUI struct compatibility
- **Key validation** — rejects empty keys and keys longer than 512 characters with `.invalidKey` error
- **DEBUG logging** — write failures now log to console in DEBUG builds for easier troubleshooting

### Removed
- Dead `KeychainKit.swift` file (empty placeholder)
- Unused `updateQuery` method in `KeychainQuery`

### Demo App
- Added `NSFaceIDUsageDescription` via `INFOPLIST_KEY` (fixes Face ID permission crash)
- Added keyboard dismiss (`.scrollDismissesKeyboard(.interactively)` + toolbar Done button)
- Fixed compound operators (`+=`/`-=`) for nonmutating setter compatibility
- Fixed Swift 6 Codable conformance (`nonisolated struct`)

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
