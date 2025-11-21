import SwiftUI

// MARK: - Onboarding Steps
enum OnboardingStep: Int, CaseIterable {
    case greenyWelcome = 0
    case styCheckIntro
    case appRating
    case appRatingThankYou
    case notificationAsk

    var progress: Double {
        return Double(self.rawValue + 1) / Double(OnboardingStep.allCases.count)
    }
}

// MARK: - Onboarding Flow View
struct OnboardingFlowView: View {
    @Environment(\.theme) var theme
    @Binding var hasCompletedOnboarding: Bool
    @StateObject private var viewModel = OnboardingViewModel()
    @StateObject private var coordinator: OnboardingFlowCoordinator

    init(hasCompletedOnboarding: Binding<Bool>) {
        self._hasCompletedOnboarding = hasCompletedOnboarding

        // Create coordinator with pages
        let vm = OnboardingViewModel()
        let pages: [AnyOnboardingPage] = [
            AnyOnboardingPage(GreenyWelcomePage(viewModel: vm)),
            AnyOnboardingPage(STYCheckIntroPage(viewModel: vm)),
            AnyOnboardingPage(AppRatingPage(viewModel: vm)),
            AnyOnboardingPage(AppRatingThankYouPage(viewModel: vm)),
            AnyOnboardingPage(NotificationAskPage(viewModel: vm))
        ]

        _coordinator = StateObject(wrappedValue: OnboardingFlowCoordinator(pages: pages))
        _viewModel = StateObject(wrappedValue: vm)
    }

    var body: some View {
        ZStack {
            // Modern gradient background
            theme.onboardingBackgroundGradient
                .ignoresSafeArea(.all)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(spacing: 0) {
                // Custom navigation bar
                OnboardingNavigationBar(
                    coordinator: coordinator,
                    viewModel: viewModel
                )

                // Content - ZStack instead of TabView
                ZStack {
                    ForEach(Array(OnboardingStep.allCases.enumerated()), id: \.element) { index, step in
                        if coordinator.currentPageIndex == index {
                            pageView(for: step)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .edgesIgnoringSafeArea(.bottom)
        .onAppear {
            // Track onboarding started
            AnalyticsManager.shared.trackFunnelStep(
                funnel: "onboarding",
                step: "started",
                stepNumber: 0,
                totalSteps: OnboardingStep.allCases.count
            )

            // Track first screen view (onChange won't fire for index 0)
            AnalyticsManager.shared.trackFunnelStep(
                funnel: "onboarding",
                step: "welcome",
                stepNumber: 1,
                totalSteps: OnboardingStep.allCases.count
            )

            // Set completion handlers
            coordinator.onComplete = {
                // Track completion
                AnalyticsManager.shared.trackFunnelStep(
                    funnel: "onboarding",
                    step: "completed",
                    stepNumber: OnboardingStep.allCases.count,
                    totalSteps: OnboardingStep.allCases.count
                )

                viewModel.completeOnboarding()
                withAnimation {
                    hasCompletedOnboarding = true
                }
            }

            viewModel.onComplete = {
                // Track completion
                AnalyticsManager.shared.trackFunnelStep(
                    funnel: "onboarding",
                    step: "completed",
                    stepNumber: OnboardingStep.allCases.count,
                    totalSteps: OnboardingStep.allCases.count
                )

                withAnimation {
                    hasCompletedOnboarding = true
                }
            }

            // Notify coordinator that page appeared
            coordinator.pageDidAppear()
        }
        .onChange(of: coordinator.currentPageIndex) { newIndex in
            // Track screen views
            let step = OnboardingStep.allCases[newIndex]
            let screenName: String

            switch step {
            case .greenyWelcome:
                screenName = "welcome"
            case .styCheckIntro:
                screenName = "sty_check"
            case .appRating:
                screenName = "rating"
            case .appRatingThankYou:
                screenName = "thank_you"
            case .notificationAsk:
                screenName = "notifications"
            }

            AnalyticsManager.shared.trackFunnelStep(
                funnel: "onboarding",
                step: screenName,
                stepNumber: newIndex + 1,
                totalSteps: OnboardingStep.allCases.count
            )
        }
        // Player Rater full-screen modal
        .fullScreenCover(isPresented: $viewModel.showingPlayerRater) {
            PlayerRaterFlowView(context: .onboarding) { rating in
                viewModel.handlePlayerRaterComplete(rating)
            }
        }
    }

    @ViewBuilder
    private func pageView(for step: OnboardingStep) -> some View {
        switch step {
        case .greenyWelcome:
            GreenyWelcomeScreen(viewModel: viewModel, coordinator: coordinator)
        case .styCheckIntro:
            STYCheckIntroScreen(viewModel: viewModel, coordinator: coordinator)
        case .appRating:
            AppRatingScreen(viewModel: viewModel, coordinator: coordinator)
        case .appRatingThankYou:
            AppRatingThankYouScreen(viewModel: viewModel, coordinator: coordinator)
        case .notificationAsk:
            NotificationAskScreen(viewModel: viewModel, coordinator: coordinator)
        }
    }
}

// MARK: - Preview
struct OnboardingFlowView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingFlowView(hasCompletedOnboarding: .constant(false))
    }
}
