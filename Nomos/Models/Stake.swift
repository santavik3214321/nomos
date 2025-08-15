import Foundation

/// Represents the data at stake in a Nomos
enum StakeType: String, Codable, CaseIterable {
    case scribesVow = "scribes_vow"
    case symbolOfAspiration = "symbol_of_aspiration"
    
    var displayName: String {
        switch self {
        case .scribesVow:
            return "The Scribe's Vow"
        case .symbolOfAspiration:
            return "The Symbol of Aspiration"
        }
    }
}

struct Stake: Codable, Equatable {
    let id: UUID
    let type: StakeType
    let content: Data // Encrypted content (text or image data)
    let createdAt: Date
    
    init(type: StakeType, content: Data) {
        self.id = UUID()
        self.type = type
        self.content = content
        self.createdAt = Date()
    }
    
    static func == (lhs: Stake, rhs: Stake) -> Bool {
        return lhs.id == rhs.id
    }
}
