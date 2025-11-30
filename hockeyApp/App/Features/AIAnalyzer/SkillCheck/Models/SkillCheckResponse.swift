import Foundation

// MARK: - Skill Check Response
struct SkillCheckResponse: Codable {
    let confidence: Double
    let overall_rating: Int
    let category: String?
    let aiComment: String  // Greeny's personalized comment

    // PREMIUM: Actionable Feedback
    let whatYouDidWell: [String]    // 3 specific positives
    let whatToWorkOn: [String]      // 3 areas to improve
    let howToImprove: [String]      // 3 drills/exercises

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
        case whatYouDidWell = "what_you_did_well"
        case whatToWorkOn = "what_to_work_on"
        case howToImprove = "how_to_improve"
        case metadata
    }

    /// Premium breakdown as structured model
    var premiumBreakdown: PremiumSkillBreakdown {
        PremiumSkillBreakdown(
            whatYouDidWell: whatYouDidWell,
            whatToWorkOn: whatToWorkOn,
            howToImprove: howToImprove
        )
    }
}

// MARK: - Premium Skill Breakdown Model
/// Structured model for premium skill breakdown - actionable improvement feedback
struct PremiumSkillBreakdown: Codable, Equatable {
    let whatYouDidWell: [String]    // 3 specific positives
    let whatToWorkOn: [String]      // 3 areas to improve
    let howToImprove: [String]      // 3 drills/exercises

    /// Placeholder for preview/testing
    static var placeholder: PremiumSkillBreakdown {
        PremiumSkillBreakdown(
            whatYouDidWell: [
                "Great weight transfer from back to front foot",
                "Smooth stick flex loading on the release",
                "Good follow-through toward the target"
            ],
            whatToWorkOn: [
                "Keep your elbow higher during the release",
                "Bend your knees more for increased power",
                "Shift weight forward slightly earlier"
            ],
            howToImprove: [
                "Wall shots - 50 reps daily focusing on quick release",
                "One-knee wrist shots to isolate upper body mechanics",
                "Target practice with four corners drill"
            ]
        )
    }
}
