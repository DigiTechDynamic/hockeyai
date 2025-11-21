import UIKit
import SwiftUI

// MARK: - App Store Configuration
/// App Store link for sharing (automatically uses App Store ID if available)
private let appStoreURL: String = {
    // Check if app is published with App Store ID
    if let appStoreID = Bundle.main.infoDictionary?["APP_STORE_ID"] as? String {
        return "https://apps.apple.com/app/id\(appStoreID)"
    }
    // Temporary: Use Google search until you set up custom domain or get App Store ID
    // TODO: Before launch, either:
    //   1. Buy custom domain (styhockey.app) and update this
    //   2. Add APP_STORE_ID to Info.plist after App Store approval
    return "https://google.com/search?q=STY+Hockey+app"
}()
private let appName = "Hockey AI"

// MARK: - Share Content Type
/// Defines the type of content being shared for template selection and analytics
public enum ShareContentType: String, Codable {
    case styCheck = "sty_check"
    case skillCheck = "skill_check"
    case stickAnalysis = "stick_analysis"
    case shotRater = "shot_rater"
    case aiCoachFlow = "ai_coach_flow"
    case generic = "generic"

    /// Display name for analytics
    var displayName: String {
        switch self {
        case .styCheck: return "STY Check"
        case .skillCheck: return "Skill Check"
        case .stickAnalysis: return "Stick Analysis"
        case .shotRater: return "Shot Rater"
        case .aiCoachFlow: return "AI Coach Flow"
        case .generic: return "Generic"
        }
    }
}

// MARK: - Share Content
/// Complete data model for sharing content across the app (TEXT-ONLY, no images)
public struct ShareContent {
    // MARK: - Core Data
    public let type: ShareContentType
    public let score: Int?
    public let title: String?
    public let subtitle: String?
    public let comment: String?

    // MARK: - Metadata
    public let userId: String?
    public let sessionId: String?
    public let metadata: [String: Any]

    // MARK: - Viral Mechanics
    /// Social proof text (e.g., "2,847 players shared today")
    public let socialProofText: String?

    /// Custom share text override
    public let customShareText: String?

    // MARK: - Initialization
    public init(
        type: ShareContentType,
        score: Int? = nil,
        title: String? = nil,
        subtitle: String? = nil,
        comment: String? = nil,
        userId: String? = nil,
        sessionId: String? = nil,
        metadata: [String: Any] = [:],
        socialProofText: String? = nil,
        customShareText: String? = nil
    ) {
        self.type = type
        self.score = score
        self.title = title
        self.subtitle = subtitle
        self.comment = comment
        self.userId = userId
        self.sessionId = sessionId
        self.metadata = metadata
        self.socialProofText = socialProofText
        self.customShareText = customShareText
    }

    // MARK: - Smart Share Text Generation
    /// Generates optimized share text based on content type and score
    public var shareText: String {
        // Use custom text if provided
        if let customText = customShareText {
            return customText
        }

        // Generate smart text based on type
        switch type {
        case .styCheck:
            return generateSTYCheckText()
        case .skillCheck:
            return generateSkillCheckText()
        case .stickAnalysis:
            return generateStickAnalysisText()
        case .shotRater:
            return generateShotRaterText()
        case .aiCoachFlow:
            return generateAICoachText()
        case .generic:
            return "Check this out! 🏒"
        }
    }

    // MARK: - Text Generation Helpers
    private func generateSTYCheckText() -> String {
        guard let score = score else {
            // ONBOARDING VALIDATION (no score) - Optimized for viral downloads
            // Uses challenge + FOMO mechanics (research: 22% more shares + 332% conversion boost)
            return "Yo there's a Greeny hockey app now\n\nJust got validated, you gotta try this\n\n\(appStoreURL)"
        }

        // FULL STY CHECK (with score) - Viral hook based on score tier
        let hook: String
        if score >= 90 {
            hook = "I scored \(score)/100 on STY Check! 😤 Can you beat it?"
        } else if score >= 75 {
            hook = "Just got a \(score)/100 on STY Check! Not bad 🔥"
        } else if score >= 60 {
            hook = "STY Check says I'm a \(score)/100! What's your rating?"
        } else {
            hook = "Got my STY rating: \(score)/100! Your turn"
        }

        return "\(hook) 🏒\n\nDownload \(appName): \(appStoreURL)"
    }

    private func generateSkillCheckText() -> String {
        guard let skill = title else {
            return "Just analyzed my hockey skills! 🏒\n\n\(appStoreURL)"
        }

        if let score = score {
            return "My \(skill) is rated \(score)/100! 🔥\n\nAnalyze yours: \(appStoreURL)"
        }

        return "Just got my \(skill) analyzed by AI! 🏒\n\nTry it: \(appStoreURL)"
    }

    private func generateStickAnalysisText() -> String {
        if let title = title {
            return "AI says my perfect stick is \(title)! 🏒\n\nFind yours: \(appStoreURL)"
        }
        return "Just got my perfect stick recommendation! 🏒\n\n\(appStoreURL)"
    }

    private func generateShotRaterText() -> String {
        guard let score = score else {
            return "AI just analyzed my shot! 🏒\n\n\(appStoreURL)"
        }

        let hook = score >= 85
            ? "My shot rated \(score)/100! 🚨 Can you do better?"
            : "Shot analysis: \(score)/100! What's yours?"

        return "\(hook) 🏒\n\n\(appStoreURL)"
    }

    private func generateAICoachText() -> String {
        return "Just got AI coaching on my technique! 🏒\n\nTry it: \(appStoreURL)"
    }

    // MARK: - Top Percentage Badge
    /// Returns badge text if score qualifies (e.g., "Top 10%")
    public var topPercentageBadge: String? {
        guard let score = score else { return nil }

        // Based on typical distribution
        if score >= 95 {
            return "TOP 1%"
        } else if score >= 90 {
            return "TOP 5%"
        } else if score >= 85 {
            return "TOP 10%"
        } else if score >= 80 {
            return "TOP 20%"
        }

        return nil
    }

    // MARK: - Analytics Properties
    /// Convert to dictionary for analytics tracking
    public var analyticsProperties: [String: Any] {
        var props: [String: Any] = [
            "content_type": type.rawValue,
            "content_type_display": type.displayName
        ]

        if let score = score {
            props["score"] = score
            props["has_top_badge"] = topPercentageBadge != nil
            if let badge = topPercentageBadge {
                props["top_badge"] = badge
            }
        }

        if let title = title {
            props["title"] = title
        }

        if let userId = userId {
            props["user_id"] = userId
        }

        if let sessionId = sessionId {
            props["session_id"] = sessionId
        }

        // Merge custom metadata
        for (key, value) in metadata {
            props[key] = value
        }

        return props
    }
}

// MARK: - Share Result
/// Result from a share action
public struct ShareResult {
    public let completed: Bool
    public let activityType: String?
    public let error: Error?

    public init(completed: Bool, activityType: String? = nil, error: Error? = nil) {
        self.completed = completed
        self.activityType = activityType
        self.error = error
    }

    /// Platform name for analytics (e.g., "Instagram", "Messages")
    public var platformName: String {
        guard let activityType = activityType else {
            return "unknown"
        }

        // Map UIActivity types to readable names
        if activityType.contains("Instagram") {
            return "Instagram"
        } else if activityType.contains("Twitter") || activityType.contains("com.atebits.Tweetie2") {
            return "Twitter"
        } else if activityType.contains("Facebook") {
            return "Facebook"
        } else if activityType.contains("TikTok") {
            return "TikTok"
        } else if activityType.contains("Snapchat") {
            return "Snapchat"
        } else if activityType == "com.apple.UIKit.activity.Message" {
            return "Messages"
        } else if activityType == "com.apple.UIKit.activity.Mail" {
            return "Mail"
        } else if activityType == "com.apple.UIKit.activity.CopyToPasteboard" {
            return "Copy"
        } else if activityType == "com.apple.UIKit.activity.SaveToCameraRoll" {
            return "Save to Photos"
        } else if activityType.contains("WhatsApp") {
            return "WhatsApp"
        } else {
            return activityType
        }
    }
}
