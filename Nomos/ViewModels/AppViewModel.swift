import SwiftUI
import Combine

/// Main app state manager
@MainActor
class AppViewModel: ObservableObject {
    @Published var appState: AppState = .loading
    @Published var activeNomos: Nomos?
    @Published var hasCompletedOnboarding: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    enum AppState: Equatable {
        case loading
        case onboarding
        case agora
        case activeNomos(Nomos)
        case verdict(Nomos)
        
        static func == (lhs: AppState, rhs: AppState) -> Bool {
            switch (lhs, rhs) {
            case (.loading, .loading), (.onboarding, .onboarding), (.agora, .agora):
                return true
            case (.activeNomos(let lhsNomos), .activeNomos(let rhsNomos)):
                return lhsNomos.id == rhsNomos.id
            case (.verdict(let lhsNomos), .verdict(let rhsNomos)):
                return lhsNomos.id == rhsNomos.id
            default:
                return false
            }
        }
    }
    
    init() {
        loadAppState()
        setupTimers()
    }
    
    // MARK: - State Management
    
    private func loadAppState() {
        // Check onboarding status
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "has_completed_onboarding")
        
        // Load active nomos if exists
        if let nomosData = UserDefaults.standard.data(forKey: "active_nomos") {
            do {
                let nomos = try JSONDecoder().decode(Nomos.self, from: nomosData)
                activeNomos = nomos
                
                if nomos.hasExpired {
                    appState = .verdict(nomos)
                } else {
                    appState = .activeNomos(nomos)
                }
            } catch {
                // If we can't decode, clear the corrupted data
                UserDefaults.standard.removeObject(forKey: "active_nomos")
                determineInitialState()
            }
        } else {
            determineInitialState()
        }
    }
    
    private func determineInitialState() {
        if hasCompletedOnboarding {
            appState = .agora
        } else {
            appState = .onboarding
        }
    }
    
    private func setupTimers() {
        // Check for expired nomos every minute
        Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            Task { @MainActor in
                self.checkForExpiredNomos()
            }
        }
    }
    
    private func checkForExpiredNomos() {
        guard let nomos = activeNomos,
              case .activeNomos = appState,
              nomos.hasExpired else { return }
        
        appState = .verdict(nomos)
    }
    
    // MARK: - Navigation Actions
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "has_completed_onboarding")
        appState = .agora
    }
    
    func nomosCreated() {
        // Reload active nomos from storage
        if let nomosData = UserDefaults.standard.data(forKey: "active_nomos") {
            do {
                let nomos = try JSONDecoder().decode(Nomos.self, from: nomosData)
                activeNomos = nomos
                appState = .activeNomos(nomos)
            } catch {
                print("Failed to load newly created nomos: \(error)")
                appState = .agora
            }
        }
    }
    
    func verdictSubmitted(success: Bool) {
        // Clear active nomos
        activeNomos = nil
        UserDefaults.standard.removeObject(forKey: "active_nomos")
        
        // Return to agora
        appState = .agora
        
        // Trigger appropriate haptic
        if success {
            HapticContext.success.trigger()
        } else {
            HapticContext.failure.trigger()
        }
    }
    
    // MARK: - Utility Methods
    
    func resetApp() {
        // Clear all data (for development/debugging)
        UserDefaults.standard.removeObject(forKey: "has_completed_onboarding")
        UserDefaults.standard.removeObject(forKey: "active_nomos")
        
        // Clean up any orphaned encrypted files
        cleanupOrphanedFiles()
        
        hasCompletedOnboarding = false
        activeNomos = nil
        appState = .onboarding
    }
    
    private func cleanupOrphanedFiles() {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            let encryptedFiles = files.filter { $0.pathExtension == "enc" }
            
            for file in encryptedFiles {
                try? FileManager.default.removeItem(at: file)
            }
        } catch {
            print("Failed to cleanup orphaned files: \(error)")
        }
    }
}
