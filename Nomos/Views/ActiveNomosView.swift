import SwiftUI
import Combine

struct ActiveNomosView: View {
    let nomos: Nomos
    let onExpired: () -> Void
    
    @State private var timeRemaining: TimeInterval
    @State private var timer: Timer?
    @State private var lastTickTime: Date = Date()
    
    init(nomos: Nomos, onExpired: @escaping () -> Void) {
        self.nomos = nomos
        self.onExpired = onExpired
        self._timeRemaining = State(initialValue: nomos.timeRemaining)
    }
    
    var body: some View {
        ZStack {
            // Background
            DesignSystem.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: DesignSystem.Spacing.xxxl) {
                Spacer()
                
                // The Rule
                VStack(spacing: DesignSystem.Spacing.lg) {
                    Text("Your Law")
                        .font(DesignSystem.Typography.title3)
                        .foregroundColor(DesignSystem.Colors.accent)
                    
                    Text(nomos.rule)
                        .font(DesignSystem.Typography.title1)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.horizontal, DesignSystem.Spacing.xl)
                
                // Timer Display
                VStack(spacing: DesignSystem.Spacing.lg) {
                    Text("Time Remaining")
                        .font(DesignSystem.Typography.callout)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    Text(formatTimeRemaining(timeRemaining))
                        .font(.system(size: 48, weight: .light, design: .monospaced))
                        .foregroundColor(DesignSystem.Colors.primaryText)
                        .contentTransition(.numericText(value: timeRemaining))
                        .animation(DesignSystem.Animations.smooth, value: timeRemaining)
                    
                    // Progress Ring
                    ProgressRingView(
                        progress: progressValue,
                        lineWidth: 4,
                        color: timeRemaining < 3600 ? DesignSystem.Colors.destructive : DesignSystem.Colors.accent
                    )
                    .frame(width: 120, height: 120)
                    .animation(DesignSystem.Animations.smooth, value: progressValue)
                }
                
                Spacer()
                
                // Motivational Text
                VStack(spacing: DesignSystem.Spacing.sm) {
                    Text("The clock ticks.")
                        .font(DesignSystem.Typography.callout)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    Text("Your word is your bond.")
                        .font(DesignSystem.Typography.footnote)
                        .foregroundColor(DesignSystem.Colors.secondaryText.opacity(0.7))
                }
                
                Spacer()
            }
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    // MARK: - Timer Management
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            updateTimeRemaining()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateTimeRemaining() {
        let newTimeRemaining = nomos.timeRemaining
        
        // Trigger haptic feedback every minute when time is running low
        if newTimeRemaining <= 3600 && newTimeRemaining > 0 {
            let currentMinute = Int(newTimeRemaining / 60)
            let lastMinute = Int(timeRemaining / 60)
            
            if currentMinute != lastMinute {
                HapticContext.timerTick.trigger()
            }
        }
        
        timeRemaining = newTimeRemaining
        
        // Check if expired
        if timeRemaining <= 0 {
            stopTimer()
            HapticContext.failure.trigger()
            onExpired()
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatTimeRemaining(_ time: TimeInterval) -> String {
        let totalSeconds = Int(max(0, time))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    private var progressValue: Double {
        let originalDuration = nomos.expiresAt.timeIntervalSince(nomos.createdAt)
        let elapsed = Date().timeIntervalSince(nomos.createdAt)
        return min(1.0, max(0.0, elapsed / originalDuration))
    }
}

// MARK: - Progress Ring View

struct ProgressRingView: View {
    let progress: Double
    let lineWidth: CGFloat
    let color: Color
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
        }
    }
}

#Preview {
    let sampleStake = Stake(type: .scribesVow, content: "Sample text".data(using: .utf8) ?? Data())
    let sampleNomos = Nomos(rule: "I will wake up at 6 AM every day", stake: sampleStake, duration: 2 * 60 * 60) // 2 hours for preview
    
    return ActiveNomosView(nomos: sampleNomos) {
        print("Nomos expired")
    }
}
