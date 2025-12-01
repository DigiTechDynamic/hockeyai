import SwiftUI

// MARK: - Onboarding Steps
enum OnboardingStep: Int, CaseIterable {
    case greenyWelcome = 0
    case profileSetup
    case bodySetup
    case gameSetup
    case styCheckIntro
    case appRating
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
            AnyOnboardingPage(ProfileSetupPage(viewModel: vm)),
            AnyOnboardingPage(BodySetupPage(viewModel: vm)),
            AnyOnboardingPage(GameSetupPage(viewModel: vm)),
            AnyOnboardingPage(STYCheckIntroPage(viewModel: vm)),
            AnyOnboardingPage(AppRatingPage(viewModel: vm)),
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
            // Track onboarding funnel: started → welcome
            OnboardingAnalytics.trackStart()
            OnboardingAnalytics.trackWelcome()

            // Set completion handlers
            coordinator.onComplete = {
                OnboardingAnalytics.trackCompletion()
                viewModel.completeOnboarding()
                withAnimation {
                    hasCompletedOnboarding = true
                }
            }

            viewModel.onComplete = {
                OnboardingAnalytics.trackCompletion()
                withAnimation {
                    hasCompletedOnboarding = true
                }
            }

            // Notify coordinator that page appeared
            coordinator.pageDidAppear()
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
        case .profileSetup:
            ProfileSetupScreen(viewModel: viewModel, coordinator: coordinator)
        case .bodySetup:
            BodySetupScreen(viewModel: viewModel, coordinator: coordinator)
        case .gameSetup:
            GameSetupScreen(viewModel: viewModel, coordinator: coordinator)
        case .styCheckIntro:
            STYCheckIntroScreen(viewModel: viewModel, coordinator: coordinator)
        case .appRating:
            AppRatingScreen(viewModel: viewModel, coordinator: coordinator)
        case .notificationAsk:
            NotificationAskScreen(viewModel: viewModel, coordinator: coordinator)
        }
    }
}

