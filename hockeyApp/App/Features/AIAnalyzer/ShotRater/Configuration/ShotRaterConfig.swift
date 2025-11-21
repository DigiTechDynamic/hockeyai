import Foundation

// MARK: - Shot Configuration Protocol
protocol ShotConfiguration {
    static var shotType: ShotType { get }
    
    // MARK: - Media Stage Configuration
    static var exampleVideo: String { get }
    static var overlayTitle: String { get }
    static var instructions: String { get }
    
    // MARK: - Recording Tips
    static var recordingTips: [String] { get }
    
    // MARK: - Trim Duration
    static var trimDurationMin: Double { get }
    static var trimDurationMax: Double { get }
    
    // MARK: - Processing Stage Configuration
    static var processingTitle: String { get }
    static var processingSubtitle: String { get }
    static var processingMessage: String { get }
    
    // MARK: - Results Stage Configuration
    static var resultsTitle: String { get }
    static var resultsSubtitle: String { get }
    
    // MARK: - AI Analysis Prompt
    static var analysisPrompt: String { get }
}

// MARK: - Shot Analysis Generation Configuration
/// Configuration for AI generation specific to shot analysis
struct ShotAnalysisGenerationConfig {
    
    /// Create the generation configuration for shot analysis
    /// NOTE: Schema now uses AnalyzerResultsContract for consistent approach
    /// - Parameters:
    ///   - temperature: Controls randomness (0.0 to 1.0), default 0.1 for consistent analysis
    ///   - maxOutputTokens: Maximum tokens to generate, default 4096
    /// - Returns: Configuration dictionary for AI generation
    static func createConfig(
        temperature: Double = 0.1,
        maxOutputTokens: Int = 4096
    ) -> [String: Any] {
        return [
            "response_mime_type": "application/json",
            "temperature": temperature,  // Very low for consistent analysis
            "topK": 10,                 // Focused token selection for sports analysis
            "topP": 0.8,                // High precision
            "maxOutputTokens": maxOutputTokens
            // Schema now comes from AnalyzerResultsContract.schemaDefinition
        ]
    }
    
    /// Create a simple configuration without schema for testing
    static func createSimpleConfig() -> [String: Any] {
        return [
            "temperature": 0.1,  // Very low for consistent analysis
            "topK": 10,  // More focused token selection
            "topP": 0.8,  // Higher precision
            "maxOutputTokens": 4096  // Increased for better responses
        ]
    }
}

// MARK: - Wrist Shot Configuration
struct WristShotConfig: ShotConfiguration {
    static let shotType: ShotType = .wristShot
    // MARK: - Media Stage Configuration
    static let exampleVideo = "WristShotFromBehind.MOV"
    static let overlayTitle = "Wrist Shot Technique"
    static let instructions = "Stand 10ft to the side at chest height. Capture full shooting motion including stick, puck, and net in frame."
    
    // MARK: - Recording Tips
    static let recordingTips: [String] = [
        "Stand 10ft to the side of shooter",
        "Capture wrist roll and release",
        "Show full stick motion"
    ]
    
    // MARK: - Trim Duration
    static let trimDurationMin: Double = 1.0
    static let trimDurationMax: Double = 3.0
    
    // MARK: - Processing Stage Configuration
    static let processingTitle = "Analyzing Your Shot"
    static let processingSubtitle = "AI is evaluating your technique"
    static let processingMessage = "Analyzing stick motion and puck release..."
    
    // MARK: - Results Stage Configuration
    static let resultsTitle = "Shot Analysis Complete"
    static let resultsSubtitle = "Your results are ready"
    
    // MARK: - AI Analysis Prompt
    static let analysisPrompt = """
        Analyze this WRIST SHOT hockey video with precise scoring criteria:
        
        SCORING GUIDELINES (be accurate and realistic):
        - 90-100: Professional/elite level technique
        - 75-89: Advanced player with excellent mechanics
        - 60-74: Good recreational player with solid fundamentals
        - 45-59: Developing player with room for improvement
        - 30-44: Beginner with basic technique
        - Below 30: Significant technique issues
        
        ANALYZE:
        1. Wrist roll mechanics and timing
        2. Weight transfer and body position
        3. Blade control and release
        
        PROVIDE:
        - Overall score (0-100) based on actual skill level observed
        - Technique score (0-100)
        - Power score (0-100)
        - SUMMARY: 2-4 sentences ONLY explaining the score. Do not include numbered tips here.
        - TIPS: Separately provide 3 specific, actionable improvements (numbered 1, 2, 3)
        
        Return structured JSON response only.
        """
}

// MARK: - Slap Shot Configuration
struct SlapShotConfig: ShotConfiguration {
    static let shotType: ShotType = .slapShot
    // MARK: - Media Stage Configuration
    static let exampleVideo = "SlapShotFromBehind.MOV"
    static let overlayTitle = "Slap Shot Technique"
    static let instructions = "Stand 10ft to the side at chest height. Capture full shooting motion including stick, puck, and net in frame."
    
    // MARK: - Recording Tips
    static let recordingTips: [String] = [
        "Stand 10ft to the side of shooter",
        "Capture full wind-up motion",
        "Show ice contact point clearly"
    ]
    
    // MARK: - Trim Duration
    static let trimDurationMin: Double = 2.0
    static let trimDurationMax: Double = 4.0
    
    // MARK: - Processing Stage Configuration
    static let processingTitle = "Analyzing Your Shot"
    static let processingSubtitle = "AI is evaluating your technique"
    static let processingMessage = "Analyzing wind-up and power transfer..."
    
    // MARK: - Results Stage Configuration
    static let resultsTitle = "Shot Analysis Complete"
    static let resultsSubtitle = "Your results are ready"
    
    // MARK: - AI Analysis Prompt
    static let analysisPrompt = """
        Analyze this SLAP SHOT hockey video with precise scoring criteria:
        
        SCORING GUIDELINES (be accurate and realistic):
        - 90-100: Professional/elite level technique
        - 75-89: Advanced player with excellent mechanics
        - 60-74: Good recreational player with solid fundamentals
        - 45-59: Developing player with room for improvement
        - 30-44: Beginner with basic technique
        - Below 30: Significant technique issues
        
        ANALYZE:
        1. Wind-up height and rotation
        2. Weight transfer and stick flex
        3. Ice contact before puck
        
        PROVIDE:
        - Overall score (0-100) based on actual skill level observed
        - Technique score (0-100)
        - Power score (0-100)
        - SUMMARY: 2-4 sentences ONLY explaining the score. Do not include numbered tips here.
        - TIPS: Separately provide 3 specific, actionable improvements (numbered 1, 2, 3)
        
        Return structured JSON response only.
        """
}

// MARK: - Snap Shot Configuration
struct SnapShotConfig: ShotConfiguration {
    static let shotType: ShotType = .snapShot
    // MARK: - Media Stage Configuration
    static let exampleVideo = "WristShotFromBehind.MOV"
    static let overlayTitle = "Snap Shot Technique"
    static let instructions = "Stand 10ft to the side at chest height. Capture full shooting motion including stick, puck, and net in frame."
    
    // MARK: - Recording Tips
    static let recordingTips: [String] = [
        "Stand 10ft to the side of shooter",
        "Show quick loading phase",
        "Capture explosive snap release"
    ]
    
    // MARK: - Trim Duration
    static let trimDurationMin: Double = 0.5
    static let trimDurationMax: Double = 2.0
    
    // MARK: - Processing Stage Configuration
    static let processingTitle = "Analyzing Your Shot"
    static let processingSubtitle = "AI is evaluating your technique"
    static let processingMessage = "Analyzing snap mechanics and release speed..."
    
    // MARK: - Results Stage Configuration
    static let resultsTitle = "Shot Analysis Complete"
    static let resultsSubtitle = "Your results are ready"
    
    // MARK: - AI Analysis Prompt
    static let analysisPrompt = """
        Analyze this SNAP SHOT hockey video with precise scoring criteria:
        
        SCORING GUIDELINES (be accurate and realistic):
        - 90-100: Professional/elite level technique
        - 75-89: Advanced player with excellent mechanics
        - 60-74: Good recreational player with solid fundamentals
        - 45-59: Developing player with room for improvement
        - 30-44: Beginner with basic technique
        - Below 30: Significant technique issues
        
        ANALYZE:
        1. Quick loading and release speed
        2. Stick flex and snap-back
        3. Minimal wind-up motion
        
        PROVIDE:
        - Overall score (0-100) based on actual skill level observed
        - Technique score (0-100)
        - Power score (0-100)
        - SUMMARY: 2-4 sentences ONLY explaining the score. Do not include numbered tips here.
        - TIPS: Separately provide 3 specific, actionable improvements (numbered 1, 2, 3)
        
        Return structured JSON response only.
        """
}

// MARK: - Backhand Shot Configuration
struct BackhandShotConfig: ShotConfiguration {
    static let shotType: ShotType = .backhandShot
    // MARK: - Media Stage Configuration
    static let exampleVideo = "WristShotFromBehind.MOV"
    static let overlayTitle = "Backhand Technique"
    static let instructions = "Stand 10ft to the side at chest height. Capture full shooting motion including stick, puck, and net in frame."
    
    // MARK: - Recording Tips
    static let recordingTips: [String] = [
        "Stand 10ft to the side of shooter",
        "Show blade cupping the puck",
        "Capture full lift and release"
    ]
    
    // MARK: - Trim Duration
    static let trimDurationMin: Double = 1.0
    static let trimDurationMax: Double = 3.0
    
    // MARK: - Processing Stage Configuration
    static let processingTitle = "Analyzing Your Shot"
    static let processingSubtitle = "AI is evaluating your technique"
    static let processingMessage = "Analyzing backhand mechanics and lift..."
    
    // MARK: - Results Stage Configuration
    static let resultsTitle = "Shot Analysis Complete"
    static let resultsSubtitle = "Your results are ready"
    
    // MARK: - AI Analysis Prompt
    static let analysisPrompt = """
        Analyze this BACKHAND SHOT hockey video with precise scoring criteria:
        
        SCORING GUIDELINES (be accurate and realistic):
        - 90-100: Professional/elite level technique
        - 75-89: Advanced player with excellent mechanics
        - 60-74: Good recreational player with solid fundamentals
        - 45-59: Developing player with room for improvement
        - 30-44: Beginner with basic technique
        - Below 30: Significant technique issues
        
        ANALYZE:
        1. Blade cupping and puck control
        2. Wrist rotation and lift motion
        3. Weight shift to outside leg
        
        PROVIDE:
        - Overall score (0-100) based on actual skill level observed
        - Technique score (0-100)
        - Power score (0-100)
        - SUMMARY: 2-4 sentences ONLY explaining the score. Do not include numbered tips here.
        - TIPS: Separately provide 3 specific, actionable improvements (numbered 1, 2, 3)
        
        Return structured JSON response only.
        """
}

// MARK: - Shot Configuration Factory
class ShotConfigurationFactory {
    private static let configurations: [ShotType: any ShotConfiguration.Type] = [
        .wristShot: WristShotConfig.self,
        .slapShot: SlapShotConfig.self,
        .backhandShot: BackhandShotConfig.self,
        .snapShot: SnapShotConfig.self
    ]
    
    static func configuration(for shotType: ShotType) -> any ShotConfiguration.Type {
        guard let config = configurations[shotType] else {
            // This should never happen now that all configurations are implemented
            print("❌ [ShotConfigurationFactory] Critical: No configuration for \(shotType)")
            return WristShotConfig.self
        }
        return config
    }
    
    // MARK: - Convenience Methods
    static func getExampleVideo(for shotType: ShotType) -> String {
        return configuration(for: shotType).exampleVideo
    }
    
    static func getOverlayTitle(for shotType: ShotType) -> String {
        return configuration(for: shotType).overlayTitle
    }
    
    static func getInstructions(for shotType: ShotType) -> String {
        return configuration(for: shotType).instructions
    }
    
    static func getRecordingTips(for shotType: ShotType) -> [String] {
        return configuration(for: shotType).recordingTips
    }
    
    static func getTrimDuration(for shotType: ShotType) -> (min: Double, max: Double) {
        let config = configuration(for: shotType)
        return (min: config.trimDurationMin, max: config.trimDurationMax)
    }
    
    static func getProcessingTexts(for shotType: ShotType) -> (title: String, subtitle: String, message: String) {
        let config = configuration(for: shotType)
        return (
            title: config.processingTitle,
            subtitle: config.processingSubtitle,
            message: config.processingMessage
        )
    }
    
    static func getResultsTexts(for shotType: ShotType) -> (title: String, subtitle: String) {
        let config = configuration(for: shotType)
        return (
            title: config.resultsTitle,
            subtitle: config.resultsSubtitle
        )
    }
    
    static func getAnalysisPrompt(for shotType: ShotType) -> String {
        return configuration(for: shotType).analysisPrompt
    }
}