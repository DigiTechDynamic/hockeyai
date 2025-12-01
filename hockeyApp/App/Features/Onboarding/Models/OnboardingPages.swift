import SwiftUI

// MARK: - Greeny Welcome Page
struct GreenyWelcomePage: OnboardingPageProtocol {
    let viewModel: OnboardingViewModel

    var pageID: String { "greeny_welcome" }

    var navigationRules: NavigationRules {
        .firstPage
    }

    func onNavigateForward(completion: @escaping (NavigationResult) -> Void) {
        // Just proceed to next page (Profile Setup)
        completion(.proceed)
    }
}

// MARK: - Profile Setup Page (Name, Age, Phone)
struct ProfileSetupPage: OnboardingPageProtocol {
    let viewModel: OnboardingViewModel

    var pageID: String { "profile_setup" }

    var navigationRules: NavigationRules {
        NavigationRules(
            allowsSwipeBack: true,
            allowsSwipeForward: false,
            showsBackButton: true,
            showsSkipButton: false,
            showsProgressBar: true,
            transitionDuration: 0.3
        )
    }

    func onNavigateForward(completion: @escaping (NavigationResult) -> Void) {
        completion(.proceed)
    }
}

// MARK: - Body Setup Page (Height, Weight, Gender)
struct BodySetupPage: OnboardingPageProtocol {
    let viewModel: OnboardingViewModel

    var pageID: String { "body_setup" }

    var navigationRules: NavigationRules {
        NavigationRules(
            allowsSwipeBack: true,
            allowsSwipeForward: false,
            showsBackButton: true,
            showsSkipButton: false,
            showsProgressBar: true,
            transitionDuration: 0.3
        )
    }

    func onNavigateForward(completion: @escaping (NavigationResult) -> Void) {
        completion(.proceed)
    }
}

// MARK: - Game Setup Page (Position, Skill Level, Handedness)
struct GameSetupPage: OnboardingPageProtocol {
    let viewModel: OnboardingViewModel

    var pageID: String { "game_setup" }

    var navigationRules: NavigationRules {
        NavigationRules(
            allowsSwipeBack: true,
            allowsSwipeForward: false,
            showsBackButton: true,
            showsSkipButton: false,
            showsProgressBar: true,
            transitionDuration: 0.3
        )
    }

    func onNavigateForward(completion: @escaping (NavigationResult) -> Void) {
        completion(.proceed)
    }
}

// MARK: - STY Check Intro Page
struct STYCheckIntroPage: OnboardingPageProtocol {
    let viewModel: OnboardingViewModel

    var pageID: String { "sty_check_intro" }

    var navigationRules: NavigationRules {
        NavigationRules(
            allowsSwipeBack: true,
            allowsSwipeForward: false,
            showsBackButton: true,
            showsSkipButton: false,  // No skip - must do STY Check
            showsProgressBar: true,
            transitionDuration: 0.3
        )
    }

    func onNavigateForward(completion: @escaping (NavigationResult) -> Void) {
        Task { @MainActor in
            // Check if user already completed STY Check in a previous session
            let hasUsedSTY = UserDefaults.standard.bool(forKey: "hasUsedOnboardingSTYRating")

            if hasUsedSTY {
                // User already used their free STY Check - skip to next page
                completion(.proceed)
            } else {
                // Store completion for when Player Rater finishes
                viewModel.navigationCompletion = completion

                // Launch Player Rater modal
                viewModel.launchPlayerRater()

                // Return waitForModal - coordinator will wait for Player Rater to complete
                // When Player Rater dismisses, viewModel.handlePlayerRaterComplete will call completion(.proceed)
            }
        }
    }

    // ✨ NEW: Check if we should skip rating screens after STY Check
    func onAppear() {
        // This will be called when returning from Player Rater modal
        // If user rated inline, we'll skip the full rating screens
    }
}

// MARK: - App Rating Page
struct AppRatingPage: OnboardingPageProtocol {
    let viewModel: OnboardingViewModel

    var pageID: String { "app_rating" }

    var navigationRules: NavigationRules {
        .locked // No back button, can skip
    }

    func canNavigateBack() -> Bool {
        false // Can't go back after Player Rater!
    }

    func onNavigateForward(completion: @escaping (NavigationResult) -> Void) {
        // User submitted or skipped rating
        completion(.proceed)
    }

    // ✨ Auto-skip if user already rated inline during STY Check
    func onAppear() {
        // Check if user rated inline in the STY Check results
        if UserDefaults.standard.bool(forKey: "hasRatedDuringOnboarding") {
            print("✅ [AppRatingPage] User already rated inline - auto-skipping this screen")
            // We'll handle the skip in the view layer
        }
    }
}

// MARK: - Notification Ask Page
struct NotificationAskPage: OnboardingPageProtocol {
    let viewModel: OnboardingViewModel

    var pageID: String { "notification_ask" }

    var navigationRules: NavigationRules {
        .finalPage // No back, can skip
    }

    func canNavigateBack() -> Bool {
        false // Last page, no going back
    }

    func onNavigateForward(completion: @escaping (NavigationResult) -> Void) {
        // Complete onboarding (permission was requested via button if user wanted it)
        completion(.proceed)
    }
}
