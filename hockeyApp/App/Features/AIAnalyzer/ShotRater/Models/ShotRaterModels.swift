import Foundation
import SwiftUI

// MARK: - Shot Types
enum ShotType: String, CaseIterable, Codable, Equatable, Identifiable {
    case wristShot = "Wrist Shot"
    case slapShot = "Slap Shot"
    case backhandShot = "Backhand"
    case snapShot = "Snap Shot"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .wristShot:
            return "Wrist Shot"
        case .slapShot:
            return "Slap Shot"
        case .backhandShot:
            return "Backhand"
        case .snapShot:
            return "Snap Shot"
        }
    }
    
    var icon: String {
        switch self {
        case .wristShot:
            return "sportscourt"
        case .slapShot:
            return "bolt.fill"
        case .backhandShot:
            return "arrow.turn.up.left"
        case .snapShot:
            return "bolt"
        }
    }
    
    var description: String {
        switch self {
        case .wristShot:
            return "Test your accuracy and quick release technique"
        case .slapShot:
            return "Measure your power and wind-up mechanics"
        case .backhandShot:
            return "Rate your backhand lift and deception"
        case .snapShot:
            return "Evaluate your quick release and shot velocity"
        }
    }
    
    var color: Color {
        switch self {
        case .wristShot:
            return .blue
        case .slapShot:
            return .red
        case .backhandShot:
            return .purple
        case .snapShot:
            return .orange
        }
    }
}

// MARK: - Shot Analysis Result
struct ShotAnalysisResult: Codable, Equatable {
    let type: ShotType
    let confidence: Double
    let overallScore: Int?
    let metrics: ShotMetrics
    let tips: String
    let videoURL: URL?
    let analysisMetadata: VideoAnalysisMetadata
    let detectedType: ShotType?
    let hasTypeMismatch: Bool
    
    // Computed property for star rating based on score
    var starRating: Int? {
        guard let score = overallScore else { return nil }
        switch score {
        case 90...100: return 5
        case 70..<90: return 4
        case 50..<70: return 3
        case 30..<50: return 2
        default: return 1
        }
    }
    
    // Computed properties for backward compatibility
    var recommendedShotType: String? {
        detectedType?.rawValue
    }
    
    var mismatchMessage: String? {
        guard hasTypeMismatch, let detected = detectedType else { return nil }
        return "Detected \(detected.displayName) instead of \(type.displayName)"
    }
    
    // Helper to extract summary and details from combined tips
    var summary: String {
        let parts = tips.components(separatedBy: "|||")
        return parts.first ?? tips
    }
    
    var detailedTips: String {
        let parts = tips.components(separatedBy: "|||")
        return parts.count > 1 ? parts[1] : tips
    }
    
    // Helper for score color
    var scoreColorName: String {
        guard let score = overallScore else { return "gray" }
        switch score {
        case 90...100:
            return "green"
        case 70..<90:
            return "blue"
        case 50..<70:
            return "yellow"
        case 30..<50:
            return "orange"
        default:
            return "red"
        }
    }
    
    // Helper for score label
    var scoreLabel: String {
        guard let score = overallScore else { return "No Score" }
        switch score {
        case 90...100:
            return "Excellent"
        case 70..<90:
            return "Good"
        case 50..<70:
            return "Fair"
        case 30..<50:
            return "Needs Work"
        default:
            return "Poor"
        }
    }
    
    // Placeholder result for no shot detected
    static func noShotDetected(for shotType: ShotType, videoURL: URL?) -> ShotAnalysisResult {
        return ShotAnalysisResult(
            type: shotType,
            confidence: 1.0,
            overallScore: nil,
            metrics: ShotMetrics(
                technique: ShotMetric(score: nil, reason: "No hockey shot detected"),
                power: ShotMetric(score: nil, reason: "No hockey shot detected")
            ),
            tips: "No hockey shot was detected in the video. Please ensure you're recording a clear \(shotType.displayName) with good lighting and the full motion visible.",
            videoURL: videoURL,
            analysisMetadata: VideoAnalysisMetadata(
                videoDuration: 0,
                videoResolution: .zero,
                videoFileSize: 0,
                processingTime: 0,
                selectedShotType: shotType.rawValue
            ),
            detectedType: nil,
            hasTypeMismatch: false
        )
    }
}

// MARK: - Identifiable for UI presentation
extension ShotAnalysisResult: Identifiable {
    var id: String {
        let url = videoURL?.lastPathComponent ?? "none"
        return "\(type.rawValue)|\(analysisMetadata.selectedShotType)|\(Int(analysisMetadata.processingTime * 1000))|\(url)"
    }
}


// MARK: - Shot Metrics
struct ShotMetrics: Codable, Equatable {
    let technique: ShotMetric
    let power: ShotMetric
    
    init(technique: ShotMetric, power: ShotMetric) {
        self.technique = technique
        self.power = power
    }
}

// MARK: - Shot Metric
struct ShotMetric: Codable, Equatable {
    let score: Int?
    let reason: String
    
    init(score: Int?, reason: String) {
        self.score = score
        self.reason = reason
    }
}

// MARK: - Video Analysis Metadata
struct VideoAnalysisMetadata: Codable, Equatable {
    var videoDuration: Double
    var videoResolution: CGSize
    var videoFileSize: Int64
    var processingTime: TimeInterval
    var selectedShotType: String
    
    init(
        videoDuration: Double,
        videoResolution: CGSize,
        videoFileSize: Int64,
        processingTime: TimeInterval,
        selectedShotType: String
    ) {
        self.videoDuration = videoDuration
        self.videoResolution = videoResolution
        self.videoFileSize = videoFileSize
        self.processingTime = processingTime
        self.selectedShotType = selectedShotType
    }
}

