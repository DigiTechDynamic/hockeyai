import Foundation

// MARK: - Rater Context
/// Defines how the Player Rater should behave based on where it's launched from
enum RaterContext {
    case onboarding        // First-time during onboarding
    case homeScreen        // From home screen (daily rating)
    case tryAgain         // Second attempt during onboarding

    var allowsSkip: Bool {
        switch self {
        case .onboarding: return false  // Must complete onboarding
        case .homeScreen: return true   // Can dismiss anytime
        case .tryAgain: return true     // Can skip second attempt
        }
    }

    var showsPaywall: Bool {
        switch self {
        case .onboarding: return false  // No paywall during onboarding
        case .homeScreen: return true   // Show paywall if daily limit hit
        case .tryAgain: return false    // Free second attempt
        }
    }

    var countsTowardDailyLimit: Bool {
        switch self {
        case .onboarding: return false  // Onboarding ratings are free
        case .homeScreen: return true   // Counts toward 1/day limit
        case .tryAgain: return false    // Free during onboarding
        }
    }

    var navigationStyle: NavigationStyle {
        switch self {
        case .onboarding: return .fullScreen  // Full-screen takeover
        case .homeScreen: return .fullScreen  // Full-screen modal
        case .tryAgain: return .fullScreen    // Stay in onboarding
        }
    }

    var showsCloseButton: Bool {
        switch self {
        case .onboarding: return false  // No escape during onboarding
        case .homeScreen: return true   // Can dismiss from home
        case .tryAgain: return true     // Can skip second attempt
        }
    }

    enum NavigationStyle {
        case fullScreen  // Full-screen takeover
        case sheet       // Bottom sheet modal
    }
}
