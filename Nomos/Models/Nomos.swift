import Foundation

/// Represents a complete Nomos (law + stake + commitment)
struct Nomos: Codable, Identifiable {
    let id: UUID
    let rule: String
    let stake: Stake
    let createdAt: Date
    let expiresAt: Date
    let isActive: Bool
    let isResolved: Bool
    let wasUpheld: Bool?
    
    init(rule: String, stake: Stake, duration: TimeInterval = 24 * 60 * 60) { // Default 24 hours
        self.id = UUID()
        self.rule = rule
        self.stake = stake
        self.createdAt = Date()
        self.expiresAt = Date().addingTimeInterval(duration)
        self.isActive = true
        self.isResolved = false
        self.wasUpheld = nil
    }
    
    /// Time remaining until expiration
    var timeRemaining: TimeInterval {
        max(0, expiresAt.timeIntervalSinceNow)
    }
    
    /// Whether this Nomos has expired
    var hasExpired: Bool {
        Date() >= expiresAt
    }
    
    /// Formatted time remaining string
    var timeRemainingFormatted: String {
        let remaining = timeRemaining
        let hours = Int(remaining) / 3600
        let minutes = Int(remaining.truncatingRemainder(dividingBy: 3600)) / 60
        let seconds = Int(remaining.truncatingRemainder(dividingBy: 60))
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

/// Anonymous event for the Agora feed
struct AgoraEvent: Codable, Identifiable {
    let id: UUID
    let eventType: EventType
    let timezone: String
    let timestamp: Date
    
    enum EventType: String, Codable {
        case committed
        case upheld
        case forfeited
        
        var displayText: String {
            switch self {
            case .committed:
                return "A Nomos was committed to."
            case .upheld:
                return "A Nomos was upheld."
            case .forfeited:
                return "A Stake was forfeited."
            }
        }
    }
}
