import SwiftUI

struct AgoraView: View {
    @StateObject private var backendService = BackendService.shared
    @State private var events: [AgoraEvent] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showCreateNomos = false
    
    var body: some View {
        ZStack {
            // Background
            DesignSystem.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Events Feed
                if isLoading {
                    loadingView
                } else if let errorMessage = errorMessage {
                    errorView(errorMessage)
                } else {
                    eventsListView
                }
                
                Spacer()
                
                // Create Button
                createButton
            }
        }
        .onAppear {
            loadEvents()
        }
        .fullScreenCover(isPresented: $showCreateNomos) {
            CreateNomosView()
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Text("Agora")
                .font(DesignSystem.Typography.largeTitle)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            Text("Anonymous echoes of commitment")
                .font(DesignSystem.Typography.callout)
                .foregroundColor(DesignSystem.Colors.secondaryText)
        }
        .padding(.top, DesignSystem.Spacing.xl)
        .padding(.bottom, DesignSystem.Spacing.lg)
    }
    
    // MARK: - Events List
    
    private var eventsListView: some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.md) {
                ForEach(events) { event in
                    EventRowView(event: event)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.bottom, 100) // Space for the create button
        }
        .refreshable {
            await refreshEvents()
        }
    }
    
    // MARK: - Loading State
    
    private var loadingView: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.Colors.accent))
                .scaleEffect(1.2)
            
            Text("Loading the echoes...")
                .font(DesignSystem.Typography.callout)
                .foregroundColor(DesignSystem.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Error State
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundColor(DesignSystem.Colors.destructive)
            
            Text("Unable to reach the Agora")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            Text(message)
                .font(DesignSystem.Typography.callout)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
            
            Button("Try Again") {
                loadEvents()
            }
            .tactileButton(style: .secondary)
        }
        .padding(.horizontal, DesignSystem.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Create Button
    
    private var createButton: some View {
        VStack {
            Button(action: {
                HapticContext.buttonPress.trigger()
                showCreateNomos = true
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(
                        Circle()
                            .fill(DesignSystem.Colors.accent)
                            .shadow(color: DesignSystem.Effects.mediumShadow, radius: 8, x: 0, y: 4)
                    )
            }
            .padding(.bottom, DesignSystem.Spacing.xl)
        }
    }
    
    // MARK: - Data Loading
    
    private func loadEvents() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Try to fetch from backend
                let fetchedEvents = try await backendService.fetchEvents()
                await MainActor.run {
                    self.events = fetchedEvents
                    self.isLoading = false
                }
            } catch {
                // Fallback to mock data for development
                await MainActor.run {
                    self.events = backendService.generateMockEvents()
                    self.isLoading = false
                    // Uncomment the line below to show actual error messages
                    // self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    @MainActor
    private func refreshEvents() async {
        do {
            let fetchedEvents = try await backendService.fetchEvents()
            self.events = fetchedEvents
            self.errorMessage = nil
        } catch {
            // Silently fail on refresh and keep existing data
            // self.errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Event Row View

struct EventRowView: View {
    let event: AgoraEvent
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(event.eventType.displayText)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                HStack {
                    Text("[\(event.timezone)]")
                        .font(DesignSystem.Typography.footnote)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    Spacer()
                    
                    Text(timeAgoString(from: event.timestamp))
                        .font(DesignSystem.Typography.footnote)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
            
            Spacer()
            
            // Event type indicator
            Circle()
                .fill(colorForEventType(event.eventType))
                .frame(width: 8, height: 8)
        }
        .padding(.vertical, DesignSystem.Spacing.md)
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .glassCard()
    }
    
    private func colorForEventType(_ eventType: AgoraEvent.EventType) -> Color {
        switch eventType {
        case .committed:
            return DesignSystem.Colors.accent
        case .upheld:
            return .green
        case .forfeited:
            return DesignSystem.Colors.destructive
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return "now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
}

#Preview {
    AgoraView()
}
