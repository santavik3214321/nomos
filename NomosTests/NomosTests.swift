import XCTest
@testable import Nomos

final class NomosTests: XCTestCase {
    
    func testNomosCreation() {
        let stake = Stake(type: .scribesVow, content: "Test content".data(using: .utf8) ?? Data())
        let nomos = Nomos(rule: "Test rule", stake: stake)
        
        XCTAssertEqual(nomos.rule, "Test rule")
        XCTAssertEqual(nomos.stake.type, .scribesVow)
        XCTAssertTrue(nomos.isActive)
        XCTAssertFalse(nomos.isResolved)
        XCTAssertNil(nomos.wasUpheld)
    }
    
    func testStakeTypeDisplayNames() {
        XCTAssertEqual(StakeType.scribesVow.displayName, "The Scribe's Vow")
        XCTAssertEqual(StakeType.symbolOfAspiration.displayName, "The Symbol of Aspiration")
    }
    
    func testAgoraEventDisplayText() {
        XCTAssertEqual(AgoraEvent.EventType.committed.displayText, "A Nomos was committed to.")
        XCTAssertEqual(AgoraEvent.EventType.upheld.displayText, "A Nomos was upheld.")
        XCTAssertEqual(AgoraEvent.EventType.forfeited.displayText, "A Stake was forfeited.")
    }
    
    func testNomosTimeRemaining() {
        let stake = Stake(type: .scribesVow, content: Data())
        let nomos = Nomos(rule: "Test", stake: stake, duration: 3600) // 1 hour
        
        XCTAssertGreaterThan(nomos.timeRemaining, 0)
        XCTAssertLessThanOrEqual(nomos.timeRemaining, 3600)
        XCTAssertFalse(nomos.hasExpired)
    }
    
    func testCryptoManagerKeyGeneration() async throws {
        let cryptoManager = CryptoManager.shared
        let testId = UUID()
        
        // Generate and store a key
        let key = try cryptoManager.generateAndStoreKey(for: testId)
        
        // Retrieve the key
        let retrievedKey = try cryptoManager.retrieveKeyFromKeychain(for: testId)
        
        // Keys should be equivalent (same data)
        let originalData = key.withUnsafeBytes { Data($0) }
        let retrievedData = retrievedKey.withUnsafeBytes { Data($0) }
        XCTAssertEqual(originalData, retrievedData)
        
        // Clean up
        try cryptoManager.deleteKeyFromKeychain(for: testId)
    }
    
    func testEncryptionDecryption() throws {
        let cryptoManager = CryptoManager.shared
        let testData = "Hello, Nomos!".data(using: .utf8)!
        let testId = UUID()
        
        // Generate a key
        let key = try cryptoManager.generateAndStoreKey(for: testId)
        
        // Encrypt
        let encryptedData = try cryptoManager.encrypt(data: testData, with: key)
        
        // Decrypt
        let decryptedData = try cryptoManager.decrypt(data: encryptedData, with: key)
        
        XCTAssertEqual(testData, decryptedData)
        XCTAssertNotEqual(testData, encryptedData)
        
        // Clean up
        try cryptoManager.deleteKeyFromKeychain(for: testId)
    }
}
