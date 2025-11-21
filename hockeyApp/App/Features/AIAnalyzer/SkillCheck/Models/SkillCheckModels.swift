import Foundation
import SwiftUI

// MARK: - Skill Analysis Result
struct SkillAnalysisResult: Codable, Equatable, Identifiable {
    let id = UUID().uuidString
    let confidence: Double
    let overallScore: Int
    let category: String?
    let aiComment: String  // Greeny's personalized comment
    let premiumBreakdown: PremiumSkillBreakdown  // Viral-optimized premium content
    let videoURL: URL?
    let analysisMetadata: VideoAnalysisMetadata
}

