# Contributing to KeychainKit

Thanks for your interest in contributing! Here's how to get started.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/KeychainKit.git`
3. Create a branch: `git checkout -b feature/your-feature`
4. Make your changes
5. Run tests: `swift test`
6. Commit: `git commit -m "Add your feature"`
7. Push: `git push origin feature/your-feature`
8. Open a Pull Request

## Development

### Requirements
- Xcode 16.0+
- Swift 6.2+
- macOS 15+

### Building
```bash
swift build
```

### Testing
```bash
swift test
```

### Demo App
Open `KeychainKitDemo/KeychainKit Demo.xcodeproj` in Xcode. Add the local package dependency (File → Add Package → Add Local → select the root folder).

## Guidelines

- **Tests required** — all new features must include tests
- **Documentation** — all public APIs need `///` doc comments
- **Security first** — this is a keychain library. Be paranoid.
- **No external dependencies** — keep it lean
- **Swift 6 concurrency** — all types must be `Sendable` where appropriate
- **Backwards compatible** — don't break existing API without a major version bump

## Reporting Security Issues

If you find a security vulnerability, please **do not** open a public issue. Instead, email security concerns to aaron.strickland@icloud.com.

## Code of Conduct

Be respectful. Be helpful. Be kind.
