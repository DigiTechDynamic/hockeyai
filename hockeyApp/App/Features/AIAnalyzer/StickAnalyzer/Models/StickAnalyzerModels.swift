import Foundation
import SwiftUI

// MARK: - Stick Analyzer Flow Holder
/// Holds the flow definition and state for Stick Analyzer
class StickAnalyzerFlowHolder: ObservableObject {
    @Published var flow: StickAnalyzerFlow
    
    init() {
        self.flow = StickAnalyzerConfig.buildFlow()
    }
}

// MARK: - Stick Analyzer Flow
/// Linear flow implementation for Stick Analyzer
class StickAnalyzerFlow: LinearAIFlow {
    init(stages: [any AIFlowStage]) {
        super.init(
            id: "stick-analyzer-flow",
            name: "Stick Analysis",
            stages: stages,
            allowsBackNavigation: true,
            showsProgress: true
        )
    }
}

// MARK: - Custom Stage for Stick Details
struct StickDetailsStage: AIFlowStage {
    let id: String
    let title: String
    let subtitle: String
    let isRequired: Bool
    let canSkip: Bool
    let canGoBack: Bool = true
    
    func validate(data: Any?) -> AIValidationResult {
        guard let details = data as? StickDetails else {
            return .invalid("Please provide stick details")
        }
        
        // If specs unknown, that's valid
        if details.unknownSpecs {
            return .valid
        }
        
        // Otherwise need at least brand/model
        if details.brand?.isEmpty ?? true {
            return .invalid("Please enter your stick brand")
        }
        
        return .valid
    }
}


// MARK: - Stick Details
struct StickDetails: Codable {
    let brand: String?
    let model: String?
    let flex: Int?
    let length: Double?
    let curvePattern: String?
    let kickPoint: KickPointType?
    let lie: Int?
    let unknownSpecs: Bool
    
    var displayName: String {
        if unknownSpecs {
            return "Unknown Stick"
        }
        if let brand = brand, let model = model {
            return "\(brand) \(model)"
        }
        return brand ?? "Current Stick"
    }
}

// MARK: - Kick Point Type
enum KickPointType: String, CaseIterable, Codable {
    case low = "Low"
    case mid = "Mid"
    case high = "High"
    
    var description: String {
        switch self {
        case .low:
            return "Quick release, good for wrist shots"
        case .mid:
            return "Balanced for all shot types"
        case .high:
            return "Maximum power for slap shots"
        }
    }
}

// MARK: - Shooting Questionnaire
struct ShootingQuestionnaire: Codable {
    let priorityFocus: PriorityFocus
    let primaryShot: PrimaryShotType
    let shootingZone: ShootingZone
}

enum PriorityFocus: String, CaseIterable, Codable {
    case power = "Power"
    case accuracy = "Accuracy"
    case balance = "Balance"
    
    var icon: String {
        switch self {
        case .power: return "bolt.fill"
        case .accuracy: return "target"
        case .balance: return "scalemass"
        }
    }
}

enum PrimaryShotType: String, CaseIterable, Codable {
    case wrist = "Wrist Shot"
    case slap = "Slap Shot"
    case snap = "Snap Shot"
    case backhand = "Backhand"
    
    var icon: String {
        switch self {
        case .wrist: return "hockey.puck"
        case .slap: return "bolt"
        case .snap: return "sparkles"
        case .backhand: return "arrow.uturn.left"
        }
    }
}

enum ShootingZone: String, CaseIterable, Codable {
    case point = "Point"
    case slot = "Slot"
    case closeRange = "Close Range"
    case varies = "Varies"
    
    var description: String {
        switch self {
        case .point: return "Blue line area"
        case .slot: return "Between circles"
        case .closeRange: return "Near the crease"
        case .varies: return "All zones"
        }
    }
}

// MARK: - Stick Analysis Result
struct StickAnalysisResult {
    let confidence: Double
    let playerProfile: PlayerProfile
    let shotVideoURL: URL
    let recommendations: StickRecommendations
    let processingTime: TimeInterval
}

// MARK: - Stick Recommendations
struct StickRecommendations {
    let idealFlex: FlexRange
    let idealLength: LengthRange
    let idealCurve: [String]
    let idealKickPoint: KickPointType
    let idealLie: Int
    let topStickModels: [RecommendedStick]
    // New: contextual reasoning for every spec
    let curveReasoning: String?
    let kickPointReasoning: String?
    let lieReasoning: String?
    // New: generic, non-brand profiles
    let recommendedProfiles: [StickProfile]?
}

struct FlexRange {
    let min: Int
    let max: Int
    let reasoning: String
    
    var displayString: String {
        "\(min)-\(max)"
    }
}

struct LengthRange {
    let minInches: Double
    let maxInches: Double
    let reasoning: String
    
    var displayString: String {
        "\(Int(minInches))-\(Int(maxInches))\""
    }
}

struct RecommendedStick {
    let brand: String
    let model: String
    let flex: Int
    let curve: String
    let kickPoint: KickPointType
    let price: String?
    let reasoning: String
    let matchScore: Int // 0-100
    
    var displayName: String {
        "\(brand) \(model)"
    }
}

// MARK: - Generic Stick Profile (brand-agnostic)
struct StickProfile {
    let name: String
    let flex: Int
    let curve: String
    let kickPoint: String
    let lie: Double
    let matchScore: Int
    let bestFor: String
    let whyItWorks: String
    let strengths: [String]?
    let tradeoffs: [String]?
}

// MARK: - Error Types
// StickAnalyzer now uses the unified AIAnalyzerError from Shared/Errors
