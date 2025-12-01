import SwiftUI
import Combine

// MARK: - Onboarding View Model
/// Simplified onboarding shared state
@MainActor
class OnboardingViewModel: ObservableObject {

    // MARK: - Published State
    @Published var enableNotifications = false
    @Published var permissionGranted = false
    @Published var showingPlayerRater = false
    @Published var playerRating: PlayerRating? = nil
    @Published var playerProfile: PlayerProfile? = nil

    // MARK: - Completion Handlers
    var onComplete: (() -> Void)?
    var navigationCompletion: ((NavigationResult) -> Void)?

    // MARK: - Notifications
    /// Request notification permission without navigation (for button use)
    func requestNotificationPermission() {
        Task {
            let granted = await NotificationKit.requestPermission()
            await MainActor.run {
                permissionGranted = granted
                enableNotifications = granted
            }
        }
    }

    /// Request notification permission with completion (for protocol use)
    func requestNotificationPermission(completion: @escaping (NavigationResult) -> Void) {
        Task {
            let granted = await NotificationKit.requestPermission()
            await MainActor.run {
                permissionGranted = granted
                enableNotifications = granted

                // Advance after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    completion(.proceed)
                }
            }
        }
    }

    // MARK: - Completion
    func completeOnboarding() {
        // Save preferences
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        UserDefaults.standard.set(enableNotifications, forKey: "notificationsEnabled")

        // Haptic only (no sound) per request
        HapticManager.shared.playNotification(type: .success)

        // Call completion handler
        onComplete?()
    }

    // MARK: - Player Rater
    func launchPlayerRater() {
        showingPlayerRater = true
    }

    func handlePlayerRaterComplete(_ rating: PlayerRating?) {
        playerRating = rating
        showingPlayerRater = false

        // IMPORTANT: Mark STY Check as used during onboarding
        // This prevents unlimited free uses if user exits before completing onboarding
        if rating != nil {
            UserDefaults.standard.set(true, forKey: "hasUsedOnboardingSTYRating")
        }

        // Call the stored navigation completion
        navigationCompletion?(.proceed)
        navigationCompletion = nil
    }

    // MARK: - Profile Management
    func saveProfileToDefaults() {
        guard let profile = playerProfile else { return }

        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(profile)
            UserDefaults.standard.set(data, forKey: "playerProfile")
            print("[Onboarding] ✅ Profile saved to UserDefaults")
        } catch {
            print("[Onboarding] ❌ Failed to save profile: \(error)")
        }
    }
}
