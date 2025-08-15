# Nomos

**The law you write for yourself.**

Nomos is a deeply private commitment app that embodies the philosophy of "Tactile Minimalism." It allows users to create personal laws (rules), commit to stakes that have meaning only to them, and use cryptographic security to enforce the consequences of their commitments.

## Philosophy

- **Private by Design**: All stakes are encrypted locally using Apple's CryptoKit. The app is built around the principle that your word is the only verification needed.
- **Tactile Minimalism**: Clean, respectful interfaces with subtle depth, texture, and comprehensive haptic feedback.
- **Cryptographic Stakes**: Upon commitment, stakes are encrypted with a random 256-bit key stored in the device's Keychain. Success reveals the stake; failure permanently destroys the key, making the data unrecoverable.

## Features

### Core Functionality
- **Rule Creation**: Define clear, personal laws
- **Stake Commitment**: Choose between "The Scribe's Vow" (text) or "The Symbol of Aspiration" (photo)
- **Cryptographic Security**: Military-grade encryption using ChaCha20-Poly1305
- **Private Judgment**: Only you decide success or failure
- **Anonymous Feed**: See anonymous echoes of commitment from around the world

### Technical Features
- **SwiftUI Interface**: Modern, fluid animations with physics-based transitions
- **Core Haptics**: Extensive haptic feedback for every interaction
- **Secure Storage**: Keychain integration for key management
- **Anonymous Backend**: Privacy-preserving event sharing
- **Comprehensive Testing**: Unit tests for all critical functionality

## Architecture

### Views
- `OnboardingView`: Three-screen introduction to the app philosophy
- `AgoraView`: Main feed showing anonymous commitment events
- `CreateNomosView`: Three-step process for creating commitments
- `ActiveNomosView`: Countdown screen with timer and progress ring
- `VerdictView`: Success/failure judgment with stake revelation

### Services
- `CryptoManager`: Handles all encryption/decryption and key management
- `HapticsManager`: Manages Core Haptics feedback throughout the app
- `BackendService`: Anonymous event submission and retrieval
- `DesignSystem`: Centralized design tokens and modifiers

### Models
- `Nomos`: Core commitment model with rule and stake
- `Stake`: Encrypted data container for user commitments
- `AgoraEvent`: Anonymous events for the public feed

## Security Model

1. **Key Generation**: 256-bit symmetric keys generated using CryptoKit
2. **Encryption**: ChaCha20-Poly1305 authenticated encryption
3. **Key Storage**: iOS Keychain with device-only accessibility
4. **Success Path**: Key retrieval → decryption → one-time viewing → destruction
5. **Failure Path**: Immediate key destruction → permanent data loss

## Design System

### Colors
- Background: `#121212` (off-black)
- Primary UI: `#1C1C1E` (textured dark gray)
- Primary Text: `#EAEAEA` (soft off-white)
- Accent: `#0A84FF` (electric blue)
- Destructive: `#C70039` (muted deep red)

### Typography
- Primary: Satoshi (Medium/Bold weights)
- Fallback: San Francisco system font
- Monospace timer display for countdown

### Interactions
- Spring-based animations (physics-based, not snappy)
- Extensive Core Haptics integration
- Tactile button responses with visual feedback

## Requirements

- iOS 17.0+
- Swift 5.10+
- Device with haptic feedback support recommended

## Installation

1. Open the project in Xcode
2. Ensure your development team is set
3. Build and run on device (haptics require physical device)

## Backend Setup

The app includes a backend service interface that expects:

### Endpoints
- `POST /api/event` - Submit anonymous events
- `GET /api/events` - Retrieve recent events

### Event Data
```json
{
  "eventType": "committed" | "upheld" | "forfeited",
  "timezone": "UTC+4"
}
```

For development, the app will fallback to mock data if the backend is unavailable.

## Testing

Run the test suite to verify:
- Encryption/decryption functionality
- Key generation and storage
- Model creation and validation
- Core business logic

```bash
cmd+u in Xcode
```

## Privacy

Nomos is designed with privacy as the core principle:

- No user accounts or identifiable information
- All personal data encrypted locally
- Anonymous-only backend communication
- No analytics or tracking
- Complete data sovereignty

## License

This project is a template implementation of the Nomos concept. Use responsibly and in accordance with your local laws and regulations.

---

*"Your word is your bond."*
# nomos
