import SwiftUI

/// Tactile Minimalism Design System
struct DesignSystem {
    
    // MARK: - Colors
    struct Colors {
        static let background = Color(hex: "#121212")
        static let primaryUI = Color(hex: "#1C1C1E")
        static let primaryText = Color(hex: "#EAEAEA")
        static let accent = Color(hex: "#0A84FF")
        static let destructive = Color(hex: "#C70039")
        
        // Additional utility colors
        static let secondaryText = Color(hex: "#EAEAEA").opacity(0.7)
        static let disabled = Color(hex: "#EAEAEA").opacity(0.3)
    }
    
    // MARK: - Typography
    struct Typography {
        static let largeTitle = Font.custom("Satoshi-Bold", size: 34, relativeTo: .largeTitle)
        static let title1 = Font.custom("Satoshi-Bold", size: 28, relativeTo: .title)
        static let title2 = Font.custom("Satoshi-Bold", size: 22, relativeTo: .title2)
        static let title3 = Font.custom("Satoshi-Bold", size: 20, relativeTo: .title3)
        static let headline = Font.custom("Satoshi-Bold", size: 17, relativeTo: .headline)
        static let body = Font.custom("Satoshi-Medium", size: 17, relativeTo: .body)
        static let callout = Font.custom("Satoshi-Medium", size: 16, relativeTo: .callout)
        static let subheadline = Font.custom("Satoshi-Medium", size: 15, relativeTo: .subheadline)
        static let footnote = Font.custom("Satoshi-Medium", size: 13, relativeTo: .footnote)
        static let caption = Font.custom("Satoshi-Medium", size: 12, relativeTo: .caption)
        
        // Fallback fonts if Satoshi is not available
        static let bodyFallback = Font.system(size: 17, weight: .medium, design: .default)
        static let headlineFallback = Font.system(size: 17, weight: .bold, design: .default)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        static let xxxl: CGFloat = 64
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
    }
    
    // MARK: - Shadows & Effects
    struct Effects {
        static let subtleShadow = Color.black.opacity(0.1)
        static let mediumShadow = Color.black.opacity(0.2)
        static let strongShadow = Color.black.opacity(0.3)
        
        static let glassEffect = VisualEffect(style: .systemUltraThinMaterialDark)
    }
    
    // MARK: - Animations
    struct Animations {
        static let spring = Animation.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)
        static let easeInOut = Animation.easeInOut(duration: 0.3)
        static let smooth = Animation.smooth(duration: 0.4)
    }
}

// MARK: - Custom View Modifiers

struct GlassCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                    .fill(DesignSystem.Colors.primaryUI)
                    .shadow(color: DesignSystem.Effects.subtleShadow, radius: 8, x: 0, y: 4)
            )
    }
}

struct TactileButtonModifier: ViewModifier {
    let style: ButtonStyle
    @State private var isPressed = false
    
    enum ButtonStyle {
        case primary
        case destructive
        case secondary
        
        var backgroundColor: Color {
            switch self {
            case .primary:
                return DesignSystem.Colors.accent
            case .destructive:
                return DesignSystem.Colors.destructive
            case .secondary:
                return DesignSystem.Colors.primaryUI
            }
        }
        
        var textColor: Color {
            switch self {
            case .primary, .destructive:
                return .white
            case .secondary:
                return DesignSystem.Colors.primaryText
            }
        }
    }
    
    func body(content: Content) -> some View {
        content
            .font(DesignSystem.Typography.headline)
            .foregroundColor(style.textColor)
            .padding(.vertical, DesignSystem.Spacing.md)
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .fill(style.backgroundColor)
                    .scaleEffect(isPressed ? 0.98 : 1.0)
                    .shadow(color: DesignSystem.Effects.mediumShadow, radius: isPressed ? 2 : 6, x: 0, y: isPressed ? 1 : 3)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(DesignSystem.Animations.spring, value: isPressed)
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                isPressed = pressing
            }, perform: {})
    }
}

// MARK: - View Extensions

extension View {
    func glassCard() -> some View {
        self.modifier(GlassCardModifier())
    }
    
    func tactileButton(style: TactileButtonModifier.ButtonStyle = .primary) -> some View {
        self.modifier(TactileButtonModifier(style: style))
    }
}

// MARK: - Color Extension for Hex Support

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Visual Effect (Glass Effect)

struct VisualEffect: UIViewRepresentable {
    let style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}
