import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var isCompleted = false
    
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Background
            DesignSystem.Colors.background
                .ignoresSafeArea()
            
            TabView(selection: $currentPage) {
                // Screen 1
                OnboardingPageView(
                    headline: "Nomos.",
                    body: "The law you write for yourself.",
                    showButton: false
                )
                .tag(0)
                
                // Screen 2
                OnboardingPageView(
                    headline: "Make a promise.",
                    body: "Define a single, clear rule. Commit to a stake that has meaning only to you.",
                    showButton: false
                )
                .tag(1)
                
                // Screen 3
                OnboardingPageView(
                    headline: "Be your own judge.",
                    body: "Your word is the only verification. This is a private contract.",
                    showButton: true,
                    buttonText: "Begin",
                    buttonAction: {
                        HapticContext.commitment.trigger()
                        withAnimation(DesignSystem.Animations.spring) {
                            isCompleted = true
                        }
                        
                        // Delay completion to allow animation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            onComplete()
                        }
                    }
                )
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .indexViewStyle(.page(backgroundDisplayMode: .never))
            .onAppear {
                setupPageControlAppearance()
            }
            .scaleEffect(isCompleted ? 0.95 : 1.0)
            .opacity(isCompleted ? 0 : 1)
            .animation(DesignSystem.Animations.spring, value: isCompleted)
        }
    }
    
    private func setupPageControlAppearance() {
        UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(DesignSystem.Colors.accent)
        UIPageControl.appearance().pageIndicatorTintColor = UIColor(DesignSystem.Colors.primaryText.opacity(0.3))
    }
}

struct OnboardingPageView: View {
    let headline: String
    let bodyText: String
    let showButton: Bool
    let buttonText: String?
    let buttonAction: (() -> Void)?
    
    init(
        headline: String,
        body: String,
        showButton: Bool = false,
        buttonText: String? = nil,
        buttonAction: (() -> Void)? = nil
    ) {
        self.headline = headline
        self.bodyText = body
        self.showButton = showButton
        self.buttonText = buttonText
        self.buttonAction = buttonAction
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xxxl) {
            Spacer()
            
            VStack(spacing: DesignSystem.Spacing.xl) {
                // Headline
                Text(headline)
                    .font(DesignSystem.Typography.largeTitle)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .multilineTextAlignment(.center)
                
                // Body
                Text(bodyText)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, DesignSystem.Spacing.xl)
            
            Spacer()
            
            // Button (only on last screen)
            if showButton, let buttonText = buttonText, let buttonAction = buttonAction {
                Button(action: buttonAction) {
                    Text(buttonText)
                        .frame(maxWidth: .infinity)
                }
                .tactileButton(style: .primary)
                .padding(.horizontal, DesignSystem.Spacing.xl)
                .padding(.bottom, DesignSystem.Spacing.xxxl)
            } else {
                // Placeholder to maintain consistent spacing
                Color.clear
                    .frame(height: 60)
                    .padding(.bottom, DesignSystem.Spacing.xxxl)
            }
        }
    }
}

#Preview {
    OnboardingView {
        print("Onboarding completed")
    }
}
