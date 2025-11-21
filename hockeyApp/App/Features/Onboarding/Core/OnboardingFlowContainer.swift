import SwiftUI

// MARK: - Onboarding Flow Container
// ⚠️ NEVER MODIFY THIS FILE - Reusable across ALL apps

/// Container view that manages the entire onboarding flow
/// Handles navigation, analytics tracking, and completion
struct OnboardingFlowContainer: View {
    // MARK: - Properties
    @Binding var isComplete: Bool
    @State private var currentPageIndex: Int = 0
    @Environment(\.theme) var theme

    private let screens: [OnboardingScreenWrapper]

    // MARK: - Initialization
    init(isComplete: Binding<Bool>) {
        self._isComplete = isComplete

        // Get screens from configuration
        self.screens = OnboardingConfiguration.createScreens(
            onComplete: {
                isComplete.wrappedValue = true
            }
        )
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            // Background (from configuration)
            OnboardingConfiguration.backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Page Indicators (if enabled)
                if OnboardingConfiguration.showPageIndicators {
                    pageIndicators
                        .padding(.top, 20)
                        .padding(.bottom, 10)
                }

                // Screen Content
                TabView(selection: $currentPageIndex) {
                    ForEach(Array(screens.enumerated()), id: \.offset) { index, screenWrapper in
                        screenWrapper.view
                            .tag(index)
                            .onAppear {
                                handleScreenAppear(index: index, screenID: screenWrapper.screenID)
                            }
                            .onDisappear {
                                handleScreenDisappear(index: index)
                            }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .disabled(!OnboardingConfiguration.allowSwipeNavigation)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            OnboardingAnalytics.trackStart()
        }
    }

    // MARK: - Page Indicators
    private var pageIndicators: some View {
        HStack(spacing: 8) {
            ForEach(0..<screens.count, id: \.self) { index in
                Circle()
                    .fill(index == currentPageIndex ?
                          OnboardingConfiguration.accentColor :
                          Color.gray.opacity(0.3))
                    .frame(
                        width: index == currentPageIndex ? 10 : 8,
                        height: 8
                    )
                    .animation(.easeInOut, value: currentPageIndex)
            }
        }
    }

    // MARK: - Analytics Tracking

    private func handleScreenAppear(index: Int, screenID: String) {
        OnboardingAnalytics.trackScreenView(
            screenID: screenID,
            screenIndex: index,
            totalScreens: screens.count
        )
    }

    private func handleScreenDisappear(index: Int) {
        // Optional: Track time spent on screen
    }
}

// MARK: - Screen Wrapper
/// Wrapper to hold screen views with metadata
struct OnboardingScreenWrapper {
    let screenID: String
    let view: AnyView
}
