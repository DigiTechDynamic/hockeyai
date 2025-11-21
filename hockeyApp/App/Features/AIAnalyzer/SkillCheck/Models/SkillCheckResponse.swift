import Foundation

// MARK: - Skill Check Response
struct SkillCheckResponse: Codable {
    let confidence: Double
    let overall_rating: Int
    let category: String?
    let aiComment: String  // Greeny's personalized comment

    // PREMIUM: Style Metrics
    let flowScore: Int
    let confidenceScore: Int
    let stylePoints: Int

    // PREMIUM: Viral Potential
    let viralViewsEstimate: String
    let viralCaption: String

    // PREMIUM: Identity
    let trashTalkLine: String
    let signatureMoveName: String

    let metadata: Metadata

    struct Metadata: Codable {
        let frames_analyzed: Int
        let fps: Int
        let video_duration: Double
    }

    enum CodingKeys: String, CodingKey {
        case confidence
        case overall_rating
        case category
        case aiComment = "ai_comment"
        case flowScore = "flow_score"
        case confidenceScore = "confidence_score"
        case stylePoints = "style_points"
        case viralViewsEstimate = "viral_views_estimate"
        case viralCaption = "viral_caption"
        case trashTalkLine = "trash_talk_line"
        case signatureMoveName = "signature_move_name"
        case metadata
    }

    /// Premium breakdown as structured model
    var premiumBreakdown: PremiumSkillBreakdown {
        PremiumSkillBreakdown(
            flowScore: flowScore,
            confidenceScore: confidenceScore,
            stylePoints: stylePoints,
            viralViewsEstimate: viralViewsEstimate,
            viralCaption: viralCaption,
            trashTalkLine: trashTalkLine,
            signatureMoveName: signatureMoveName
        )
    }
}

// MARK: - Premium Skill Breakdown Model
/// Structured model for premium skill breakdown
struct PremiumSkillBreakdown: Codable, Equatable {
    let flowScore: Int
    let confidenceScore: Int
    let stylePoints: Int
    let viralViewsEstimate: String
    let viralCaption: String
    let trashTalkLine: String
    let signatureMoveName: String
}

