import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    @StateObject private var authManager = AuthenticationManager.shared
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.theme) var theme

    var body: some View {
        ZStack {
            // Debug indicator removed - handled by NotificationKit

            SplashContainer {
                Group {
                    switch viewModel.currentViewState {
                    case .loading:
                        UnifiedLoadingView(message: "Loading...")

                    case .authentication:
                        AuthenticationView()
                            .environmentObject(authManager)

                    case .onboarding:
                        OnboardingFlowView(hasCompletedOnboarding: $viewModel.hasCompletedOnboarding)
                            .environmentObject(authManager)
                            .environmentObject(themeManager)
                            .environment(\.theme, themeManager.activeTheme)

                    case .main:
                        HockeyMainView()
                            .environmentObject(authManager)
                    }
                }
                .animation(theme.animations.medium, value: viewModel.currentViewState)
            }

            // Notifications work but don't deep link - user can tap Results button
        }
    }
}


// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
