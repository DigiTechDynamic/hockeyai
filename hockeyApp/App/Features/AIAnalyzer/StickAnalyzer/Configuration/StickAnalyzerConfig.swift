import Foundation

// MARK: - Stick Analyzer Configuration
/// Centralized configuration for Stick Analyzer Flow including prompts, stages, and settings
struct StickAnalyzerConfig {

    // MARK: - Flow Builder
    static func buildFlow() -> StickAnalyzerFlow {
        print("🏒 [StickAnalyzerConfig] Creating stick analyzer flow")

        var stages: [any AIFlowStage] = []

        // Stage 1: Player Profile
        stages.append(createPlayerProfileStage())

        // Stage 2: Body Scan (replaces video capture - lower friction)
        stages.append(createBodyScanStage())

        // Stages 3-5: Shooting Preferences (3 separate stages like AI Coach)
        stages.append(createShootingPriorityStage())     // Question 1
        stages.append(createPrimaryShotStage())          // Question 2
        stages.append(createShootingZoneStage())         // Question 3

        // Stage 6: Analysis Processing (no validation needed for body scan)
        stages.append(createProcessingStage())

        // Stage 7: Results
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

    private static func createBodyScanStage() -> CustomStage {
        return CustomStage(
            id: "body-scan",
            title: "Body Scan",
            subtitle: "",
            isRequired: false,  // Not required - user can skip
            canSkip: true,      // Allow skip
            canGoBack: true,
            showsHeader: true,  // Show the flow header with title and X button
            showsProgress: true // Show progress bar
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

    private static func createProcessingStage() -> ProcessingStage {
        return ProcessingStage(
            id: "stick-analysis-processing",
            title: "Analyzing",
            subtitle: "",
            processingMessage: "Our AI is analyzing your body proportions and preferences..."
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
        Analyze this player's full body photo and provide personalized hockey stick recommendations.

        PLAYER PROFILE:
        - Height: \(Int(height))" (use this as reference for proportions)
        - Weight: \(Int(weight)) lbs
        - Position: \(positionStr)
        - Shoots: \(handednessStr)
        - Play Style: \(playStyleStr)

        SHOOTING PREFERENCES:
        - Priority: \(shootingPriority) (most important factor in shots)
        - Primary Shot Type: \(primaryShot) (most frequently used)
        - Typical Shooting Zone: \(shootingZone)

        BODY ANALYSIS FOCUS:
        1. Estimate arm span and proportions from the body photo
        2. Assess body type (lean, athletic, stocky) which affects flex preference
        3. Note shoulder width for grip positioning guidance
        4. Consider torso-to-leg ratio for stance and lie angle
        5. Factor in overall build for power potential

        RECOMMENDATIONS SHOULD CONSIDER:
        - Body proportions visible in photo (arm span affects ideal stick length)
        - Weight and build type for flex recommendations
        - For "\(shootingPriority)" priority: adjust flex and kick point accordingly
        - For "\(primaryShot)" as primary shot: optimize stick characteristics for this shot type
        - For "\(shootingZone)" zone: consider appropriate stick length and lie angle
        - Provide recommendations based on player profile and body proportions observed in photo
        """
    }
}
