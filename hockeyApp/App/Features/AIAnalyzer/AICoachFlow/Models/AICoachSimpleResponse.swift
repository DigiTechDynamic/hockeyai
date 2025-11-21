import Foundation

// MARK: - AI Coach Simple Response
/// Response model that matches the simplified schema structure
struct AICoachSimpleResponse: Codable {
    let confidence: Double
    let overall_rating: Int
    let key_observation: String
    let video_context: VideoContext
    let radar_metrics: RadarMetrics
    let metric_reasoning: MetricReasoning
    let primary_focus: PrimaryFocus
    let improvement_tips: ImprovementTips
    let metadata: Metadata

    struct RadarMetrics: Codable {
        let stance_score: Int
        let balance_score: Int
        let follow_through_score: Int
        let explosive_power_score: Int
        let release_point_score: Int
    }

    struct MetricReasoning: Codable {
        let stance: String
        let balance: String
        let follow_through: String
        let power: String
        let release: String
    }

    struct PrimaryFocus: Codable {
        let metric: String
        let specific_issue: String
        let why_it_matters: String
        let how_to_improve: String
        let coaching_cues: [String]
        let drill: String
    }

    struct ImprovementTips: Codable {
        let stance: String
        let balance: String
        let follow_through: String
        let power: String
        let release: String
    }

    struct Metadata: Codable {
        let frames_analyzed: Int
        let fps: Int
        let angles_processed: Int
    }

    struct VideoContext: Codable {
        let items: [VideoContextItem]
    }

    struct VideoContextItem: Codable {
        let text: String
    }

    // MARK: - Computed Properties for UI

    /// Overall rating label based on score
    var overallLabel: String {
        switch overall_rating {
        case 90...100: return "Elite"
        case 80...89: return "Strong"
        case 70...79: return "Good"
        case 60...69: return "Developing"
        default: return "Needs Work"
        }
    }
}
