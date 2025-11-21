import SwiftUI
import Combine

// MARK: - Player Rater View Model
class PlayerRaterViewModel: ObservableObject {

    // MARK: - Published State
    @Published var currentStep: RaterStep = .photoUpload
    @Published var uploadedImage: UIImage?
    @Published var isAnalyzing = false
    @Published var rating: PlayerRating?
    @Published var error: String?
    @Published var analysisProgress: Double = 0.0

    // MARK: - Premium State
    @Published var isPremiumUnlocked = false  // For testing: toggle to bypass paywall
    @Published var showPaywall = false

    // MARK: - AI Consent State
    @Published var showAIConsentDialog = false
    private var pendingImageForAnalysis: UIImage?  // Store image while waiting for consent

    // MARK: - Configuration
    let context: RaterContext
    var onComplete: ((PlayerRating?) -> Void)?  // Callback when done

    // MARK: - Private State
    private var cancellables = Set<AnyCancellable>()
    private var analysisStartTime: Date?

    // MARK: - Initialization
    init(context: RaterContext) {
        self.context = context

        // Auto-unlock Beauty Check during onboarding (boost downloads/ratings over revenue at launch)
        if context == .onboarding {
            self.isPremiumUnlocked = true
            print("✅ [PlayerRaterViewModel] Auto-unlocking Beauty Check for onboarding context")
        }
    }

    // MARK: - Steps
    enum RaterStep {
        case photoUpload
        case analyzing
        case results
    }

    // MARK: - Actions
    func uploadPhoto(_ image: UIImage) {
        uploadedImage = image

        // Check for AI consent before proceeding
        Task { @MainActor in
            if AIConsentManager.shared.needsConsent {
                // Store image and show consent dialog
                pendingImageForAnalysis = image
                showAIConsentDialog = true
                print("⚠️ [PlayerRaterViewModel] AI consent needed - showing dialog")
            } else {
                // Consent already given, proceed with analysis
                proceedWithAnalysis()
            }
        }
    }

    /// Called when user accepts AI consent
    func handleConsentAccepted() {
        print("✅ [PlayerRaterViewModel] AI consent accepted - proceeding with analysis")
        proceedWithAnalysis()
    }

    /// Called when user declines AI consent
    func handleConsentDeclined() {
        print("❌ [PlayerRaterViewModel] AI consent declined - resetting state")
        uploadedImage = nil
        pendingImageForAnalysis = nil
        currentStep = .photoUpload
        error = "AI analysis requires your consent to process photos"
    }

    /// Proceed with analysis after consent is confirmed
    private func proceedWithAnalysis() {
        currentStep = .analyzing
        startAnalysis()
        pendingImageForAnalysis = nil // Clear pending image
    }

    private func startAnalysis() {
        isAnalyzing = true
        analysisProgress = 0.1 // start with a small real progress
        analysisStartTime = Date() // Track start time for analytics

        // Haptic feedback when AI analysis starts
        HapticManager.shared.playImpact(style: .light)

        // Drive progress from real network events
        cancellables.removeAll()
        NotificationCenter.default.publisher(for: .aiRequestSent)
            .sink { [weak self] _ in
                guard let self = self else { return }
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.analysisProgress = max(self.analysisProgress, 0.35)
                }
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .aiResponseReceived)
            .sink { [weak self] _ in
                guard let self = self else { return }
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.analysisProgress = max(self.analysisProgress, 0.9)
                }
            }
            .store(in: &cancellables)

        // Call real PlayerRaterService immediately
        guard let image = uploadedImage else {
            self.error = "No image available"
            self.isAnalyzing = false
            return
        }

        Task {
            do {
                let result = try await PlayerRaterService.analyzePlayer(
                    photo: image,
                    isOnboarding: context == .onboarding
                )

                await MainActor.run {
                    self.rating = result
                    self.analysisProgress = 1.0
                    self.isAnalyzing = false
                    self.currentStep = .results
                    HapticManager.shared.playNotification(type: .success)

                    // Analysis completion tracking now handled in RatingResultsView
                    // when user views/accepts results
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.isAnalyzing = false
                    print("❌ [PlayerRaterViewModel] Analysis failed: \(error)")

                    // Track analysis failure
                    if self.context == .onboarding {
                        PlayerRaterAnalytics.trackAnalysisFailed(
                            context: self.context,
                            error: error.localizedDescription
                        )
                    }
                }
            }
        }
    }

    func complete() {
        onComplete?(rating)
    }

    func dismiss() {
        onComplete?(nil)
    }

    func goBack() {
        switch currentStep {
        case .photoUpload:
            dismiss()
        case .analyzing:
            // Can't go back during analysis
            break
        case .results:
            currentStep = .photoUpload
            uploadedImage = nil
            rating = nil
        }
    }

    // MARK: - Premium Actions

    /// Trigger paywall to unlock Beauty Check
    func unlockPremium() {
        // Track beauty breakdown button click (Step 6)
        if let rating = self.rating, context != .onboarding {
            STYCheckAnalytics.trackBeautyBreakdownClicked(
                score: rating.overallScore,
                tier: rating.archetype
            )
        }

        showPaywall = true
        HapticManager.shared.playImpact(style: .medium)
        print("💎 [PlayerRaterViewModel] Triggering Beauty Check paywall")
    }

    /// Called after paywall dismisses - check if user purchased
    func checkPremiumStatus() {
        let monetization = MonetizationManager.shared

        if monetization.isPremium {
            // User is now premium - unlock the Beauty Check
            let wasAlreadyUnlocked = isPremiumUnlocked
            isPremiumUnlocked = true
            HapticManager.shared.playNotification(type: .success)
            print("✅ [PlayerRaterViewModel] Premium purchased - Beauty Check unlocked!")

            // Track beauty breakdown unlocked (Step 7 - Funnel Completion)
            if !wasAlreadyUnlocked, let rating = self.rating, context != .onboarding {
                STYCheckAnalytics.trackBeautyBreakdownUnlocked(
                    score: rating.overallScore,
                    tier: rating.archetype
                )
            }
        } else if context != .onboarding {
            // Only log paywall dismissal for non-onboarding contexts
            // (During onboarding, premium is auto-unlocked, so this check is expected)
            print("❌ [PlayerRaterViewModel] Paywall dismissed without purchase")
        }
    }

    // MARK: - Cleanup
    deinit {
        cancellables.removeAll()
    }
}
