import Foundation
import CryptoKit
import Security

/// Manages all cryptographic operations for Nomos
class CryptoManager {
    static let shared = CryptoManager()
    
    private init() {}
    
    // MARK: - Key Generation & Storage
    
    /// Generates a new 256-bit symmetric key and stores it in Keychain
    func generateAndStoreKey(for nomosId: UUID) throws -> SymmetricKey {
        let key = SymmetricKey(size: .bits256)
        try storeKeyInKeychain(key, for: nomosId)
        return key
    }
    
    /// Stores a symmetric key in the Keychain
    private func storeKeyInKeychain(_ key: SymmetricKey, for nomosId: UUID) throws {
        let keyData = key.withUnsafeBytes { Data($0) }
        
        // Use different accessibility for simulator vs device
        let accessibility: String
        #if targetEnvironment(simulator)
        accessibility = kSecAttrAccessibleWhenUnlocked as String
        #else
        accessibility = kSecAttrAccessibleWhenUnlockedThisDeviceOnly as String
        #endif
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "nomos_key_\(nomosId.uuidString)",
            kSecAttrService as String: "com.nomos.app",
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: accessibility
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw CryptoError.keychainError(status)
        }
    }
    
    /// Retrieves a symmetric key from the Keychain
    func retrieveKeyFromKeychain(for nomosId: UUID) throws -> SymmetricKey {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "nomos_key_\(nomosId.uuidString)",
            kSecAttrService as String: "com.nomos.app",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let keyData = result as? Data else {
            throw CryptoError.keychainError(status)
        }
        
        return SymmetricKey(data: keyData)
    }
    
    /// Permanently deletes a key from the Keychain
    func deleteKeyFromKeychain(for nomosId: UUID) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "nomos_key_\(nomosId.uuidString)",
            kSecAttrService as String: "com.nomos.app"
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw CryptoError.keychainError(status)
        }
    }
    
    // MARK: - Encryption & Decryption
    
    /// Encrypts data using ChaCha20-Poly1305
    func encrypt(data: Data, with key: SymmetricKey) throws -> Data {
        let sealedBox = try ChaChaPoly.seal(data, using: key)
        return sealedBox.combined
    }
    
    /// Decrypts data using ChaCha20-Poly1305
    func decrypt(data: Data, with key: SymmetricKey) throws -> Data {
        let sealedBox = try ChaChaPoly.SealedBox(combined: data)
        return try ChaChaPoly.open(sealedBox, using: key)
    }
    
    // MARK: - High-level Stake Operations
    
    /// Encrypts and stores a stake
    func encryptAndStoreStake(_ stake: Stake, for nomosId: UUID) throws {
        let key = try generateAndStoreKey(for: nomosId)
        let stakeData = try JSONEncoder().encode(stake)
        let encryptedData = try encrypt(data: stakeData, with: key)
        
        let documentsURL = try getDocumentsDirectory()
        let fileURL = documentsURL.appendingPathComponent("stake_\(nomosId.uuidString).enc")
        try encryptedData.write(to: fileURL)
    }
    
    /// Retrieves and decrypts a stake
    func retrieveAndDecryptStake(for nomosId: UUID) throws -> Stake {
        let key = try retrieveKeyFromKeychain(for: nomosId)
        
        let documentsURL = try getDocumentsDirectory()
        let fileURL = documentsURL.appendingPathComponent("stake_\(nomosId.uuidString).enc")
        let encryptedData = try Data(contentsOf: fileURL)
        
        let decryptedData = try decrypt(data: encryptedData, with: key)
        return try JSONDecoder().decode(Stake.self, from: decryptedData)
    }
    
    /// Permanently destroys a stake (deletes key and file)
    func destroyStake(for nomosId: UUID) throws {
        // Delete the key from Keychain
        try deleteKeyFromKeychain(for: nomosId)
        
        // Delete the encrypted file
        let documentsURL = try getDocumentsDirectory()
        let fileURL = documentsURL.appendingPathComponent("stake_\(nomosId.uuidString).enc")
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
    }
    
    // MARK: - Helper Methods
    
    private func getDocumentsDirectory() throws -> URL {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw CryptoError.fileSystemError
        }
        return documentsURL
    }
}

// MARK: - Error Types

enum CryptoError: Error, LocalizedError {
    case keychainError(OSStatus)
    case encryptionError
    case decryptionError
    case fileSystemError
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .keychainError(let status):
            return keychainErrorDescription(for: status)
        case .encryptionError:
            return "Failed to encrypt data"
        case .decryptionError:
            return "Failed to decrypt data"
        case .fileSystemError:
            return "File system error"
        case .invalidData:
            return "Invalid data format"
        }
    }
    
    private func keychainErrorDescription(for status: OSStatus) -> String {
        switch status {
        case errSecDuplicateItem:
            return "Keychain item already exists"
        case errSecItemNotFound:
            return "Keychain item not found"
        case errSecNotAvailable:
            return "Keychain not available"
        case -34018:
            #if targetEnvironment(simulator)
            return "Keychain access restricted in Simulator. Please test on a physical device for full functionality."
            #else
            return "Keychain access denied. Please ensure the app has proper entitlements."
            #endif
        default:
            return "Keychain error: \(status). Please try again or test on a physical device."
        }
    }
}
