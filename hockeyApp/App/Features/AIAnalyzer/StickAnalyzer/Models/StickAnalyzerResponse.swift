import Foundation

// MARK: - Stick Analyzer Response
/// Typed response model that matches the StickAnalyzer schema structure
struct StickAnalysisResponse: Codable {
    let confidence: Double

    // Flex recommendations
    let ideal_flex_min: Int
    let ideal_flex_max: Int
    let flex_reasoning: String

    // Length recommendations
    let ideal_length_min: Double
    let ideal_length_max: Double
    let length_reasoning: String

    // Curve recommendations
    let ideal_curves: [String]
    let curve_reasoning: String

    // Kick point recommendation
    let ideal_kick_point: String
    let kick_point_reasoning: String

    // Lie angle
    let ideal_lie: Int
    let lie_reasoning: String

    // Stick recommendations
    let recommended_sticks: [AIRecommendedStick]
}

struct AIRecommendedStick: Codable {
    let brand: String
    let model: String
    let flex: Int
    let curve: String
    let kick_point: String
    let price: String?
    let reasoning: String
    let match_score: Int
}
