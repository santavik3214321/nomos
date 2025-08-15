import SwiftUI
import PhotosUI
import Combine

/// ViewModel for the Create Nomos flow
@MainActor
class CreateNomosViewModel: ObservableObject {
    @Published var rule: String = ""
    @Published var selectedStakeType: StakeType?
    @Published var textStake: String = ""
    @Published var selectedImage: UIImage?
    @Published var isCommitting: Bool = false
    @Published var commitmentSucceeded: Bool = false
    @Published var showingError: Bool = false
    @Published var errorMessage: String = ""
    
    private let cryptoManager = CryptoManager.shared
    private let backendService = BackendService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var hasValidStake: Bool {
        guard let stakeType = selectedStakeType else { return false }
        
        switch stakeType {
        case .scribesVow:
            return !textStake.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .symbolOfAspiration:
            return selectedImage != nil
        }
    }
    
    var canCommit: Bool {
        return !rule.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && hasValidStake
    }
    
    // MARK: - Actions
    
    func reset() {
        rule = ""
        selectedStakeType = nil
        textStake = ""
        selectedImage = nil
        isCommitting = false
        commitmentSucceeded = false
        showingError = false
        errorMessage = ""
    }
    
    func loadImage(from item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                selectedImage = image
            }
        } catch {
            showError("Failed to load image: \(error.localizedDescription)")
        }
    }
    
    func commitNomos() async {
        guard canCommit, let stakeType = selectedStakeType else { return }
        
        isCommitting = true
        
        do {
            // Create stake data
            let stakeData: Data
            switch stakeType {
            case .scribesVow:
                stakeData = textStake.data(using: .utf8) ?? Data()
            case .symbolOfAspiration:
                guard let image = selectedImage,
                      let imageData = image.jpegData(compressionQuality: 0.8) else {
                    throw CreateNomosError.invalidStakeData
                }
                stakeData = imageData
            }
            
            // Create stake
            let stake = Stake(type: stakeType, content: stakeData)
            
            // Create nomos
            let nomos = Nomos(rule: rule, stake: stake)
            
            // Encrypt and store the stake
            try cryptoManager.encryptAndStoreStake(stake, for: nomos.id)
            
            // Store the nomos in UserDefaults (unencrypted metadata)
            try storeNomos(nomos)
            
            // Submit anonymous event to backend
            try await backendService.submitEvent(.committed)
            
            // Trigger commitment haptic
            HapticContext.commitment.trigger()
            
            commitmentSucceeded = true
            
        } catch {
            showError("Failed to commit Nomos: \(error.localizedDescription)")
        }
        
        isCommitting = false
    }
    
    // MARK: - Private Methods
    
    private func storeNomos(_ nomos: Nomos) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(nomos)
        UserDefaults.standard.set(data, forKey: "active_nomos")
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
        HapticContext.failure.trigger()
    }
}

// MARK: - Error Types

enum CreateNomosError: Error, LocalizedError {
    case invalidStakeData
    case encryptionFailed
    case storageFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidStakeData:
            return "Invalid stake data"
        case .encryptionFailed:
            return "Failed to encrypt stake"
        case .storageFailed:
            return "Failed to store nomos"
        }
    }
}
