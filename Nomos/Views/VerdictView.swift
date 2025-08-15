import SwiftUI

struct VerdictView: View {
    let nomos: Nomos
    let onVerdictSubmitted: (Bool) -> Void
    
    @State private var showingStake = false
    @State private var retrievedStake: Stake?
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            // Background
            DesignSystem.Colors.background
                .ignoresSafeArea()
            
            if showingStake {
                stakeRevealView
            } else {
                verdictSelectionView
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Verdict Selection View
    
    private var verdictSelectionView: some View {
        VStack(spacing: DesignSystem.Spacing.xxxl) {
            Spacer()
            
            // Header
            VStack(spacing: DesignSystem.Spacing.lg) {
                Text("The Verdict.")
                    .font(DesignSystem.Typography.largeTitle)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .multilineTextAlignment(.center)
                
                Text("Time has expired for:")
                    .font(DesignSystem.Typography.callout)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            
            // Rule Display
            Text(nomos.rule)
                .font(DesignSystem.Typography.title2)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, DesignSystem.Spacing.xl)
                .padding(.vertical, DesignSystem.Spacing.lg)
                .glassCard()
                .padding(.horizontal, DesignSystem.Spacing.lg)
            
            Spacer()
            
            // Verdict Buttons
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Success Button
                Button(action: {
                    handleSuccess()
                }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text("I Succeeded")
                    }
                    .frame(maxWidth: .infinity, minHeight: 60)
                }
                .tactileButton(style: .primary)
                .disabled(isLoading)
                
                // Failure Button
                Button(action: {
                    handleFailure()
                }) {
                    Text("I Failed")
                        .frame(maxWidth: .infinity, minHeight: 60)
                }
                .tactileButton(style: .destructive)
                .disabled(isLoading)
            }
            .padding(.horizontal, DesignSystem.Spacing.xl)
            .padding(.bottom, DesignSystem.Spacing.xxxl)
        }
    }
    
    // MARK: - Stake Reveal View
    
    private var stakeRevealView: some View {
        VStack(spacing: DesignSystem.Spacing.xxxl) {
            Spacer()
            
            // Header
            VStack(spacing: DesignSystem.Spacing.lg) {
                Text("Your Word Was Kept.")
                    .font(DesignSystem.Typography.largeTitle)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .multilineTextAlignment(.center)
                
                Text("Your stake is revealed one final time:")
                    .font(DesignSystem.Typography.callout)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            // Stake Content
            if let stake = retrievedStake {
                stakeContentView(stake)
                    .transition(.opacity.combined(with: .scale))
                    .animation(DesignSystem.Animations.spring, value: retrievedStake)
            }
            
            Spacer()
            
            // Continue Button
            Button(action: {
                finalizeSuccess()
            }) {
                Text("Honor Preserved")
                    .frame(maxWidth: .infinity, minHeight: 60)
            }
            .tactileButton(style: .primary)
            .padding(.horizontal, DesignSystem.Spacing.xl)
            .padding(.bottom, DesignSystem.Spacing.xxxl)
        }
    }
    
    private func stakeContentView(_ stake: Stake) -> some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Text(stake.type.displayName)
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.accent)
            
            switch stake.type {
            case .scribesVow:
                if let text = String(data: stake.content, encoding: .utf8) {
                    ScrollView {
                        Text(text)
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                            .padding(DesignSystem.Spacing.lg)
                    }
                    .frame(maxHeight: 300)
                    .glassCard()
                }
                
            case .symbolOfAspiration:
                if let image = UIImage(data: stake.content) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 250, maxHeight: 250)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
                        .shadow(color: DesignSystem.Effects.mediumShadow, radius: 8, x: 0, y: 4)
                }
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
    }
    
    // MARK: - Failure View
    
    private var failureView: some View {
        VStack(spacing: DesignSystem.Spacing.xxxl) {
            Spacer()
            
            VStack(spacing: DesignSystem.Spacing.lg) {
                Text("The Stake Is Forfeited.")
                    .font(DesignSystem.Typography.largeTitle)
                    .foregroundColor(DesignSystem.Colors.destructive)
                    .multilineTextAlignment(.center)
                
                Text("The key has been destroyed. The data is lost.")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            Button(action: {
                onVerdictSubmitted(false)
            }) {
                Text("Accept Judgment")
                    .frame(maxWidth: .infinity, minHeight: 60)
            }
            .tactileButton(style: .destructive)
            .padding(.horizontal, DesignSystem.Spacing.xl)
            .padding(.bottom, DesignSystem.Spacing.xxxl)
        }
    }
    
    // MARK: - Actions
    
    private func handleSuccess() {
        isLoading = true
        
        Task {
            do {
                // Retrieve and decrypt the stake
                let stake = try CryptoManager.shared.retrieveAndDecryptStake(for: nomos.id)
                
                await MainActor.run {
                    self.retrievedStake = stake
                    self.isLoading = false
                    
                    HapticContext.success.trigger()
                    
                    withAnimation(DesignSystem.Animations.spring) {
                        self.showingStake = true
                    }
                }
                
                // Submit success event to backend
                try await BackendService.shared.submitEvent(.upheld)
                
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.showError("Failed to retrieve stake: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func handleFailure() {
        HapticContext.failure.trigger()
        
        Task {
            do {
                // Permanently destroy the stake
                try CryptoManager.shared.destroyStake(for: nomos.id)
                
                // Submit failure event to backend
                try await BackendService.shared.submitEvent(.forfeited)
                
                await MainActor.run {
                    onVerdictSubmitted(false)
                }
                
            } catch {
                await MainActor.run {
                    self.showError("Failed to destroy stake: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func finalizeSuccess() {
        Task {
            do {
                // Clean up the stake after viewing
                try CryptoManager.shared.destroyStake(for: nomos.id)
                
                await MainActor.run {
                    onVerdictSubmitted(true)
                }
                
            } catch {
                await MainActor.run {
                    self.showError("Failed to clean up stake: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}

#Preview {
    let sampleStake = Stake(type: .scribesVow, content: "Dear future self, you did it! You kept your word and proved that you can achieve anything you set your mind to. This moment of success is a testament to your discipline and commitment.".data(using: .utf8) ?? Data())
    let sampleNomos = Nomos(rule: "I will wake up at 6 AM every day for a week", stake: sampleStake)
    
    return VerdictView(nomos: sampleNomos) { success in
        print("Verdict: \(success ? "Success" : "Failure")")
    }
}
