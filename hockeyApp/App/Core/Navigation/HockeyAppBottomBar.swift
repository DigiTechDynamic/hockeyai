import SwiftUI

// MARK: - Hockey App Bottom Bar
struct HockeyAppBottomBar: View {
    @Environment(\.theme) var theme
    let primaryAction: () -> Void
    let secondaryActions: [HockeyBottomAction]
    
    @State private var animatePrimary = false
    
    var body: some View {
        HStack(spacing: theme.spacing.lg) {
            // Secondary actions
            ForEach(secondaryActions.prefix(2), id: \.title) { action in
                Button(action: action.action) {
                    VStack(spacing: theme.spacing.xs + 2) {
                        Image(systemName: action.icon)
                            .font(theme.fonts.headline)
                        Text(action.title)
                            .font(theme.fonts.caption)
                    }
                    .foregroundColor(theme.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }
            
            // Primary action button
            Button(action: {
                primaryAction()
                animatePrimaryButton()
            }) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [theme.primary, theme.primary.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 64, height: 64)
                        .shadow(
                            color: theme.primary.opacity(0.4),
                            radius: animatePrimary ? 20 : 10,
                            x: 0,
                            y: animatePrimary ? 8 : 5
                        )
                    
                    Image(systemName: "plus")
                        .font(theme.fonts.largeTitle)
                        .foregroundColor(theme.textOnPrimary)
                        .rotationEffect(.degrees(animatePrimary ? 90 : 0))
                }
                .scaleEffect(animatePrimary ? 1.1 : 1.0)
            }
            .buttonStyle(PlainButtonStyle())
            
            // More secondary actions
            ForEach(secondaryActions.dropFirst(2).prefix(2), id: \.title) { action in
                Button(action: action.action) {
                    VStack(spacing: theme.spacing.xs + 2) {
                        Image(systemName: action.icon)
                            .font(theme.fonts.headline)
                        Text(action.title)
                            .font(theme.fonts.caption)
                    }
                    .foregroundColor(theme.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, theme.spacing.lg)
        .padding(.vertical, theme.spacing.sm)
        .background(
            Rectangle()
                .fill(theme.surface.opacity(0.9))
                .background(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        )
    }
    
    private func animatePrimaryButton() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            animatePrimary = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                animatePrimary = false
            }
        }
    }
}

// MARK: - Hockey Bottom Action Model
struct HockeyBottomAction {
    let title: String
    let icon: String
    let action: () -> Void
}

// MARK: - Default Hockey Bottom Actions
extension HockeyBottomAction {
    static func defaultActions(
        onLog: @escaping () -> Void,
        onTimer: @escaping () -> Void,
        onRecord: @escaping () -> Void,
        onAI: @escaping () -> Void
    ) -> [HockeyBottomAction] {
        [
            HockeyBottomAction(title: "Log", icon: "square.and.pencil", action: onLog),
            HockeyBottomAction(title: "Timer", icon: "timer", action: onTimer),
            HockeyBottomAction(title: "Record", icon: "video.fill", action: onRecord),
            HockeyBottomAction(title: "AI Tips", icon: "brain", action: onAI)
        ]
    }
}