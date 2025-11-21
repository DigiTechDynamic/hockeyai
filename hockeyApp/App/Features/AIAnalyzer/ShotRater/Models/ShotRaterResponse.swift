import Foundation

// MARK: - Shot Rater Response
/// Typed response model that matches the simplified ShotRater schema structure
struct ShotRaterResponse: Codable {
    let confidence: Double
    let overall_rating: Int
    let technique_score: Int
    let technique_reason: String
    let power_score: Int
    let power_reason: String
    let summary: String
    let metadata: Metadata

    struct Metadata: Codable {
        let frames_analyzed: Int
        let fps: Int
        let video_duration: Double
    }

    // MARK: - Computed Properties for UI

    /// Overall rating label based on score
    var overallLabel: String {
        switch overall_rating {
        case 90...100: return "Excellent"
        case 70...89: return "Good"
        case 50...69: return "Fair"
        case 30...49: return "Needs Work"
        default: return "Poor"
        }
    }
}
