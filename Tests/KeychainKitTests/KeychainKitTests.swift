import XCTest
import Foundation
@testable import KeychainKit

final class KeychainKitTests: XCTestCase {
    
    var keychain: Keychain!
    let testService = "KeychainKitTests_\(UUID().uuidString)"
    
    override func setUp() {
        super.setUp()
        keychain = Keychain(service: testService)
    }
    
    override func tearDown() {
        // Clean up all test data
        try? keychain.removeAll()
        super.tearDown()
    }
    
    // MARK: - Data Tests
    
    func testSetAndGetData() throws {
        let testKey = "testDataKey"
        let testData = "Hello, Keychain!".data(using: .utf8)!
        
        // Set data
        try keychain.set(testData, forKey: testKey)
        
        // Get data
        let retrievedData = try keychain.get(forKey: testKey)
        
        XCTAssertEqual(testData, retrievedData)
    }
    
    func testGetNonexistentData() throws {
        let result = try keychain.get(forKey: "nonexistent_key")
        XCTAssertNil(result)
    }
    
    func testOverwriteExistingData() throws {
        let testKey = "overwriteKey"
        let originalData = "Original".data(using: .utf8)!
        let newData = "Updated".data(using: .utf8)!
        
        // Set original data
        try keychain.set(originalData, forKey: testKey)
        
        // Overwrite with new data
        try keychain.set(newData, forKey: testKey)
        
        // Verify new data was stored
        let retrievedData = try keychain.get(forKey: testKey)
        XCTAssertEqual(newData, retrievedData)
    }
    
    // MARK: - String Tests
    
    func testSetAndGetString() throws {
        let testKey = "testStringKey"
        let testString = "Hello, Keychain String!"
        
        // Set string
        try keychain.set(testString, forKey: testKey)
        
        // Get string
        let retrievedString = try keychain.getString(forKey: testKey)
        
        XCTAssertEqual(testString, retrievedString)
    }
    
    func testGetNonexistentString() throws {
        let result = try keychain.getString(forKey: "nonexistent_string_key")
        XCTAssertNil(result)
    }
    
    // MARK: - Codable Tests
    
    struct TestStruct: Codable, Sendable, Equatable {
        let name: String
        let age: Int
        let isActive: Bool
    }
    
    func testSetAndGetCodable() throws {
        let testKey = "testCodableKey"
        let testObject = TestStruct(name: "John Doe", age: 30, isActive: true)
        
        // Set codable object
        try keychain.set(testObject, forKey: testKey)
        
        // Get codable object
        let retrievedObject = try keychain.get(TestStruct.self, forKey: testKey)
        
        XCTAssertEqual(testObject, retrievedObject)
    }
    
    func testGetNonexistentCodable() throws {
        let result = try keychain.get(TestStruct.self, forKey: "nonexistent_codable_key")
        XCTAssertNil(result)
    }
    
    // MARK: - Remove Tests
    
    func testRemoveItem() throws {
        let testKey = "removeKey"
        let testData = "Remove me".data(using: .utf8)!
        
        // Set data
        try keychain.set(testData, forKey: testKey)
        
        // Verify it exists
        XCTAssertTrue(try keychain.contains(key: testKey))
        
        // Remove it
        try keychain.remove(forKey: testKey)
        
        // Verify it's gone
        XCTAssertFalse(try keychain.contains(key: testKey))
    }
    
    func testRemoveNonexistentItem() throws {
        // This should not throw an error
        try keychain.remove(forKey: "nonexistent_remove_key")
    }
    
    func testRemoveAll() throws {
        // Use a completely separate keychain instance for this test
        let removeAllKeychain = Keychain(service: "RemoveAllTest_\(UUID().uuidString)")
        let keys = ["key1", "key2", "key3"]
        let testData = "Test data".data(using: .utf8)!
        
        // Make sure keychain is clean first
        try removeAllKeychain.removeAll()
        
        // Set multiple items
        for key in keys {
            try removeAllKeychain.set(testData, forKey: key)
        }
        
        // Verify they exist
        for key in keys {
            XCTAssertTrue(try removeAllKeychain.contains(key: key))
        }
        
        // Remove all
        try removeAllKeychain.removeAll()
        
        // Verify individually removed (more reliable than keys() on macOS)
        for key in keys {
            let data = try removeAllKeychain.get(forKey: key)
            XCTAssertNil(data, "Key '\(key)' should return nil after removeAll()")
        }
    }
    
    // MARK: - Contains Tests
    
    func testContainsExistingItem() throws {
        let testKey = "containsKey"
        let testData = "Contains test".data(using: .utf8)!
        
        // Set data
        try keychain.set(testData, forKey: testKey)
        
        // Check if it exists
        XCTAssertTrue(try keychain.contains(key: testKey))
    }
    
    func testContainsNonexistentItem() throws {
        XCTAssertFalse(try keychain.contains(key: "nonexistent_contains_key"))
    }
    
    // MARK: - Keys Tests
    
    func testKeys() throws {
        let testKeys = ["key1", "key2", "key3"]
        let testData = "Key test".data(using: .utf8)!
        
        // Set multiple items
        for key in testKeys {
            try keychain.set(testData, forKey: key)
        }
        
        // Get all keys
        let retrievedKeys = try keychain.keys()
        
        // Verify all test keys are present
        for key in testKeys {
            XCTAssertTrue(retrievedKeys.contains(key))
        }
    }
    
    func testKeysEmptyKeychain() throws {
        let keys = try keychain.keys()
        XCTAssertTrue(keys.isEmpty)
    }
    
    // MARK: - Error Tests
    
    func testErrorDescriptions() {
        let errors: [KeychainError] = [
            .itemNotFound,
            .duplicateItem,
            .authFailed,
            .unexpectedData,
            .unhandled(-25300)
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertNotNil(error.failureReason)
            XCTAssertNotNil(error.recoverySuggestion)
            
            // Ensure descriptions are not empty
            XCTAssertFalse(error.errorDescription?.isEmpty ?? true)
        }
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilityValues() {
        let accessibilities: [KeychainAccessibility] = [
            .whenUnlocked,
            .afterFirstUnlock,
            .whenUnlockedThisDeviceOnly,
            .afterFirstUnlockThisDeviceOnly
        ]
        
        for accessibility in accessibilities {
            // Ensure each accessibility has a valid CFString
            XCTAssertNotNil(accessibility.cfString)
            XCTAssertFalse(accessibility.description.isEmpty)
        }
    }
    
    func testKeychainWithDifferentAccessibility() throws {
        let restrictedKeychain = Keychain(
            service: testService + "_restricted",
            accessibility: .whenUnlockedThisDeviceOnly
        )
        
        let testKey = "restrictedKey"
        let testData = "Restricted data".data(using: .utf8)!
        
        // Set data with restricted accessibility
        try restrictedKeychain.set(testData, forKey: testKey)
        
        // Get data
        let retrievedData = try restrictedKeychain.get(forKey: testKey)
        
        XCTAssertEqual(testData, retrievedData)
        
        // Clean up
        try restrictedKeychain.removeAll()
    }
    
    // MARK: - Default Instance Tests
    
    func testDefaultKeychainInstance() throws {
        let testKey = "defaultInstanceKey"
        let testString = "Default instance test"
        
        // Use default instance
        try Keychain.default.set(testString, forKey: testKey)
        let retrieved = try Keychain.default.getString(forKey: testKey)
        
        XCTAssertEqual(testString, retrieved)
        
        // Clean up
        try Keychain.default.remove(forKey: testKey)
    }
    
    // MARK: - Multiple Keychain Instances Tests
    
    func testMultipleKeychainInstances() throws {
        let keychain1 = Keychain(service: testService + "_1")
        let keychain2 = Keychain(service: testService + "_2")
        
        let testKey = "sharedKey"
        let data1 = "Data from keychain 1".data(using: .utf8)!
        let data2 = "Data from keychain 2".data(using: .utf8)!
        
        // Set different data in each keychain with the same key
        try keychain1.set(data1, forKey: testKey)
        try keychain2.set(data2, forKey: testKey)
        
        // Verify each keychain returns its own data
        let retrieved1 = try keychain1.get(forKey: testKey)
        let retrieved2 = try keychain2.get(forKey: testKey)
        
        XCTAssertEqual(data1, retrieved1)
        XCTAssertEqual(data2, retrieved2)
        XCTAssertNotEqual(retrieved1, retrieved2)
        
        // Clean up
        try keychain1.removeAll()
        try keychain2.removeAll()
    }
    
    // MARK: - Biometric Support Tests
    
    func testBiometricAvailability() {
        // Just test that the methods don't crash
        let isAvailable = Keychain.isBiometricAuthenticationAvailable()
        let biometricType = Keychain.biometricType()
        
        // These methods should return consistent results
        if isAvailable {
            XCTAssertNotNil(biometricType)
        } else {
            XCTAssertNil(biometricType)
        }
    }
    
    // Note: We can't easily test actual biometric operations in unit tests
    // as they require user interaction and physical device capabilities
    
    // MARK: - Performance Tests
    
    func testPerformanceOfMultipleOperations() throws {
        let iterations = 100
        let testData = "Performance test data".data(using: .utf8)!
        
        measure {
            for i in 0..<iterations {
                let key = "perfKey_\(i)"
                do {
                    try keychain.set(testData, forKey: key)
                    let _ = try keychain.get(forKey: key)
                    try keychain.remove(forKey: key)
                } catch {
                    XCTFail("Performance test failed with error: \(error)")
                }
            }
        }
    }
}