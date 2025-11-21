import Foundation

// MARK: - AI Coach Simple Schema
/// Simplified schema with explicit top-level fields instead of flexible sections
/// This approach works with Gemini's schema limitations (no oneOf/anyOf/discriminator)
struct AICoachSimpleSchema: Codable {}

extension AICoachSimpleSchema: AISchemaConvertible {
    static var schemaDefinition: JSONSchema {
        // Define primary_focus object with REQUIRED coaching fields
        let primaryFocusObject = SchemaBuilder.nestedObject(
            properties: [
                "metric": SchemaBuilder.string(description: "Name of weakest metric (Power, Balance, Stance, Follow Through, or Release)"),
                "specific_issue": SchemaBuilder.string(description: "Specific technical issue observed in the video"),
                "why_it_matters": SchemaBuilder.string(description: "Why this area is important for shot quality"),
                "how_to_improve": SchemaBuilder.string(description: "DETAILED step-by-step coaching guide (200-300 words). Break down into progressive steps: (1) without puck, (2) with stick but no puck, (3) with puck. Include specific body position cues and movement sequences. This is the PRIMARY coaching value."),
                "coaching_cues": SchemaBuilder.array(
                    items: SchemaBuilder.string(description: "One memorable coaching cue"),
                    description: "Exactly 5 memorable coaching cues the player can remember during practice"
                ),
                "drill": SchemaBuilder.string(description: "Specific practice drill with clear instructions the player can do immediately")
            ],
            required: ["metric", "specific_issue", "why_it_matters", "how_to_improve", "coaching_cues", "drill"]
        )

        // Define radar_metrics object with all 5 scores
        let radarMetricsObject = SchemaBuilder.nestedObject(
            properties: [
                "stance_score": SchemaBuilder.integer(description: "Stance and base score (0-100)", minimum: 0, maximum: 100),
                "balance_score": SchemaBuilder.integer(description: "Balance and stability score (0-100)", minimum: 0, maximum: 100),
                "follow_through_score": SchemaBuilder.integer(description: "Follow-through score (0-100)", minimum: 0, maximum: 100),
                "explosive_power_score": SchemaBuilder.integer(description: "Power generation score (0-100)", minimum: 0, maximum: 100),
                "release_point_score": SchemaBuilder.integer(description: "Release point score (0-100)", minimum: 0, maximum: 100)
            ],
            required: ["stance_score", "balance_score", "follow_through_score", "explosive_power_score", "release_point_score"]
        )

        // Define metric_reasoning object with explanations for all 5 metrics
        let metricReasoningObject = SchemaBuilder.nestedObject(
            properties: [
                "stance": SchemaBuilder.string(description: "Explain what you observed about the player's stance in the video"),
                "balance": SchemaBuilder.string(description: "Explain what you observed about the player's balance in the video"),
                "follow_through": SchemaBuilder.string(description: "Explain what you observed about the player's follow-through in the video"),
                "power": SchemaBuilder.string(description: "Explain what you observed about the player's power generation in the video"),
                "release": SchemaBuilder.string(description: "Explain what you observed about the player's release point in the video")
            ],
            required: ["stance", "balance", "follow_through", "power", "release"]
        )

        // Define improvement_tips object with quick tips for each metric
        let improvementTipsObject = SchemaBuilder.nestedObject(
            properties: [
                "stance": SchemaBuilder.string(description: "Quick tip for improving stance"),
                "balance": SchemaBuilder.string(description: "Quick tip for improving balance"),
                "follow_through": SchemaBuilder.string(description: "Quick tip for improving follow-through"),
                "power": SchemaBuilder.string(description: "Quick tip for improving power"),
                "release": SchemaBuilder.string(description: "Quick tip for improving release")
            ],
            required: ["stance", "balance", "follow_through", "power", "release"]
        )

        // Define metadata object
        let metadataObject = SchemaBuilder.nestedObject(
            properties: [
                "frames_analyzed": SchemaBuilder.integer(description: "Total frames analyzed from both videos", minimum: 0),
                "fps": SchemaBuilder.integer(description: "Frames per second used for analysis", minimum: 1, maximum: 120),
                "angles_processed": SchemaBuilder.integer(description: "Number of camera angles processed", minimum: 2, maximum: 2)
            ],
            required: ["frames_analyzed", "fps", "angles_processed"]
        )

        // Define video_context object - what AI actually saw in the video
        let videoContextItemObject = SchemaBuilder.nestedObject(
            properties: [
                "text": SchemaBuilder.string(description: "Specific observation text")
            ],
            required: ["text"]
        )

        let videoContextObject = SchemaBuilder.nestedObject(
            properties: [
                "items": SchemaBuilder.array(
                    items: videoContextItemObject,
                    description: "3-5 specific things observed in the video to prove AI watched it. Include environment, player details from profile, visual details if visible, shot outcome if visible."
                )
            ],
            required: ["items"]
        )

        // Main schema with explicit top-level fields
        return SchemaBuilder.object(
            properties: [
                "confidence": SchemaBuilder.number(description: "Analysis confidence level (0.0 to 1.0)", minimum: 0, maximum: 1),
                "overall_rating": SchemaBuilder.integer(description: "Overall shot technique rating (0-100)", minimum: 0, maximum: 100),
                "key_observation": SchemaBuilder.string(description: "Your #1 observation about THIS PLAYER'S shot technique (40-60 words). What stands out most about their form, timing, or mechanics? Focus on the player's performance, not video quality. Be specific about what you observe (e.g., 'back heel stays planted', 'limited hip rotation', 'stick flex minimal')."),
                "video_context": videoContextObject,
                "radar_metrics": radarMetricsObject,
                "metric_reasoning": metricReasoningObject,
                "primary_focus": primaryFocusObject,
                "improvement_tips": improvementTipsObject,
                "metadata": metadataObject
            ],
            required: ["confidence", "overall_rating", "key_observation", "video_context", "radar_metrics", "metric_reasoning", "primary_focus", "improvement_tips", "metadata"],
            description: "Hockey shot analysis with explicit structure and required coaching fields"
        )
    }
}
