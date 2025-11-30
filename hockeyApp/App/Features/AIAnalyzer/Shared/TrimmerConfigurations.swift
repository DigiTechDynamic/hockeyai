import SwiftUI

// MARK: - AI Analyzer Trimmer Configurations
/// Predefined trimmer configurations for each AI Analyzer feature
public extension VideoTrimmerConfig {
    
    /// Configuration for Shot Rater - requires clips up to 3 seconds
    static func shotRater() -> VideoTrimmerConfig {
        VideoTrimmerConfig(
            title: "Trim Video",
            subtitle: "Select a clip (3 seconds or less)",
            minDuration: 0.3,
            maxDuration: 3.0,
            buttonTitle: "Use Clip",
            validationMessage: "Perfect!"
        )
    }
    
    /// Configuration for AI Coach - clips up to 3 seconds
    static func aiCoach() -> VideoTrimmerConfig {
        VideoTrimmerConfig(
            title: "Trim Video",
            subtitle: "Select a clip (3 seconds or less)",
            minDuration: 0.3,
            maxDuration: 3.0,
            buttonTitle: "Use Clip",
            validationMessage: "Perfect!"
        )
    }
    
    /// Configuration for Stick Analyzer - clips up to 3 seconds
    static func stickAnalyzer() -> VideoTrimmerConfig {
        VideoTrimmerConfig(
            title: "Trim Video",
            subtitle: "Select a clip (3 seconds or less)",
            minDuration: 0.3,
            maxDuration: 3.0,
            buttonTitle: "Use Clip",
            validationMessage: "Perfect!"
        )
    }
    
    /// Configuration for Skill Check - allows up to 10 seconds for various skills
    static func skillCheck() -> VideoTrimmerConfig {
        VideoTrimmerConfig(
            title: "Trim Video",
            subtitle: "Select a clip (10 seconds or less)",
            minDuration: 0.5,
            maxDuration: 10.0,
            buttonTitle: "Use Clip",
            validationMessage: "Perfect!"
        )
    }

    /// Configuration for Shot Rater with custom duration
    static func shotRater(minDuration: Double, maxDuration: Double) -> VideoTrimmerConfig {
        let title = minDuration == maxDuration ?
            "Trim to \(Int(minDuration)) second\(minDuration == 1 ? "" : "s")" :
            "Trim to \(Int(minDuration))-\(Int(maxDuration)) seconds"

        return VideoTrimmerConfig(
            title: title,
            subtitle: "Select the perfect shot moment",
            minDuration: minDuration,
            maxDuration: min(maxDuration, 3.0), // Cap at 3 seconds max
            buttonTitle: "Use This Clip",
            validationMessage: "Perfect duration!"
        )
    }
}