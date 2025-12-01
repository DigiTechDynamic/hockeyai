import SwiftUI

// MARK: - Player Rater Flow View (Main Container)
struct PlayerRaterFlowView: View {
    @Environment(\.theme) var theme
    @StateObject private var viewModel: PlayerRaterViewModel
    @Environment(\.presentationMode) var presentationMode

    // Saved results state
    @State private var showingSavedResults = false
    @State private var savedResult: StoredSTYCheckResult?

    private let context: RaterContext
    private let onComplete: (PlayerRating?) -> Void

    init(context: RaterContext, onComplete: @escaping (PlayerRating?) -> Void) {
        self.context = context
        self.onComplete = onComplete
        let vm = PlayerRaterViewModel(context: context)
        _viewModel = StateObject(wrappedValue: vm)

        // Set completion handler
        vm.onComplete = onComplete
    }

    var body: some View {
        Group {
            // Only show saved results for homeScreen context (not onboarding)
            if showingSavedResults, let saved = savedResult, context == .homeScreen {
                SavedSTYCheckResultsView(
                    result: saved,
                    onNewCheck: {
                        showingSavedResults = false
                        savedResult = nil
                    },
                    onExit: {
                        onComplete(nil)
                    }
                )
            } else {
                normalFlowView
            }
        }
        .onAppear {
            // Check for saved results when view appears (only for homeScreen context)
            if context == .homeScreen, let latestResult = AnalysisResultsStore.shared.latestSTYResult {
                savedResult = latestResult
                showingSavedResults = true
            }
        }
    }

    private var normalFlowView: some View {
        VStack(spacing: 0) {
            // Content based on step (no fixed header)
            ZStack {
                // Unified background to match app shell
                ThemedBackground()

                switch viewModel.currentStep {
                case .photoUpload:
                    PhotoUploadView(viewModel: viewModel)

                case .analyzing:
                    PlayerRaterAnalyzingView(viewModel: viewModel)

                case .results:
                    RatingResultsView(viewModel: viewModel)
                }
            }

            // No bottom skip; skip now lives in the top-right overlay.
        }
        // Overlay lightweight top controls
        .overlay(alignment: .top) {
            PlayerRaterTopControls(
                context: viewModel.context,
                currentStep: viewModel.currentStep,
                onBack: { viewModel.dismiss() },
                onClose: { viewModel.dismiss() }
            )
        }
        // Prevent accidental swipe-dismiss while analyzing
        .interactiveDismissDisabled(viewModel.currentStep == .analyzing)
        .background(ThemedBackground())
        .preferredColorScheme(.dark)
        // AI Consent Dialog (shown before first AI feature use) as overlay card
        .overlay {
            if viewModel.showAIConsentDialog {
                ZStack {
                    // Blurred + darkened backdrop for readability
                    Rectangle()
                        .fill(.ultraThinMaterial) // system blur of content underneath
                        .ignoresSafeArea()
                        .transition(.opacity)
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()

                    AIConsentDialog(
                        onAccept: {
                            // Hide overlay then proceed
                            withAnimation(.easeInOut(duration: 0.25)) {
                                viewModel.showAIConsentDialog = false
                            }
                            viewModel.handleConsentAccepted()
                        },
                        onDecline: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                viewModel.showAIConsentDialog = false
                            }
                            viewModel.handleConsentDeclined()
                        }
                    )
                    .transition(.scale.combined(with: .opacity))
                }
                .allowsHitTesting(true)
                .animation(.easeInOut(duration: 0.25), value: viewModel.showAIConsentDialog)
            }
        }
        .onAppear {
            // Track funnel start based on context
            if viewModel.context == .onboarding {
                // Onboarding funnel already tracked in STYCheckIntroScreen
                // Individual steps tracked in each view
            } else {
                // Track home screen STY check start (Funnel 3)
                STYCheckAnalytics.trackStarted(source: viewModel.context == .tryAgain ? "try_again" : "home_screen")
            }
        }
    }

    // MARK: - Old Funnel Tracking (REMOVED)
    // Funnel tracking now handled by individual view files:
    // - STYValidationAnalytics for onboarding context
    // - STYCheckAnalytics for home screen context (STY Check)
    // This provides more granular tracking with picker_opened step}
}
