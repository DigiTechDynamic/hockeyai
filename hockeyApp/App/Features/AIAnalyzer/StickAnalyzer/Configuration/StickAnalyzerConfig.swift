import Foundation

// MARK: - Stick Analyzer Configuration
/// Centralized configuration for Stick Analyzer Flow including prompts, stages, and settings
struct StickAnalyzerConfig {
    
    // MARK: - Flow Builder
    static func buildFlow() -> StickAnalyzerFlow {
        print("🏒 [StickAnalyzerConfig] Creating stick analyzer flow")
        
        var stages: [any AIFlowStage] = []

        // Phone setup tutorial is now shown just-in-time when the user taps "Record Video"

        // Stage 1: Player Profile
        stages.append(createPlayerProfileStage())

        // Stage 2: Shot Video Capture (simplified to one stage)
        stages.append(createShotVideoStage())

        // Stages 3-5: Shooting Preferences (3 separate stages like AI Coach)
        stages.append(createShootingPriorityStage())     // Question 1
        stages.append(createPrimaryShotStage())          // Question 2
        stages.append(createShootingZoneStage())         // Question 3

        // Stage 6: Validation
        stages.append(createValidationStage())

        // Stage 7: Analysis Processing
        stages.append(createProcessingStage())

        // Stage 8: Results
        stages.append(createResultsStage())
        
        print("📱 [StickAnalyzerConfig] Created flow with \(stages.count) stages")
        return StickAnalyzerFlow(stages: stages)
    }
    
    // MARK: - Stage Configurations
    
    private static func createPlayerProfileStage() -> PlayerProfileStage {
        return PlayerProfileStage(
            id: "player-profile",
            title: "Player Profile",
            subtitle: "",
            isRequired: true,
            canSkip: false
        )
    }

    private static func createTutorialStage() -> CustomStage {
        return CustomStage(
            id: "phone-setup-tutorial",
            title: "",
            subtitle: ""
        )
    }

    private static func createShotVideoStage() -> MediaCaptureStage {
        return MediaCaptureStage(
            id: "shot-video-capture",
            title: "Record Shot",
            subtitle: "",
            isRequired: true,
            canSkip: false,
            mediaTypes: [.video],
            maxItems: 1,
            minItems: 1,
            instructions: "Record a video of your best shot from any angle",
            maxVideos: 1
        )
    }
    
    private static func createShootingPriorityStage() -> SelectionStage {
        return SelectionStage(
            id: "shooting-priority",
            title: "Preferences",
            subtitle: "",
            isRequired: true,
            canSkip: false,
            canGoBack: true,
            options: [
                SelectionStage.SelectionOption(
                    id: "power",
                    title: "Power",
                    subtitle: "Maximum shot velocity and distance",
                    icon: "bolt.fill"
                ),
                SelectionStage.SelectionOption(
                    id: "accuracy",
                    title: "Accuracy",
                    subtitle: "Precise shot placement and control",
                    icon: "target"
                ),
                SelectionStage.SelectionOption(
                    id: "balance",
                    title: "Balance",
                    subtitle: "Equal emphasis on power and accuracy",
                    icon: "scalemass"
                )
            ],
            multiSelect: false
        )
    }
    
    private static func createPrimaryShotStage() -> SelectionStage {
        return SelectionStage(
            id: "primary-shot",
            title: "Preferences",
            subtitle: "",
            isRequired: true,
            canSkip: false,
            canGoBack: true,
            options: [
                SelectionStage.SelectionOption(
                    id: "wrist",
                    title: "Wrist Shot",
                    subtitle: "",
                    icon: "hockey.puck"
                ),
                SelectionStage.SelectionOption(
                    id: "slap",
                    title: "Slap Shot",
                    subtitle: "",
                    icon: "bolt"
                ),
                SelectionStage.SelectionOption(
                    id: "snap",
                    title: "Snap Shot",
                    subtitle: "",
                    icon: "sparkles"
                ),
                SelectionStage.SelectionOption(
                    id: "backhand",
                    title: "Backhand",
                    subtitle: "",
                    icon: "arrow.uturn.left"
                )
            ],
            multiSelect: false
        )
    }
    
    private static func createShootingZoneStage() -> SelectionStage {
        return SelectionStage(
            id: "shooting-zone",
            title: "Preferences",
            subtitle: "",
            isRequired: true,
            canSkip: false,
            canGoBack: true,
            options: [
                SelectionStage.SelectionOption(
                    id: "point",
                    title: "Point",
                    subtitle: "Blue line area",
                    icon: ""
                ),
                SelectionStage.SelectionOption(
                    id: "slot",
                    title: "Slot",
                    subtitle: "Between circles",
                    icon: ""
                ),
                SelectionStage.SelectionOption(
                    id: "close",
                    title: "Close Range",
                    subtitle: "Near the crease",
                    icon: ""
                ),
                SelectionStage.SelectionOption(
                    id: "varies",
                    title: "Varies",
                    subtitle: "All zones",
                    icon: ""
                )
            ],
            multiSelect: false
        )
    }
    
    private static func createValidationStage() -> ProcessingStage {
        return ProcessingStage(
            id: "stick-validation",
            title: "Validating Shot",
            subtitle: "",
            processingMessage: "Checking your hockey shot video..."
        )
    }

    private static func createProcessingStage() -> ProcessingStage {
        return ProcessingStage(
            id: "stick-analysis-processing",
            title: "Analyzing Stick",
            subtitle: "",
            processingMessage: "Our AI is analyzing your shooting technique and player profile..."
        )
    }
    
    private static func createResultsStage() -> ResultsStage {
        return ResultsStage(
            id: "stick-analysis-results",
            title: "Perfect Stick",
            subtitle: ""
        )
    }
    
    // MARK: - AI Prompt Generation
    
    static func createAnalysisPrompt(
        playerProfile: PlayerProfile,
        questionnaire: ShootingQuestionnaire
    ) -> String {
        // Build comprehensive analysis prompt with all player data
        let height = playerProfile.height ?? 70
        let weight = playerProfile.weight ?? 150
        let positionStr = playerProfile.position?.rawValue ?? "Forward"
        let handednessStr = playerProfile.handedness?.rawValue ?? "Right"
        let playStyleStr = playerProfile.playStyle?.rawValue ?? "Two-Way"

        // Format questionnaire preferences
        let shootingPriority = questionnaire.priorityFocus.rawValue
        let primaryShot = questionnaire.primaryShot.rawValue
        let shootingZone = questionnaire.shootingZone.rawValue

        return """
        Analyze this hockey shot and recommend ideal stick specifications.

        PLAYER PROFILE:
        - Height: \(Int(height))"
        - Weight: \(Int(weight)) lbs
        - Position: \(positionStr)
        - Shoots: \(handednessStr)
        - Play Style: \(playStyleStr)

        SHOOTING PREFERENCES:
        - Priority: \(shootingPriority) (most important factor in shots)
        - Primary Shot Type: \(primaryShot) (most frequently used)
        - Typical Shooting Zone: \(shootingZone)

        ANALYSIS FOCUS:
        1. Evaluate stick flex usage and loading in the video
        2. Assess hand positioning, grip strength, and control
        3. Analyze follow-through mechanics and energy transfer
        4. Consider player's shooting priority (\(shootingPriority)) when recommending flex
        5. Factor in primary shot type (\(primaryShot)) for kick point recommendation
        6. Account for shooting zone (\(shootingZone)) for stick length and lie

        RECOMMENDATIONS SHOULD CONSIDER:
        - For "\(shootingPriority)" priority: adjust flex and kick point accordingly
        - For "\(primaryShot)" as primary shot: optimize stick characteristics for this shot type
        - For "\(shootingZone)" zone: consider appropriate stick length and lie angle
        - Provide recommendations based solely on player profile and shooting technique observed in video
        """
    }
}
