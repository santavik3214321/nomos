import SwiftUI

@main
struct NomosApp: App {
    @StateObject private var appViewModel = AppViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appViewModel)
                .preferredColorScheme(.dark) // Force dark mode for Tactile Minimalism
        }
    }
}

@MainActor
struct ContentView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    
    var body: some View {
        ZStack {
            // Global background
            DesignSystem.Colors.background
                .ignoresSafeArea()
            
            // Content based on app state
            switch appViewModel.appState {
            case .loading:
                LoadingView()
                
            case .onboarding:
                OnboardingView {
                    appViewModel.completeOnboarding()
                }
                
            case .agora:
                AgoraView()
                    .onReceive(NotificationCenter.default.publisher(for: .nomosCreated)) { _ in
                        appViewModel.nomosCreated()
                    }
                
            case .activeNomos(let nomos):
                ActiveNomosView(nomos: nomos) {
                    // Nomos expired, transition to verdict
                    appViewModel.appState = .verdict(nomos)
                }
                
            case .verdict(let nomos):
                VerdictView(nomos: nomos) { success in
                    appViewModel.verdictSubmitted(success: success)
                }
            }
        }
        .animation(DesignSystem.Animations.spring, value: appViewModel.appState)
    }
}

// MARK: - Loading View

struct LoadingView: View {
    @State private var opacity: Double = 0.3
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Text("Nomos")
                .font(DesignSystem.Typography.largeTitle)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .opacity(opacity)
                .onAppear {
                    withAnimation(
                        Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)
                    ) {
                        opacity = 1.0
                    }
                }
            
            Text("Loading...")
                .font(DesignSystem.Typography.callout)
                .foregroundColor(DesignSystem.Colors.secondaryText)
        }
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let nomosCreated = Notification.Name("nomosCreated")
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(AppViewModel())
}
