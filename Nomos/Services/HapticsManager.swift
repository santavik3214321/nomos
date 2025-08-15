import Foundation
import CoreHaptics
import UIKit

/// Manages haptic feedback throughout the app
class HapticsManager: ObservableObject {
    static let shared = HapticsManager()
    
    private var hapticEngine: CHHapticEngine?
    private let impactGenerator = UIImpactFeedbackGenerator()
    private let notificationGenerator = UINotificationFeedbackGenerator()
    
    private init() {
        setupHapticEngine()
    }
    
    // MARK: - Setup
    
    private func setupHapticEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            print("Device doesn't support haptics")
            return
        }
        
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            print("Failed to start haptic engine: \(error)")
        }
    }
    
    // MARK: - Simple Haptics (Fallback)
    
    /// Soft impact for button presses
    func softImpact() {
        impactGenerator.impactOccurred(intensity: 0.5)
    }
    
    /// Medium impact for selections
    func mediumImpact() {
        impactGenerator.impactOccurred(intensity: 0.7)
    }
    
    /// Rigid impact for major commitments
    func rigidImpact() {
        impactGenerator.impactOccurred(intensity: 1.0)
    }
    
    /// Success notification
    func successNotification() {
        notificationGenerator.notificationOccurred(.success)
    }
    
    /// Error notification
    func errorNotification() {
        notificationGenerator.notificationOccurred(.error)
    }
    
    /// Warning notification
    func warningNotification() {
        notificationGenerator.notificationOccurred(.warning)
    }
    
    // MARK: - Core Haptics (Advanced)
    
    /// Creates a custom haptic pattern for button press
    func buttonPress() {
        guard hapticEngine != nil else {
            softImpact()
            return
        }
        
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
        
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [intensity, sharpness],
            relativeTime: 0
        )
        
        playHapticPattern([event])
    }
    
    /// Creates a custom haptic pattern for commitment action
    func commitment() {
        guard hapticEngine != nil else {
            rigidImpact()
            return
        }
        
        // Create a complex pattern: strong initial hit, followed by a subtle confirmation
        let strongIntensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
        let strongSharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
        
        let subtleIntensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4)
        let subtleSharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
        
        let initialHit = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [strongIntensity, strongSharpness],
            relativeTime: 0
        )
        
        let confirmation = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [subtleIntensity, subtleSharpness],
            relativeTime: 0.15
        )
        
        playHapticPattern([initialHit, confirmation])
    }
    
    /// Creates a custom haptic pattern for success
    func success() {
        guard hapticEngine != nil else {
            successNotification()
            return
        }
        
        // Create an uplifting pattern: gentle rise and peak
        let events = [
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                ],
                relativeTime: 0
            ),
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                ],
                relativeTime: 0.1
            ),
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
                ],
                relativeTime: 0.2
            )
        ]
        
        playHapticPattern(events)
    }
    
    /// Creates a custom haptic pattern for failure
    func failure() {
        guard hapticEngine != nil else {
            errorNotification()
            return
        }
        
        // Create a declining pattern: strong hit, fade to nothing
        let events = [
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
                ],
                relativeTime: 0
            ),
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                ],
                relativeTime: 0.08
            ),
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                ],
                relativeTime: 0.16
            )
        ]
        
        playHapticPattern(events)
    }
    
    /// Creates a subtle ticking haptic for timer countdown
    func timerTick() {
        guard hapticEngine != nil else {
            return // No fallback for timer ticks
        }
        
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.2)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
        
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [intensity, sharpness],
            relativeTime: 0
        )
        
        playHapticPattern([event])
    }
    
    // MARK: - Private Helpers
    
    private func playHapticPattern(_ events: [CHHapticEvent]) {
        guard let hapticEngine = hapticEngine else { return }
        
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try hapticEngine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Failed to play haptic pattern: \(error)")
        }
    }
}

// MARK: - Haptic Context Enum

enum HapticContext {
    case buttonPress
    case commitment
    case success
    case failure
    case navigation
    case timerTick
    
    func trigger() {
        let haptics = HapticsManager.shared
        
        switch self {
        case .buttonPress:
            haptics.buttonPress()
        case .commitment:
            haptics.commitment()
        case .success:
            haptics.success()
        case .failure:
            haptics.failure()
        case .navigation:
            haptics.mediumImpact()
        case .timerTick:
            haptics.timerTick()
        }
    }
}
