import SwiftUI
import UserNotifications

// MARK: - Notification Ask Screen (Research-Backed Design)
struct NotificationAskScreen: View {
    @Environment(\.theme) var theme
    @ObservedObject var viewModel: OnboardingViewModel
    @ObservedObject var coordinator: OnboardingFlowCoordinator

    // Drive UI off shared view model state to avoid duplicate flows
    @State private var animateIn = false
    @State private var showNotificationExamples = false
    @State private var notificationsDenied = false

    var body: some View {
        VStack(spacing: 0) {
            // Step indicator (reduced top padding)
            Text("Step 2 of 3")
                .font(theme.fonts.caption)
                .foregroundColor(theme.textSecondary)
                .padding(.top, theme.spacing.md)

            VStack(spacing: theme.spacing.lg) {
                // Notification bell tile (matches spec image)
                ZStack {
                    // Soft outer glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    theme.primary.opacity(0.2),
                                    theme.primary.opacity(0.06),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 90
                            )
                        )
                        .frame(width: 170, height: 170)

                    // App icon tile background (rounded squircle)
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(0.85),
                                    theme.surface.opacity(0.9)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 110, height: 110)
                        .overlay(
                            // Subtle highlight stroke
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.18),
                                            Color.white.opacity(0.06)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: Color.black.opacity(0.45), radius: 18, x: 0, y: 10)

                    // Bell icon with gold gradient
                    Image(systemName: "bell.fill")
                        .font(.system(size: 54, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(hex: "#FFD57A"), // light gold
                                    Color(hex: "#F2A654")  // deep amber
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Color.white.opacity(0.25), radius: 0, x: 0, y: 0)
                        .shadow(color: Color(hex: "#F2A654").opacity(0.6), radius: 12, x: 0, y: 0)
                        .shadow(color: Color(hex: "#F2A654").opacity(0.35), radius: 22, x: 0, y: 6)
                }
                .scaleEffect(animateIn ? 1 : 0.88)
                .animation(.spring(response: 0.6, dampingFraction: 0.75), value: animateIn)

                // Permission pre-prompt card (replaces headline text)
                ZStack(alignment: .bottomTrailing) {
                    PermissionPromptCard(
                        onDontAllow: {
                            HapticManager.shared.playImpact(style: .light)
                            OnboardingAnalytics.trackNotificationResponse(allowed: false)
                            coordinator.navigateForward()
                        },
                        onAllow: {
                            viewModel.requestNotificationPermission { _ in
                                HapticManager.shared.playNotification(type: .success)
                                // Track as allowed since user tapped "Allow"
                                OnboardingAnalytics.trackNotificationResponse(allowed: true)
                                coordinator.navigateForward()
                            }
                        }
                    )
                    // Emoji finger pointing up toward "Allow"
                    Text("☝️")
                        .font(.system(size: 44))
                        .shadow(color: Color.black.opacity(0.35), radius: 6, x: 0, y: 2)
                        .offset(x: -22, y: 26)
                }
                // Constrain width so the popup isn't full screen
                .frame(maxWidth: 360)
                .padding(.horizontal, theme.spacing.lg)
                .padding(.bottom, theme.spacing.xl) // add space so emoji doesn't overlap next content
                .opacity(animateIn ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.1), value: animateIn)

                // Notification preview cards
                VStack(spacing: theme.spacing.sm) {
                    NotificationPreviewCard(
                        title: "Shot Analysis Ready! 🎯",
                        message: "Your wrist shot scored 92/100. Tap to see tips.",
                        time: "now"
                    )
                    .opacity(showNotificationExamples ? 1 : 0)
                    .offset(x: showNotificationExamples ? 0 : -30)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: showNotificationExamples)

                    NotificationPreviewCard(
                        title: "Training Streak! 🔥",
                        message: "5 days in a row! Keep it up.",
                        time: "9:00 AM"
                    )
                    .opacity(showNotificationExamples ? 1 : 0)
                    .offset(x: showNotificationExamples ? 0 : -30)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3), value: showNotificationExamples)

                    NotificationPreviewCard(
                        title: "New Achievement! 🏆",
                        message: "Unlocked: Speed Demon badge",
                        time: "Yesterday"
                    )
                    .opacity(showNotificationExamples ? 1 : 0)
                    .offset(x: showNotificationExamples ? 0 : -30)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.4), value: showNotificationExamples)
                }
                .padding(.horizontal, theme.spacing.lg)
                .opacity(animateIn ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.2), value: animateIn)
            }
            // Spacer to balance layout after moving prompt card up
            Spacer(minLength: theme.spacing.lg)
        }
        .onAppear {
            // Track funnel step
            OnboardingAnalytics.trackNotificationScreen()

            withAnimation {
                animateIn = true
            }
            // Delay showing notification examples for staggered animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                showNotificationExamples = true
            }
            // Check if notifications were previously denied
            refreshNotificationDenied()
        }
        .onChange(of: viewModel.permissionGranted) { granted in
            if granted {
                notificationsDenied = false
            } else {
                refreshNotificationDenied()
            }
        }
    }
}

// MARK: - Helpers
private extension NotificationAskScreen {
    func refreshNotificationDenied() {
        Task { @MainActor in
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            notificationsDenied = (settings.authorizationStatus == .denied)
        }
    }
}

// MARK: - Inline Permission Prompt Card
private struct PermissionPromptCard: View {
    @Environment(\.theme) var theme
    let onDontAllow: () -> Void
    let onAllow: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("Notifications")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)

                Text("Allow us to send you notifications and updates on your progress")
                    .font(.system(size: 14))
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)

            Divider()
                .background(Color.white.opacity(0.08))

            HStack(spacing: 0) {
                Button(action: onDontAllow) {
                    Text("Don't Allow")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(theme.primary)
                        .frame(maxWidth: .infinity, maxHeight: 48)
                }

                Rectangle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 1, height: 48)

                Button(action: onAllow) {
                    Text("Allow")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [theme.primary, theme.primary.opacity(0.85)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(maxWidth: .infinity, maxHeight: 48)
                }
            }
            .background(
                // Slightly darker strip for button row, like native alert
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.1),
                        Color.black.opacity(0.22)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .background(
            // Stronger glassmorphism: layered material, gradient glare, vignette, and soft shadow
            RoundedRectangle(cornerRadius: theme.cornerRadius * 1.2, style: .continuous)
                .fill(.ultraThinMaterial)
                .background(
                    // Subtle diagonal glare
                    RoundedRectangle(cornerRadius: theme.cornerRadius * 1.2, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.09),
                                    Color.white.opacity(0.02)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .blendMode(.screen)
                )
                .shadow(color: Color.black.opacity(0.5), radius: 18, x: 0, y: 14)
        )
        .overlay(
            // Outer highlight
            RoundedRectangle(cornerRadius: theme.cornerRadius * 1.2, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.20), Color.white.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .overlay(
            // Inner subtle border for depth
            RoundedRectangle(cornerRadius: theme.cornerRadius * 1.2, style: .continuous)
                .inset(by: 1.25)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
        .overlay(
            // Top edge light sweep
            RoundedRectangle(cornerRadius: theme.cornerRadius * 1.2, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.25), Color.clear],
                        startPoint: .top,
                        endPoint: .center
                    ),
                    lineWidth: 1
                )
                .mask(
                    RoundedRectangle(cornerRadius: theme.cornerRadius * 1.2, style: .continuous)
                        .stroke(lineWidth: 1)
                )
        )
    }
}
