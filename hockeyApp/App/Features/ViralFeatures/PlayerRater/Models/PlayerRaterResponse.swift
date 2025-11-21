import Foundation

// MARK: - Player Rater Response
/// Response model for player aesthetic rating
struct PlayerRaterResponse: Codable {
    let contains_person: Bool
    let visual_observations: [String]
    let gear_components: [String]
    let overall_score: Int
    let description: String
    let ai_comment: String

    // PREMIUM INTANGIBLES
    let confidence_score: Int
    let confidence_explanation: String
    let toughness_score: Int
    let toughness_explanation: String
    let flow_score: Int
    let flow_explanation: String
    let intimidation_score: Int
    let intimidation_explanation: String
    let locker_room_nickname: String
    let nickname_explanation: String
    let pro_comparison: String
    let pro_comparison_explanation: String

    // MARK: - Computed Properties for UI

    /// Rating tier based on score (simplified 3-tier system)
    var tier: String {
        switch overall_score {
        case 90...100: return "Elite"       // Person WITH gear
        case 70..<90: return "Solid"        // Person WITHOUT gear (MOST USERS)
        case 50..<70: return "Hockey Item"  // Hockey item (no person)
        default: return "Not Hockey"        // Non-hockey items (0-49)
        }
    }

    /// Tier emoji (simplified 3-tier system)
    var tierEmoji: String {
        switch overall_score {
        case 90...100: return "⭐🔥"  // Person with gear
        case 70..<90: return "💪✨"   // Person without gear (MOST USERS)
        case 50..<70: return "🏒🎯"   // Hockey item only
        default: return "❌"          // Non-hockey
        }
    }

    /// Premium intangibles as a structured model
    var premiumIntangibles: PremiumIntangibles? {
        guard contains_person else { return nil }

        return PremiumIntangibles(
            confidenceScore: confidence_score,
            confidenceExplanation: confidence_explanation,
            toughnessScore: toughness_score,
            toughnessExplanation: toughness_explanation,
            flowScore: flow_score,
            flowExplanation: flow_explanation,
            intimidationScore: intimidation_score,
            intimidationExplanation: intimidation_explanation,
            lockerRoomNickname: locker_room_nickname,
            nicknameExplanation: nickname_explanation,
            proComparison: pro_comparison,
            proComparisonExplanation: pro_comparison_explanation
        )
    }
}

// MARK: - Premium Intangibles Model
/// Structured model for premium STY Check insights
struct PremiumIntangibles: Codable, Equatable {
    let confidenceScore: Int
    let confidenceExplanation: String
    let toughnessScore: Int
    let toughnessExplanation: String
    let flowScore: Int
    let flowExplanation: String
    let intimidationScore: Int
    let intimidationExplanation: String
    let lockerRoomNickname: String
    let nicknameExplanation: String
    let proComparison: String
    let proComparisonExplanation: String
}
