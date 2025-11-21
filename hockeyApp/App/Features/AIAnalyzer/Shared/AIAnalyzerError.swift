import Foundation

// MARK: - Unified AI Analyzer Error
/// Simplified error handling for all AI analyzer features (ShotRater, StickAnalyzer, AICoach)
public enum AIAnalyzerError: LocalizedError, Equatable {
    case networkIssue
    case aiProcessingFailed(String)
    case invalidContent(InvalidContentReason)
    case validationParsingFailed(String)  // Validation JSON couldn't be parsed
    case analysisParsingFailed(String)    // Analysis JSON couldn't be parsed

    // MARK: - Invalid Content Reasons
    public enum InvalidContentReason: Equatable {
        case aiDetectedInvalidContent(String) // AI-provided specific messages about video content
    }
    
    // MARK: - User-Facing Messages
    public var errorDescription: String? {
        switch self {
        case .networkIssue:
            return "Connection Error"
        case .aiProcessingFailed:
            return "Analysis Failed"
        case .invalidContent:
            return "Invalid Video"
        case .validationParsingFailed:
            return "Validation Failed"
        case .analysisParsingFailed:
            return "Processing Failed"
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .networkIssue:
            return "Unable to connect to the analysis service. Please check your internet connection."
        case .aiProcessingFailed(let details):
            return "The AI service couldn't analyze your video. \(details)"
        case .invalidContent(let reason):
            return reason.message
        case .validationParsingFailed(let details):
            return details
        case .analysisParsingFailed(let details):
            return details
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .networkIssue:
            return "Check your internet connection and try again."
        case .aiProcessingFailed:
            return "Try recording a shorter, clearer video."
        case .invalidContent(let reason):
            return reason.suggestion
        case .validationParsingFailed:
            return "This is usually temporary. Try again in a few seconds."
        case .analysisParsingFailed:
            return "The analysis completed but couldn't be displayed. Try analyzing again."
        }
    }
    
    // MARK: - Helper Properties
    
    /// Whether the error can be retried
    public var isRetryable: Bool {
        switch self {
        case .networkIssue, .aiProcessingFailed, .validationParsingFailed, .analysisParsingFailed:
            return true
        case .invalidContent:
            return false // Need new video
        }
    }
    
    /// Button text for the primary action
    public var actionButtonText: String {
        switch self {
        case .networkIssue, .aiProcessingFailed, .validationParsingFailed, .analysisParsingFailed:
            return "Try Again"
        case .invalidContent:
            return "Record New Video"
        }
    }
}

// MARK: - Invalid Content Reason Extensions
extension AIAnalyzerError.InvalidContentReason {
    var message: String {
        switch self {
        case .aiDetectedInvalidContent(let message):
            // Return the AI's message as-is
            return message
        }
    }

    var suggestion: String {
        switch self {
        case .aiDetectedInvalidContent:
            return "Record a hockey shot with proper form."
        }
    }

    var tips: [String] {
        switch self {
        case .aiDetectedInvalidContent:
            return [
                "Use a hockey stick and puck",
                "Record on ice, street, or synthetic surface",
                "Ensure the full shooting motion is visible",
                "Use good lighting and keep camera steady"
            ]
        }
    }
}

// MARK: - Error Conversion Helpers
extension AIAnalyzerError {
    /// Convert from generic errors
    public static func from(_ error: Error) -> AIAnalyzerError {
        // Check for network errors
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            return .networkIssue
        }
        
        // Check if the error message indicates a network issue
        let errorMessage = error.localizedDescription.lowercased()
        if errorMessage.contains("connection error") ||
           errorMessage.contains("network") ||
           errorMessage.contains("internet") ||
           errorMessage.contains("offline") {
            return .networkIssue
        }
        
        // AIAnalysisError has been removed - using unified error system
        
        // Default to processing failed
        return .aiProcessingFailed(error.localizedDescription)
    }
}