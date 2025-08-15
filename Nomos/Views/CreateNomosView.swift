import SwiftUI
import PhotosUI

@MainActor
struct CreateNomosView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CreateNomosViewModel()
    @State private var currentStep: CreateStep = .rule
    @State private var showingImagePicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @FocusState private var isRuleFieldFocused: Bool
    @FocusState private var isTextStakeFieldFocused: Bool
    
    enum CreateStep: Int, CaseIterable {
        case rule = 0
        case stake = 1
        case commitment = 2
        
        var title: String {
            switch self {
            case .rule: return "What is your law?"
            case .stake: return "What is at stake?"
            case .commitment: return "Commit"
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            DesignSystem.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                    .frame(maxWidth: 600)
                
                // Progress indicator
                progressView
                    .frame(maxWidth: 600)
                
                // Content
                TabView(selection: $currentStep) {
                    ruleStepView
                        .tag(CreateStep.rule)
                    stakeStepView
                        .tag(CreateStep.stake)
                    commitmentStepView
                        .tag(CreateStep.commitment)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(DesignSystem.Animations.spring, value: currentStep)
                
                // Navigation
                navigationView
                    .frame(maxWidth: 600)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
                isRuleFieldFocused = false
                isTextStakeFieldFocused = false
            }
        }
        .onAppear {
            viewModel.reset()
        }
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isRuleFieldFocused = false
                    isTextStakeFieldFocused = false
                }
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Button(action: {
                HapticContext.buttonPress.trigger()
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.primaryText)
            }
            
            Spacer()
            
            Text("Create Nomos")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            Spacer()
            
            // Invisible button for symmetry
            Button(action: {}) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.clear)
            }
            .disabled(true)
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.top, DesignSystem.Spacing.md)
    }
    
    // MARK: - Progress View
    
    private var progressView: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            ForEach(CreateStep.allCases, id: \.rawValue) { step in
                Capsule()
                    .fill(step.rawValue <= currentStep.rawValue ? DesignSystem.Colors.accent : DesignSystem.Colors.primaryUI)
                    .frame(height: 4)
                    .animation(DesignSystem.Animations.smooth, value: currentStep)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.vertical, DesignSystem.Spacing.lg)
    }
    
    // MARK: - Step 1: Rule
    
    private var ruleStepView: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.xl) {
                Text(CreateStep.rule.title)
                    .font(DesignSystem.Typography.title1)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .multilineTextAlignment(.center)
                
                TextField("e.g., \"I will wake up at 6 AM.\"", text: $viewModel.rule, axis: .vertical)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .padding(DesignSystem.Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                            .fill(DesignSystem.Colors.primaryUI)
                    )
                    .lineLimit(3...6)
                    .focused($isRuleFieldFocused)
                
                Spacer(minLength: DesignSystem.Spacing.xxl)
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .frame(maxWidth: 600)
        }
        .scrollDismissesKeyboard(.interactively)
    }
    
    // MARK: - Step 2: Stake
    
    private var stakeStepView: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Text(CreateStep.stake.title)
                .font(DesignSystem.Typography.title1)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .multilineTextAlignment(.center)
            
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Scribe's Vow Button
                Button(action: {
                    HapticContext.buttonPress.trigger()
                    viewModel.selectedStakeType = .scribesVow
                }) {
                    Text(StakeType.scribesVow.displayName)
                        .frame(maxWidth: .infinity)
                }
                .tactileButton(style: viewModel.selectedStakeType == .scribesVow ? .primary : .secondary)
                
                // Symbol of Aspiration Button
                Button(action: {
                    HapticContext.buttonPress.trigger()
                    viewModel.selectedStakeType = .symbolOfAspiration
                }) {
                    Text(StakeType.symbolOfAspiration.displayName)
                        .frame(maxWidth: .infinity)
                }
                .tactileButton(style: viewModel.selectedStakeType == .symbolOfAspiration ? .primary : .secondary)
            }
            
            // Conditional content based on selection
            if let stakeType = viewModel.selectedStakeType {
                stakeContentView(for: stakeType)
            }
            
            Spacer()
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
    }
    
    private func stakeContentView(for stakeType: StakeType) -> some View {
        Group {
            switch stakeType {
            case .scribesVow:
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    Text("Write a letter to the self who succeeds.")
                        .font(DesignSystem.Typography.callout)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    TextField("Dear future self...", text: $viewModel.textStake, axis: .vertical)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                        .padding(DesignSystem.Spacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                                .fill(DesignSystem.Colors.primaryUI)
                        )
                        .lineLimit(5...10)
                        .focused($isTextStakeFieldFocused)
                }
                
            case .symbolOfAspiration:
                VStack(spacing: DesignSystem.Spacing.md) {
                    Text("Capture a symbol of your aspiration.")
                        .font(DesignSystem.Typography.callout)
                        .foregroundColor(DesignSystem.Colors.secondaryText)

                    // Button to present the system picker (avoids Sendable/actor issues)
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                        photoPickerContent
                    }
                    .frame(width: 160, height: 160)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                            .fill(DesignSystem.Colors.primaryUI)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                                    .stroke(DesignSystem.Colors.accent, style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                            )
                    )
                    .onChange(of: selectedPhotoItem) { _, newItem in
                        Task { @MainActor in
                            await viewModel.loadImage(from: newItem)
                        }
                    }
                }
            }
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
        .animation(DesignSystem.Animations.spring, value: stakeType)
    }
    
    // MARK: - Step 3: Commitment
    
    private var commitmentStepView: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Text("The Commitment")
                .font(DesignSystem.Typography.title1)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .multilineTextAlignment(.center)
            
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Rule summary
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("Your Law:")
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.accent)
                    
                    Text(viewModel.rule)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                        .padding(DesignSystem.Spacing.md)
                        .glassCard()
                }
                
                // Stake summary
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("Your Stake:")
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.accent)
                    
                    if let stakeType = viewModel.selectedStakeType {
                        Text(stakeType.displayName)
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                            .padding(DesignSystem.Spacing.md)
                            .glassCard()
                    }
                }
            }
            
            Spacer()
            
            // Commitment button
            Button(action: {
                Task {
                    await viewModel.commitNomos()
                }
            }) {
                if viewModel.isCommitting {
                    HStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                        Text("Committing...")
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    Text("Commit")
                        .frame(maxWidth: .infinity)
                }
            }
            .tactileButton(style: .primary)
            .disabled(viewModel.isCommitting || !viewModel.canCommit)
            .opacity(viewModel.canCommit ? 1.0 : 0.6)
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .onReceive(viewModel.$commitmentSucceeded) { succeeded in
            if succeeded {
                HapticContext.success.trigger()
                dismiss()
            }
        }
    }
    
    // MARK: - Navigation
    
    private var navigationView: some View {
        HStack {
            // Back button
            if currentStep.rawValue > 0 {
                Button("Back") {
                    HapticContext.buttonPress.trigger()
                    withAnimation(DesignSystem.Animations.spring) {
                        currentStep = CreateStep(rawValue: currentStep.rawValue - 1) ?? .rule
                    }
                }
                .tactileButton(style: .secondary)
            } else {
                Spacer()
            }
            
            Spacer()
            
            // Next button
            if currentStep != .commitment {
                Button("Next") {
                    HapticContext.buttonPress.trigger()
                    withAnimation(DesignSystem.Animations.spring) {
                        currentStep = CreateStep(rawValue: currentStep.rawValue + 1) ?? .commitment
                    }
                }
                .tactileButton(style: .primary)
                .disabled(!canProceed)
                .opacity(canProceed ? 1.0 : 0.6)
            } else {
                Spacer()
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.bottom, DesignSystem.Spacing.xl)
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case .rule:
            return !viewModel.rule.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .stake:
            return viewModel.hasValidStake
        case .commitment:
            return true
        }
    }
    
    @MainActor
    private var photoPickerContent: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            if let selectedImage = viewModel.selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                
                Text("Tap to change")
                    .font(DesignSystem.Typography.footnote)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            } else {
                Image(systemName: "camera")
                    .font(.system(size: 40))
                    .foregroundColor(DesignSystem.Colors.accent)
                
                Text("Tap to capture")
                    .font(DesignSystem.Typography.callout)
                    .foregroundColor(DesignSystem.Colors.accent)
            }
        }
    }
}

#Preview {
    CreateNomosView()
}
