import Foundation
import SwiftUI

// MARK: - AI Coach Analysis Flow
/// Linear flow implementation for AI Coach
class AICoachAnalysisFlow: LinearAIFlow {
    let shotType: ShotType?
    
    init(stages: [any AIFlowStage], shotType: ShotType? = nil) {
        self.shotType = shotType
        super.init(
            id: "ai-coach-flow",
            name: "AI Coach Analysis",
            stages: stages,
            allowsBackNavigation: true,
            showsProgress: true
        )
    }
}

// MARK: - Player Profile Stage
/// Custom stage for player profile input
struct PlayerProfileStage: AIFlowStage {
    let id: String
    let title: String
    let subtitle: String
    let isRequired: Bool
    let canSkip: Bool
    let canGoBack: Bool = true
    
    func validate(data: Any?) -> AIValidationResult {
        guard let profile = data as? PlayerProfile else {
            return .invalid("Please complete your player profile")
        }
        return .valid
    }
}

// MARK: - AI Coach Analysis Result
struct AICoachAnalysisResult {
    let shotType: ShotType
    let playerProfile: PlayerProfile
    let frontNetVideoURL: URL
    let sideAngleVideoURL: URL
    let processingTime: TimeInterval

    // Direct typed response - no conversion needed!
    let response: AICoachSimpleResponse

    // Convenience accessors
    var overallRating: Int { response.overall_rating }
    var confidence: Double { response.confidence }
    
    // Direct access to metadata
    var framesAnalyzed: Int {
        response.metadata.frames_analyzed
    }

    var biomechanics: RadarChartMetrics {
        let metrics = response.radar_metrics

        return RadarChartMetrics(
            stance: MetricScore(
                name: "Stance",
                score: metrics.stance_score,
                descriptor: getDescriptor(for: metrics.stance_score),
                status: MetricStatus(score: metrics.stance_score)
            ),
            balance: MetricScore(
                name: "Balance",
                score: metrics.balance_score,
                descriptor: getDescriptor(for: metrics.balance_score),
                status: MetricStatus(score: metrics.balance_score)
            ),
            followThrough: MetricScore(
                name: "Follow Through",
                score: metrics.follow_through_score,
                descriptor: getDescriptor(for: metrics.follow_through_score),
                status: MetricStatus(score: metrics.follow_through_score)
            ),
            explosivePower: MetricScore(
                name: "Power",
                score: metrics.explosive_power_score,
                descriptor: getDescriptor(for: metrics.explosive_power_score),
                status: MetricStatus(score: metrics.explosive_power_score)
            ),
            releasePoint: MetricScore(
                name: "Release",
                score: metrics.release_point_score,
                descriptor: getDescriptor(for: metrics.release_point_score),
                status: MetricStatus(score: metrics.release_point_score)
            ),
            overallScore: overallRating,
            response: response
        )
    }
    
    // Helper function for metric descriptors
    private func getDescriptor(for score: Int) -> String {
        switch score {
        case 90...100: return "Excellent"
        case 80...89: return "Strong"
        case 70...79: return "Good"
        case 60...69: return "Developing"
        default: return "Needs Work"
        }
    }
}

// MARK: - Radar Chart Metrics (kept for UI compatibility)
struct RadarChartMetrics {
    let stance: MetricScore         // Foundation setup
    let balance: MetricScore        // Control throughout
    let followThrough: MetricScore   // Completion
    let explosivePower: MetricScore  // Quick force generation
    let releasePoint: MetricScore    // Puck departure position
    let overallScore: Int           // Calculated from all 5
    let response: AICoachSimpleResponse  // Direct typed response
    
    var focusArea: FocusAreaMetric {
        let scores = [stance, balance, followThrough, explosivePower, releasePoint]
        let lowest = scores.min { $0.score < $1.score }!

        return FocusAreaMetric(
            metric: lowest,
            improvementTip: getImprovementTip(for: lowest.name),
            primaryFocus: response.primary_focus
        )
    }
    
    func getReasoningForMetric(_ metricName: String) -> String {
        let reasoning = response.metric_reasoning

        switch metricName.lowercased() {
        case "stance":
            return reasoning.stance
        case "balance":
            return reasoning.balance
        case "follow through":
            return reasoning.follow_through
        case "power":
            return reasoning.power
        case "release":
            return reasoning.release
        default:
            return "Analysis not available for this metric."
        }
    }
    
    private func getScoreForMetric(_ metricName: String) -> Int {
        switch metricName.lowercased() {
        case "stance": return stance.score
        case "balance": return balance.score
        case "follow through": return followThrough.score
        case "power": return explosivePower.score
        case "release": return releasePoint.score
        default: return 70
        }
    }
    
    private func getImprovementTip(for metric: String) -> String {
        let tips = response.improvement_tips

        switch metric.lowercased() {
        case "stance":
            return tips.stance
        case "balance":
            return tips.balance
        case "follow through":
            return tips.follow_through
        case "power":
            return tips.power
        case "release":
            return tips.release
        default:
            return "Focus on consistent practice and proper technique"
        }
    }
}

struct MetricScore {
    let name: String
    let score: Int          // 0-100
    let descriptor: String  // "Excellent", "Strong", "Needs work"
    let status: MetricStatus
    
    var statusIcon: String {
        switch status {
        case .excellent: return "checkmark.circle.fill"
        case .good: return "checkmark.circle"
        case .needsWork: return "exclamationmark.triangle"
        }
    }
}

enum MetricStatus {
    case excellent  // 80%+
    case good       // 70-79%
    case needsWork  // <70%
    
    init(score: Int) {
        if score >= 80 {
            self = .excellent
        } else if score >= 70 {
            self = .good
        } else {
            self = .needsWork
        }
    }
}

struct FocusAreaMetric {
    let metric: MetricScore
    let improvementTip: String  // Short tip for backward compatibility
    let currentVsTarget: String
    let motivationalMessage: String

    // Detailed coaching information - direct from typed response
    let specificIssue: String
    let whyItMatters: String
    let howToImprove: String
    let coachingCues: [String]
    let drill: String

    init(metric: MetricScore, improvementTip: String, primaryFocus: AICoachSimpleResponse.PrimaryFocus) {
        self.metric = metric
        self.improvementTip = improvementTip

        // Direct typed access - no extraction needed!
        self.specificIssue = primaryFocus.specific_issue
        self.whyItMatters = primaryFocus.why_it_matters
        self.howToImprove = primaryFocus.how_to_improve
        self.coachingCues = primaryFocus.coaching_cues
        self.drill = primaryFocus.drill

        // Generate simplified progress indicator
        let target = 85
        let gap = target - metric.score

        // Create friendly progress message
        if gap > 0 {
            switch gap {
            case 1...5:
                self.currentVsTarget = "Almost there - minor adjustments needed"
                self.motivationalMessage = whyItMatters
            case 6...10:
                self.currentVsTarget = "Good foundation - room to grow"
                self.motivationalMessage = whyItMatters
            case 11...15:
                self.currentVsTarget = "Key area for improvement"
                self.motivationalMessage = whyItMatters
            default:
                self.currentVsTarget = "Primary development area"
                self.motivationalMessage = whyItMatters
            }
        } else {
            self.currentVsTarget = "Excellent - maintain and refine"
            self.motivationalMessage = "You've mastered this fundamental!"
        }
    }
}


