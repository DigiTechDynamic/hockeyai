import Foundation

// MARK: - Skill Check Schema
struct SkillCheckSchema: Codable {}

extension SkillCheckSchema: AISchemaConvertible {
    static var schemaDefinition: JSONSchema {
        let metadataObject = SchemaBuilder.nestedObject(
            properties: [
                "frames_analyzed": SchemaBuilder.integer(description: "Total frames analyzed from video", minimum: 0),
                "fps": SchemaBuilder.integer(description: "Frames per second used for analysis", minimum: 1, maximum: 120),
                "video_duration": SchemaBuilder.number(description: "Video duration in seconds", minimum: 0)
            ],
            required: ["frames_analyzed", "fps", "video_duration"]
        )

        return SchemaBuilder.object(
            properties: [
                "confidence": SchemaBuilder.number(description: "Analysis confidence level (0.0 to 1.0)", minimum: 0, maximum: 1),
                "overall_rating": SchemaBuilder.integer(description: "Overall skill rating (0-100). 🚨 NEVER USE MULTIPLES OF 5! Use 73, 78, 82, 87, 91, 96 - NOT 70, 75, 80, 85, 90, 95, 100", minimum: 0, maximum: 100),
                "category": SchemaBuilder.string(description: "Detected skill category (e.g., stickhandling, deke, shot, pass, skating)"),
                "ai_comment": SchemaBuilder.string(description: "A fun, personalized comment from Greeny (the AI mascot) about the player's skill - should be encouraging, a bit cheeky, and reference specific things seen in the video. 1-2 sentences."),

                // PREMIUM: STYLE METRICS
                "flow_score": SchemaBuilder.integer(description: "How smooth and effortless the skill execution looks (0-100). Analyze fluidity, grace, coordination. High = buttery smooth, Low = choppy/forced. 🚨 NEVER USE MULTIPLES OF 5! Use 73, 78, 82, 87, 91, 96 - NOT 70, 75, 80, 85, 90, 95, 100", minimum: 0, maximum: 100),
                "confidence_score": SchemaBuilder.integer(description: "Body language confidence during execution (0-100). Analyze posture, hesitation, commitment to the move. High = fearless/committed, Low = tentative. 🚨 NEVER USE MULTIPLES OF 5! Use 73, 78, 82, 87, 91, 96 - NOT 70, 75, 80, 85, 90, 95, 100", minimum: 0, maximum: 100),
                "style_points": SchemaBuilder.integer(description: "Overall cool factor and aesthetic appeal (0-100). How good does it look regardless of effectiveness? High = highlight reel worthy, Low = functional but boring. 🚨 NEVER USE MULTIPLES OF 5! Use 73, 78, 82, 87, 91, 96 - NOT 70, 75, 80, 85, 90, 95, 100", minimum: 0, maximum: 100),

                // PREMIUM: VIRAL POTENTIAL
                "viral_views_estimate": SchemaBuilder.string(description: "Estimated TikTok/social views if posted (e.g., '15K+', '250K+', '1M+'). Base on execution quality, style, and wow-factor. Most skills: 5K-50K. Elite skills: 50K-500K. Insane skills: 500K+"),
                "viral_caption": SchemaBuilder.string(description: "Ready-to-post viral caption for social media. Should be 1-2 sentences, use hockey slang, include relevant emojis (1-2 max), and make it screenshot-worthy. Reference the specific skill shown. Examples: 'That toe drag had him on skates 🔥 | Practice makes permanent' or 'Snipe show at the barn today 🎯 | Beer league but make it highlight reel'"),

                // PREMIUM: IDENTITY
                "trash_talk_line": SchemaBuilder.string(description: "What you'd say after pulling off this move in a game. Should be cocky but playful, reference the skill, use hockey culture language. 1 sentence max. Examples: 'Buddy's ankles just filed for workers comp' or 'That's going on the highlight reel, boys' or 'Top cheese, where mama keeps the peanut butter'"),
                "signature_move_name": SchemaBuilder.string(description: "Creative name for this specific execution/style. Should be 2-4 words, sound cool, reference what makes it unique. Examples: 'The Silky Mitts Special', 'Backhand Butter', 'Ankle Breaker 3000', 'Five Hole Sniper', 'The Dirty Dangle'"),

                "metadata": metadataObject
            ],
            required: ["confidence", "overall_rating", "ai_comment", "flow_score", "confidence_score", "style_points", "viral_views_estimate", "viral_caption", "trash_talk_line", "signature_move_name", "metadata"],
            description: "Hockey skill analysis with viral-optimized premium content"
        )
    }
}

