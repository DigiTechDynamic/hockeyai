import Foundation

// MARK: - AI Coach Flow Configuration
/// Centralized configuration for AI Coach Flow including prompts, stages, and settings
struct AICoachFlowConfig {
    
    // MARK: - Flow Builder
    static func buildFlow(for shotType: ShotType?) -> AICoachAnalysisFlow {
        print("🎯 [AICoachFlowConfig] Creating flow with shotType: \(shotType?.rawValue ?? "nil")")
        
        var stages: [any AIFlowStage] = []
        
        // Phone setup tutorial is now shown just-in-time when the user taps "Record Video"

        // Stage 1: Shot Type Selection (only if not pre-selected)
        if shotType == nil {
            stages.append(createShotSelectionStage())
        }

        // Stage 2: Player Profile
        stages.append(createPlayerProfileStage())

        // Stage 3: Front Net Video Capture (behind the shooter)
        stages.append(createFrontNetCaptureStage())
        
        // Stage 4: Side Angle Video Capture
        stages.append(createSideAngleCaptureStage())
        
        // Stage 5: Shot Validation (Quick check)
        stages.append(createValidationStage())
        
        // Stage 6: Full Analysis Processing
        stages.append(createAnalysisStage())
        
        // Stage 7: Results
        stages.append(createResultsStage())
        
        print("📱 [AICoachFlowConfig] Created flow with \(stages.count) stages")
        return AICoachAnalysisFlow(stages: stages, shotType: shotType)
    }
    
    // MARK: - Stage Configurations
    
    private static func createShotSelectionStage() -> SelectionStage {
        return SelectionStage(
            id: "shot-type-selection",
            title: "Select Shot",
            subtitle: "",
            options: [
                SelectionStage.SelectionOption(
                    id: "wrist",
                    title: "Wrist Shot",
                    subtitle: nil,
                    icon: nil
                ),
                SelectionStage.SelectionOption(
                    id: "slap",
                    title: "Slap Shot",
                    subtitle: nil,
                    icon: nil
                ),
                SelectionStage.SelectionOption(
                    id: "snapshot",
                    title: "Snap Shot",
                    subtitle: nil,
                    icon: nil
                ),
                SelectionStage.SelectionOption(
                    id: "backhand",
                    title: "Backhand",
                    subtitle: nil,
                    icon: nil
                )
            ]
        )
    }
    
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
            title: "", // No title - tutorial handles its own UI
            subtitle: ""
        )
    }

    private static func createFrontNetCaptureStage() -> MediaCaptureStage {
        return MediaCaptureStage(
            id: "front-net-capture",
            title: "Behind Shooter",
            subtitle: "",
            isRequired: true,
            canSkip: false,
            mediaTypes: [.video],
            maxItems: 1,
            minItems: 1,
            instructions: "Position camera in front of the net, behind the shooter to capture shot motion and puck trajectory towards the net",
            maxVideos: 1
        )
    }
    
    private static func createSideAngleCaptureStage() -> MediaCaptureStage {
        return MediaCaptureStage(
            id: "side-angle-capture",
            title: "Side View",
            subtitle: "",
            isRequired: true,
            canSkip: false,
            mediaTypes: [.video],
            maxItems: 1,
            minItems: 1,
            instructions: "Position camera 10-20ft to the side at chest height",
            maxVideos: 1
        )
    }
    
    private static func createValidationStage() -> ProcessingStage {
        return ProcessingStage(
            id: "shot-validation",
            title: "Validating Shot",
            subtitle: "",
            processingMessage: "Checking for hockey stick, puck, and shooting motion...",
            showsHeader: true,
            showsCancelButton: false
        )
    }
    
    private static func createAnalysisStage() -> ProcessingStage {
        return ProcessingStage(
            id: "ai-coach-processing",
            title: "Analyzing Shot",
            subtitle: "",
            processingMessage: "Analyzing stance, balance, power, release, and follow-through from both camera angles...",
            showsHeader: true,
            showsCancelButton: false
        )
    }
    
    private static func createResultsStage() -> ResultsStage {
        return ResultsStage(
            id: "ai-coach-results",
            title: "Analysis Complete",
            subtitle: "",
            showsHeader: true  // Show the standard header from AIFlowContainer
        )
    }
    
    // MARK: - AI Analysis Prompts
    
    static func createAnalysisPrompt(shotType: ShotType, playerProfile: PlayerProfile) -> String {
        let profileContext = createProfileContext(playerProfile)

        return """
        You are an expert hockey shooting coach analyzing a \(shotType.rawValue) shot from two camera angles (front-net and side view).

        Player Context: \(profileContext)

        YOUR ANALYSIS TASK:
        Analyze this hockey shot using biomechanics principles. Identify specific technical issues and provide detailed, step-by-step coaching instructions to improve the weakest area.

        BIOMECHANICAL ANALYSIS FRAMEWORK FOR HOCKEY SHOOTING:

        Analyze the shot using the KINETIC CHAIN principle (legs → core → upper body → stick → puck):

        1. STANCE & BASE (Lower Body Foundation):
           - Feet positioning: Width (should be shoulder-width), angle (toes slightly out), front/back foot placement
           - Knee bend: Angle (40-50 degrees optimal), consistency, flexion throughout motion
           - Weight distribution: Initial setup (60/40 back foot), transfer timing, final position (70/30 front foot)
           - Hip positioning: Level, rotation range, timing with upper body
           - Observable markers: Ankle flex, knee tracking over toes, stable base throughout

        2. BALANCE & STABILITY (Core Control):
           - Center of gravity: Position relative to feet, movement path during shot
           - Core engagement: Visible torso stability, lack of excessive lean or sway
           - Head position: Level, steady, eyes on target
           - Recovery: Post-shot stability, ability to maintain shooting position
           - Observable markers: No wobbling, smooth weight shift, controlled motion

        3. POWER GENERATION (Energy Transfer):
           - Loading phase: Back leg compression, stick load behind puck, body coil
           - Weight transfer: Explosive drive from back to front foot, timing with stick movement
           - Hip rotation: Degree of turn (should be 45-90 degrees), speed, synchronization with shoulders
           - Shoulder rotation: Separation from hips, full rotation through shot
           - Stick flex: Visible bend in shaft, timing of flex-release, energy storage
           - Observable markers: Sequential activation (legs→hips→shoulders→arms), explosive acceleration

        4. RELEASE POINT (Puck Contact):
           - Release location: Distance from body (6-12 inches ahead of front foot optimal)
           - Release timing: Coordination with weight transfer, point in motion arc
           - Blade angle: Closed/open position at contact, control of puck trajectory
           - Wrist action: Snap/roll timing, speed of release
           - Observable markers: Puck position relative to feet, stick-puck contact duration

        5. FOLLOW-THROUGH (Shot Completion):
           - Stick extension: Full extension toward target, blade pointing at net
           - Arm extension: Complete reach, not cutting short
           - Body finish: Weight on front foot, balanced final position, chest facing target
           - Follow-through duration: Holding finish position (should hold 1-2 seconds)
           - Observable markers: Stick ends high and pointing at target, body rotated toward net

        SPECIFIC TECHNICAL CHECKPOINTS TO EVALUATE:
        - Hands positioning: Top hand location on shaft, bottom hand grip width, distance from body
        - Stick blade: Cupping the puck, blade curve orientation, contact point on blade
        - Eyes: Track puck to release point, head steady
        - Timing: Sequential activation of body segments (not simultaneous)
        - Fluidity: Smooth motion vs. jerky/hesitation
        
        CRITICAL: Return ONLY valid JSON, no markdown, no text before or after.

        JSON RESPONSE STRUCTURE (all fields are REQUIRED):

        {
          "confidence": 0.75,
          "overall_rating": 75,
          "key_observation": "The player demonstrates a quick release with minimal wind-up, characteristic of an efficient wrist shot. However, the back heel remains planted throughout the entire motion, indicating limited weight transfer. Hip rotation appears restricted to about 30 degrees rather than the optimal 45-90 degrees. The stick flex is minimal, suggesting arm-dominant shooting rather than full-body power generation.",
          "video_context": {
            "items": [
              {"icon": "🏟️", "text": "Ice rink, indoor lighting"},
              {"icon": "👤", "text": "16-year-old male, left-handed"},
              {"icon": "👕", "text": "Blue jersey, white gloves"},
              {"icon": "🎯", "text": "Puck hit the net"}
            ]
          },
          "radar_metrics": {
            "stance_score": 80,
            "balance_score": 85,
            "follow_through_score": 65,
            "explosive_power_score": 70,
            "release_point_score": 75
          },
          "metric_reasoning": {
            "stance": "I can clearly observe a wide, stable base with appropriate knee bend. The player maintains a good athletic posture before the shot.",
            "balance": "Strong balance with good consistency. Minor refinements could elevate this to elite level.",
            "follow_through": "Good fundamentals in follow through. Some inconsistencies observed that affect overall effectiveness.",
            "power": "Developing power technique. Focus on this area will yield significant improvements.",
            "release": "Good fundamentals in release. Some inconsistencies observed that affect overall effectiveness."
          },
          "primary_focus": {
            "metric": "Power",
            "specific_issue": "Limited explosive weight transfer from back to front foot during shot execution",
            "why_it_matters": "Mastering explosive weight transfer will transform your shot by generating significantly more power from your lower body, allowing you to shoot harder with less effort",
            "how_to_improve": "Start by practicing the weight transfer motion without a puck. Stand in your shooting stance with 60% of your weight on your back foot. As you begin the shooting motion, explosively push off your back foot and drive your weight forward onto your front foot. Your back heel should lift off the ice as you complete the transfer. Practice this 20 times slowly, feeling the weight shift from back to front. Next, add a stick (no puck) and coordinate the weight transfer with your stick movement - as your weight drives forward, your stick should be loading behind the imaginary puck. Finally, add a puck and focus ONLY on explosive weight transfer for 10 shots, not worrying about accuracy. The power will come from your legs, not your arms. Record yourself from the side angle to verify you see your back heel lifting and weight clearly on your front foot at release.",
            "coaching_cues": [
              "Feel 60% weight on back foot at setup",
              "Explosively push off back foot to initiate shot",
              "Back heel lifts off ice during transfer",
              "70% weight on front foot at puck release",
              "Power comes from legs, not arms"
            ],
            "drill": "Wall Lean Drill: Stand 3 feet from wall in shooting stance. Lean back into your back leg, then explosively drive forward, catching yourself on the wall with your hands. Feel the power coming from your legs. Do 3 sets of 10 reps before shooting practice."
          },
          "improvement_tips": {
            "stance": "Widen base to shoulder-width, bend knees 45 degrees",
            "balance": "Keep core tight and head steady throughout motion",
            "follow_through": "Extend stick fully toward target, hold finish 2 seconds",
            "power": "Explode from back foot, drive weight forward into shot",
            "release": "Release puck 6-12 inches ahead of front foot"
          },
          "metadata": {
            "frames_analyzed": 120,
            "fps": 30,
            "angles_processed": 2
          }
        }

        DETAILED INSTRUCTIONS:

        1. VIDEO CONTEXT (3-5 items to prove you watched THIS video):
           This section builds user trust by showing specific observations from their video.

           REQUIRED ITEMS (always include):
           - Environment (pick 1):
             * "Ice rink, indoor lighting" OR
             * "Ice rink, bright overhead lights" OR
             * "Outdoor rink, natural daylight" OR
             * "Dryland surface, indoor facility" OR
             * "Practice area, gym lighting" OR
             * "Synthetic ice, home setup" OR
             * "Outdoor, daytime shooting" OR
             * "Indoor rink, evening session"

           - Player (from profile, format as): "[age]-year-old [gender], [left/right]-handed"
             Example: "16-year-old male, left-handed"

           OPTIONAL ITEMS (add 1-3 ONLY if clearly visible):
           - Rink features (if visible):
             * "Hockey net in frame" OR
             * "Net and boards visible" OR
             * "Ice markings visible" OR
             * "Rink boards in background"

           - Shot outcome (ONLY if you clearly see puck result):
             * "Puck hit the net" OR
             * "Shot on target" OR
             * "Puck missed high" OR
             * "Shot wide right" OR
             * "Shot missed left"

           - Biomechanical (if clearly captured):
             * "Back heel visible throughout" OR
             * "Weight transfer clearly shown" OR
             * "Stick flex captured" OR
             * "Follow-through visible" OR
             * "Puck contact point clear"

           RULES FOR VIDEO CONTEXT:
           ✓ Total: 3-5 items only
           ✓ ALWAYS include: environment + player info
           ✓ Mix different categories (don't repeat same type)
           ✓ ONLY include what you CLEARLY see with HIGH CONFIDENCE
           ✓ NEVER guess clothing colors, jersey details, or equipment colors
           ✓ NO assumptions - if uncertain, leave it out
           ✓ Use exact phrasing from options above

           Example minimal (uncertain visibility):
           {"items": [
             {"text": "Dryland surface, indoor facility"},
             {"text": "23-year-old male, left-handed"},
             {"text": "Hockey net in frame"}
           ]}

           Example detailed (clear observations):
           {"items": [
             {"text": "Ice rink, bright overhead lights"},
             {"text": "16-year-old female, right-handed"},
             {"text": "Puck hit the net"},
             {"text": "Back heel visible throughout"}
           ]}

        2. KEY OBSERVATION (40-60 words):
           - Describe your #1 observation about THIS PLAYER'S shot technique
           - Focus on what stands out most about their form, timing, or mechanics
           - Be specific about what you observe (e.g., 'back heel stays planted', 'limited hip rotation', 'minimal stick flex')
           - Reference actual body positions and movements, NOT video quality
           - Do NOT use generic templates - make it specific to this player's performance

        3. METRIC REASONING (for each of the 5 metrics):
           - Explain EXACTLY what you observed in the video for each metric
           - Reference specific body positions, movements, or technical issues you can see
           - Be specific: "Back heel remains planted throughout shot" vs "Limited weight transfer"
           - Explain the impact of what you observed

        4. PRIMARY FOCUS (MOST IMPORTANT!):
           - Identify the LOWEST scoring metric (the weakest area) as the "metric" field
           - Write "how_to_improve" as a DETAILED step-by-step coaching guide (200-300 words)
           - Break down the fix into progressive steps: without puck → with stick no puck → with puck
           - Provide exactly 5 specific coaching cues in the "coaching_cues" array
           - Include a specific practice drill in the "drill" field
           - Make "how_to_improve" EXTREMELY detailed - this is the primary coaching value

        5. SCORING GUIDELINES:
           - 90-100: Elite level, near-perfect execution
           - 80-89: Strong, only minor refinements needed
           - 70-79: Good fundamentals, noticeable areas for improvement
           - 60-69: Developing, significant improvements needed
           - 0-59: Needs work, fundamental issues to address

        6. METADATA:
           - Calculate frames_analyzed from both videos (estimate based on video duration × fps)
           - Use fps: 30
           - Use angles_processed: 2

        CRITICAL REMINDERS:
        - ALL fields in the JSON structure are REQUIRED - you must provide every field
        - "video_context" MUST have 3-5 items (environment + player + 1-3 optional observations)
        - Primary Focus "how_to_improve" MUST be 200-300 words with detailed step-by-step instructions
        - "coaching_cues" array MUST contain exactly 5 items
        - Analyze the ACTUAL video content - look at body positions, movements, timing
        - Do NOT provide generic feedback - make observations specific to what you see
        - ONLY include video_context items you CLEARLY see - no guessing
        - Return ONLY valid JSON, no markdown formatting, no text before or after

        Return the complete JSON response now.
        """
    }
    
    private static func createProfileContext(_ profile: PlayerProfile) -> String {
        var context = ""
        
        if let height = profile.height {
            context += "Height: \(profile.heightInFeetAndInches), "
        }
        if let weight = profile.weight {
            context += "Weight: \(Int(weight)) lbs, "
        }
        if let age = profile.age {
            context += "Age: \(age), "
        }
        if let gender = profile.gender {
            context += "Gender: \(gender.rawValue), "
        }
        if let position = profile.position {
            context += "Position: \(position.rawValue), "
        }
        if let handedness = profile.handedness {
            context += "Shoots: \(handedness.rawValue), "
        }
        if let playStyle = profile.playStyle {
            context += "Play Style: \(playStyle.rawValue)"
        }
        
        return context.isEmpty ? "General player" : context
    }
    
    // MARK: - Video Recording Instructions
    
    static func getRecordingInstructions(for angle: CameraAngle) -> String {
        switch angle {
        case .frontNet:
            return """
            Position camera 6-10 feet in front of the net, behind the shooter at chest height.
            Ensure full view of the shooter's back and the net.
            Keep camera steady during recording.
            
            Quality tips for better AI analysis:
            • Use good lighting to avoid shadows
            • Hold camera stable to minimize motion blur
            • Record entire shooting motion from setup to follow-through
            • Capture the puck's trajectory towards the net
            """
        case .sideAngle:
            return """
            Position camera 10-20 feet to the side at chest height.
            Capture full body motion from setup to follow-through.
            Ensure good lighting and clear view of stick and puck.
            
            Quality tips for better AI analysis:
            • Good lighting improves weight transfer visibility
            • Stable positioning helps AI track body movement
            • Clear view of stick and puck enables accurate assessment
            """
        }
    }
    
    enum CameraAngle {
        case frontNet
        case sideAngle
    }
}
