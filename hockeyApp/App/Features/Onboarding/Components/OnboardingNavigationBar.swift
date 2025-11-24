import SwiftUI

// MARK: - Onboarding Navigation Bar
struct OnboardingNavigationBar: View {
    @Environment(\.theme) var theme
    @ObservedObject var coordinator: OnboardingFlowCoordinator
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Combined header row with SnapHockey, Back, and Skip
            HStack {
                // Back button - controlled by coordinator
                if coordinator.showsBackButton() {
                    Button(action: { coordinator.navigateBack() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(theme.primary)
                    }
                    .frame(width: 44, height: 44)
                } else {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.clear)
                        .frame(width: 44, height: 44)
                        .allowsHitTesting(false)
                }

                Spacer()

                // Center SnapHockey text - only show after first page
                if coordinator.currentPageIndex > 0 {
                    Text("SnapHockey")
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color.white,
                                    Color.white.opacity(0.95)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Color.white.opacity(0.55), radius: 0, x: 0, y: 0)
                        .shadow(color: Color.white.opacity(0.35), radius: 4, x: 0, y: 0)
                        .shadow(color: theme.primary.opacity(0.45), radius: 10, x: 0, y: 2)
                }

                Spacer()

                // Skip button - controlled by coordinator
                if coordinator.canSkip() {
                    Button(action: { coordinator.skip() }) {
                        Text("Skip")
                            .font(theme.fonts.body)
                            .foregroundColor(theme.textSecondary)
                    }
                    .frame(height: 44)
                } else {
                    // Invisible spacer to keep layout balanced
                    Text("Skip")
                        .font(theme.fonts.body)
                        .foregroundColor(.clear)
                        .frame(height: 44)
                        .allowsHitTesting(false)
                }
            }
            .padding(.horizontal, theme.spacing.lg)
            .padding(.top, theme.spacing.sm)
            .padding(.bottom, theme.spacing.sm)

            // Progress bar - controlled by coordinator
            if coordinator.showsProgressBar() {
                HStack {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(theme.divider)
                                .frame(height: 3)

                            Rectangle()
                                .fill(theme.primary)
                                .frame(width: geometry.size.width * coordinator.progress, height: 3)
                                .shadow(color: theme.primary.opacity(0.6), radius: 4)
                                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: coordinator.progress)
                        }
                    }
                    .frame(height: 3)
                }
                .padding(.horizontal, theme.spacing.lg)
            }
        }
        .background(Color(hex: "#0F0F0F"))
    }
}
