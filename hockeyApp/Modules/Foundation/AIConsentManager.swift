import Foundation
import SwiftUI

// MARK: - AI Consent Manager
/// Manages user consent for third-party AI processing (OpenAI, Google Gemini)
/// Required for Apple App Store compliance (Nov 2025 requirement)
@MainActor
class AIConsentManager: ObservableObject {
    static let shared = AIConsentManager()

    @Published private(set) var hasGivenConsent: Bool

    private let consentKey = "hasGivenAIConsent"

    private init() {
        self.hasGivenConsent = UserDefaults.standard.bool(forKey: consentKey)
    }

    /// Check if user has already given consent
    var needsConsent: Bool {
        return !hasGivenConsent
    }

    /// Record user consent
    func grantConsent() {
        hasGivenConsent = true
        UserDefaults.standard.set(true, forKey: consentKey)
        print("✅ [AIConsentManager] User granted AI processing consent")
    }

    /// Revoke consent (for privacy settings)
    func revokeConsent() {
        hasGivenConsent = false
        UserDefaults.standard.set(false, forKey: consentKey)
        print("❌ [AIConsentManager] User revoked AI processing consent")
    }

    /// Reset consent (for testing)
    func resetConsent() {
        hasGivenConsent = false
        UserDefaults.standard.removeObject(forKey: consentKey)
        print("🔄 [AIConsentManager] AI consent reset")
    }
}

// MARK: - AI Consent Dialog View
/// Centered overlay card matching CameraQualityTutorial style
struct AIConsentDialog: View {
    @Environment(\.theme) var theme
    let onAccept: () -> Void
    let onDecline: () -> Void

    var body: some View {
        BaseCard(style: .glass) {
            VStack(spacing: theme.spacing.lg) {
                // Header
                VStack(spacing: theme.spacing.sm) {
                    headerIcon

                    Text("AI-Powered Analysis")
                        .font(theme.fonts.title)
                        .foregroundColor(theme.text)

                    Text("To analyze your hockey training, we process photos/videos with trusted third‑party AI services.")
                        .font(theme.fonts.callout)
                        .foregroundColor(theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, theme.spacing.lg)
                }
                .padding(.top, theme.spacing.sm)

                // Privacy assurances
                VStack(alignment: .leading, spacing: theme.spacing.md) {
                    privacyAssuranceRow(icon: "lock.shield.fill", text: "Media only used for analysis")
                    privacyAssuranceRow(icon: "xmark.circle.fill", text: "Not used to train AI models")
                    privacyAssuranceRow(icon: "person.fill.xmark", text: "No personal info shared with providers")
                }
                .padding(.horizontal, theme.spacing.lg)

                // Privacy link
                HStack(spacing: 6) {
                    Text("Learn more in our")
                        .font(theme.fonts.caption)
                        .foregroundColor(theme.textSecondary)
                    Link("Privacy Policy",
                         destination: URL(string: "https://docs.google.com/document/d/1sVyqytQLQfAE1dFUzZvXx5H7wZQ7W-Nc3K9d0bIUM08/edit?tab=t.0#heading=h.57lx0vttzc7l")!)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(theme.primary)
                }

                // Actions
                VStack(spacing: theme.spacing.sm) {
                    AppButton(title: "I Agree - Continue", action: {
                        AIConsentManager.shared.grantConsent()
                        onAccept()
                    }, style: .primary, size: .large)

                    AppButton(title: "No Thanks", action: {
                        onDecline()
                    }, style: .ghost, size: .medium)
                }
                .padding(.horizontal, theme.spacing.lg)
                .padding(.bottom, theme.spacing.sm)
            }
        }
        .frame(maxWidth: 460)
        .padding(theme.spacing.lg)
    }

    // MARK: - Header Icon
    private var headerIcon: some View {
        ZStack {
            Circle()
                .fill(theme.primary.opacity(0.1))
                .frame(width: 64, height: 64)
                .overlay(
                    Circle()
                        .stroke(theme.primary.opacity(0.35), lineWidth: 1)
                )
            Image(systemName: "brain.head.profile")
                .font(.system(size: 30, weight: .semibold))
                .foregroundColor(theme.primary)
        }
    }

    private func privacyAssuranceRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(theme.primary)
                .frame(width: 20)

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(theme.textSecondary)
        }
    }
}

// MARK: - Preview
#Preview("AI Consent Dialog") {
    AIConsentDialog(
        onAccept: { print("Accepted") },
        onDecline: { print("Declined") }
    )
}
