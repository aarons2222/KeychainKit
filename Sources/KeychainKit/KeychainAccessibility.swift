import Foundation
import Security

/// Controls when a keychain item is accessible
public enum KeychainAccessibility: Sendable, CustomStringConvertible {
    /// Item data can only be accessed while the device is unlocked by the user
    case whenUnlocked
    /// Item data can only be accessed once the device has been unlocked after a restart
    case afterFirstUnlock
    /// Item data can only be accessed while the device is unlocked by the user, and only on this device
    case whenUnlockedThisDeviceOnly
    /// Item data can only be accessed once the device has been unlocked after a restart, and only on this device
    case afterFirstUnlockThisDeviceOnly
    
    /// The corresponding CFString value for use with the Security framework
    public var cfString: CFString {
        switch self {
        case .whenUnlocked:
            return kSecAttrAccessibleWhenUnlocked
        case .afterFirstUnlock:
            return kSecAttrAccessibleAfterFirstUnlock
        case .whenUnlockedThisDeviceOnly:
            return kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        case .afterFirstUnlockThisDeviceOnly:
            return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        }
    }
    
    /// The string representation of the accessibility level
    public var description: String {
        switch self {
        case .whenUnlocked:
            return "whenUnlocked"
        case .afterFirstUnlock:
            return "afterFirstUnlock"
        case .whenUnlockedThisDeviceOnly:
            return "whenUnlockedThisDeviceOnly"
        case .afterFirstUnlockThisDeviceOnly:
            return "afterFirstUnlockThisDeviceOnly"
        }
    }
}