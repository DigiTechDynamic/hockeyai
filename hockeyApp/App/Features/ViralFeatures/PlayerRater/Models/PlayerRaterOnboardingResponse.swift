import Foundation

// MARK: - Player Rater Onboarding Response
/// Simplified response for onboarding validation (5 fields only)
/// This dramatically reduces output tokens and speeds up onboarding
struct PlayerRaterOnboardingResponse: Codable {
    let contains_person: Bool
    let overall_score: Int
    let tier: String
    let ai_comment: String
    let visual_observations: [String]

    // MARK: - Computed Properties

    /// Tier emoji for onboarding
    var tierEmoji: String {
        return contains_person ? "💪✨" : "❌"
    }

    // MARK: - Conversion to Full Response

    /// Convert onboarding response to full PlayerRaterResponse with default values
    /// This allows the rest of the app to work with a consistent model
    func toFullResponse() -> PlayerRaterResponse {
        return PlayerRaterResponse(
            contains_person: contains_person,
            visual_observations: visual_observations,
            gear_components: [],  // Empty for onboarding
            overall_score: overall_score,
            description: ai_comment,  // Reuse comment as description
            ai_comment: ai_comment,
            // Default premium intangibles (not analyzed during onboarding)
            confidence_score: 0,
            confidence_explanation: "",
            toughness_score: 0,
            toughness_explanation: "",
            flow_score: 0,
            flow_explanation: "",
            intimidation_score: 0,
            intimidation_explanation: "",
            locker_room_nickname: "",
            nickname_explanation: "",
            pro_comparison: "",
            pro_comparison_explanation: ""
        )
    }
}
