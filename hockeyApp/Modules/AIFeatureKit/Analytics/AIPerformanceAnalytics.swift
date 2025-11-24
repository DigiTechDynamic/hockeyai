//
//  AIPerformanceAnalytics.swift
//  SnapHockey
//
//  Analytics tracking for AI performance and reliability monitoring
//

import Foundation

/// Centralized analytics for monitoring AI feature performance and reliability
enum AIPerformanceAnalytics {

    /// Features that use AI analysis
    enum AIFeature: String {
        case styCheck = "sty_check"
        case shotRater = "shot_rater"
        case aiCoach = "ai_coach"
        case stickAnalyzer = "stick_analyzer"
        case skillCheck = "skill_check"
    }

    /// AI error types for categorization
    enum AIErrorType: String {
        case timeout = "timeout"
        case apiError = "api_error"
        case parsingError = "parsing_error"
        case invalidResponse = "invalid_response"
        case networkError = "network_error"
        case rateLimitError = "rate_limit_error"
        case authError = "auth_error"
        case unknown = "unknown"
    }

    /// Response quality issue types
    enum QualityIssue: String {
        case missingComment = "missing_comment"
        case invalidScore = "invalid_score"
        case missingPremiumData = "missing_premium_data"
        case malformedJSON = "malformed_json"
        case incompleteData = "incomplete_data"
    }

    // MARK: - Core AI Events

    // MARK: - Helper Methods for Network Detection

    /// Get current network type for analytics
    private static func getNetworkType() -> String {
        Connectivity.shared.start()
        if Connectivity.shared.isCellular {
            return "cellular"
        } else if Connectivity.shared.hasFirstUpdate {
            return "wifi"
        } else {
            return "unknown"
        }
    }

    /// Track when AI analysis starts
    /// - Parameters:
    ///   - feature: Which AI feature is being used
    ///   - provider: AI provider (openai, gemini)
    ///   - imageSizeKB: Size of image being analyzed
    ///   - context: User context
    static func trackAnalysisStarted(
        feature: AIFeature,
        provider: String,
        imageSizeKB: Int,
        context: String? = nil
    ) {
        var properties: [String: Any] = [
            "feature": feature.rawValue,
            "provider": provider,
            "image_size_kb": imageSizeKB,
            "network_type": getNetworkType()
        ]

        if let context = context {
            properties["context"] = context
        }

        AnalyticsManager.shared.track(
            eventName: "ai_analysis_started",
            properties: properties
        )

        #if DEBUG
        print("📊 [AI Analytics] Analysis started - feature: \(feature.rawValue), provider: \(provider), size: \(imageSizeKB)KB, network: \(getNetworkType())")
        #endif
    }

    /// Track successful AI analysis completion
    /// - Parameters:
    ///   - feature: Which AI feature completed
    ///   - provider: AI provider used
    ///   - durationSeconds: How long analysis took
    ///   - tokensUsed: Total tokens consumed
    ///   - responseValid: Whether response was valid
    ///   - containsPerson: Whether person was detected (if applicable)
    ///   - scoreGenerated: Score value (if applicable)
    ///   - hasPremiumData: Whether premium data was included
    ///   - imageSizeKB: Size of image analyzed
    static func trackAnalysisCompleted(
        feature: AIFeature,
        provider: String,
        durationSeconds: Double,
        tokensUsed: Int? = nil,
        responseValid: Bool,
        containsPerson: Bool? = nil,
        scoreGenerated: Int? = nil,
        hasPremiumData: Bool? = nil,
        imageSizeKB: Int
    ) {
        var properties: [String: Any] = [
            "feature": feature.rawValue,
            "provider": provider,
            "duration_seconds": durationSeconds,
            "response_valid": responseValid,
            "image_size_kb": imageSizeKB,
            "network_type": getNetworkType()
        ]

        if let tokens = tokensUsed {
            properties["tokens_used"] = tokens
        }

        if let person = containsPerson {
            properties["contains_person"] = person
        }

        if let score = scoreGenerated {
            properties["score_generated"] = score
        }

        if let premium = hasPremiumData {
            properties["has_premium_data"] = premium
        }

        AnalyticsManager.shared.track(
            eventName: "ai_analysis_completed",
            properties: properties
        )

        #if DEBUG
        print("📊 [AI Analytics] Analysis completed - duration: \(String(format: "%.2f", durationSeconds))s, valid: \(responseValid), network: \(getNetworkType())")
        #endif
    }

    /// Track AI analysis failure
    /// - Parameters:
    ///   - feature: Which AI feature failed
    ///   - provider: AI provider used
    ///   - errorType: Category of error
    ///   - errorMessage: Detailed error message
    ///   - durationBeforeFailure: How long before failure
    ///   - retryCount: Number of retries attempted
    ///   - imageSizeKB: Size of image
    static func trackAnalysisFailed(
        feature: AIFeature,
        provider: String,
        errorType: AIErrorType,
        errorMessage: String,
        durationBeforeFailure: Double,
        retryCount: Int = 0,
        imageSizeKB: Int
    ) {
        let properties: [String: Any] = [
            "feature": feature.rawValue,
            "provider": provider,
            "error_type": errorType.rawValue,
            "error_message": errorMessage,
            "duration_before_failure": durationBeforeFailure,
            "retry_count": retryCount,
            "image_size_kb": imageSizeKB,
            "network_type": getNetworkType()
        ]

        AnalyticsManager.shared.track(
            eventName: "ai_analysis_failed",
            properties: properties
        )

        #if DEBUG
        print("📊 [AI Analytics] ❌ Analysis failed - type: \(errorType.rawValue), message: \(errorMessage), network: \(getNetworkType())")
        #endif
    }

    /// Track response quality issues
    /// - Parameters:
    ///   - feature: Which AI feature had quality issue
    ///   - issueType: Type of quality problem
    ///   - score: Score if available
    ///   - hasComment: Whether comment exists
    ///   - hasPremiumData: Whether premium data exists
    static func trackQualityIssue(
        feature: AIFeature,
        issueType: QualityIssue,
        score: Int? = nil,
        hasComment: Bool,
        hasPremiumData: Bool
    ) {
        var properties: [String: Any] = [
            "feature": feature.rawValue,
            "issue_type": issueType.rawValue,
            "has_comment": hasComment,
            "has_premium_data": hasPremiumData
        ]

        if let score = score {
            properties["score"] = score
        }

        AnalyticsManager.shared.track(
            eventName: "ai_response_quality_issue",
            properties: properties
        )

        #if DEBUG
        print("📊 [AI Analytics] ⚠️ Quality issue - type: \(issueType.rawValue)")
        #endif
    }

    /// Track validation failures (no person, poor quality, etc.)
    /// - Parameters:
    ///   - feature: Which AI feature
    ///   - validationType: Why validation failed
    ///   - duration: How long validation took
    static func trackValidationFailed(
        feature: AIFeature,
        validationType: String,
        duration: Double
    ) {
        let properties: [String: Any] = [
            "feature": feature.rawValue,
            "validation_type": validationType,
            "duration": duration
        ]

        AnalyticsManager.shared.track(
            eventName: "ai_validation_failed",
            properties: properties
        )

        #if DEBUG
        print("📊 [AI Analytics] ⚠️ Validation failed - type: \(validationType)")
        #endif
    }

    // MARK: - Performance Benchmarks

    /// Track performance metrics for monitoring
    /// - Parameters:
    ///   - feature: Which AI feature
    ///   - provider: AI provider
    ///   - metrics: Dictionary of performance metrics
    static func trackPerformanceMetrics(
        feature: AIFeature,
        provider: String,
        metrics: [String: Any]
    ) {
        var properties: [String: Any] = [
            "feature": feature.rawValue,
            "provider": provider
        ]

        properties.merge(metrics) { (_, new) in new }

        AnalyticsManager.shared.track(
            eventName: "ai_performance_benchmark",
            properties: properties
        )

        #if DEBUG
        print("📊 [AI Analytics] Performance benchmark recorded")
        #endif
    }

    // MARK: - Helper Methods

    /// Determine error type from error object
    static func categorizeError(_ error: Error) -> AIErrorType {
        let errorString = error.localizedDescription.lowercased()

        if errorString.contains("timeout") || errorString.contains("timed out") {
            return .timeout
        } else if errorString.contains("parse") || errorString.contains("decode") {
            return .parsingError
        } else if errorString.contains("network") || errorString.contains("connection") {
            return .networkError
        } else if errorString.contains("rate limit") || errorString.contains("429") {
            return .rateLimitError
        } else if errorString.contains("auth") || errorString.contains("401") || errorString.contains("403") {
            return .authError
        } else if errorString.contains("500") || errorString.contains("502") || errorString.contains("503") {
            return .apiError
        } else {
            return .unknown
        }
    }
}
