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

                // PREMIUM: WHAT YOU DID WELL (3 items)
                "what_you_did_well": SchemaBuilder.array(
                    items: SchemaBuilder.string(description: "A specific positive observation about their technique or execution"),
                    description: "EXACTLY 3 specific things the player did well. Be specific about what you observed (e.g., 'Great weight transfer from back to front foot', 'Smooth stick flex loading'). Each item = 1 short sentence. MUST have exactly 3 items."
                ),

                // PREMIUM: WHAT TO WORK ON (3 items)
                "what_to_work_on": SchemaBuilder.array(
                    items: SchemaBuilder.string(description: "A specific area that needs improvement"),
                    description: "EXACTLY 3 specific areas for improvement. Be constructive and specific (e.g., 'Keep elbow higher during release', 'Bend knees more for better power'). Each item = 1 short sentence. MUST have exactly 3 items."
                ),

                // PREMIUM: HOW TO IMPROVE (3 items)
                "how_to_improve": SchemaBuilder.array(
                    items: SchemaBuilder.string(description: "A specific drill or exercise to practice"),
                    description: "EXACTLY 3 actionable drills or exercises to improve. Be practical (e.g., 'Practice wall shots focusing on quick release - 50 reps daily', 'Use a balance board while stickhandling'). Each item = 1 short sentence with drill name and brief description. MUST have exactly 3 items."
                ),

                "metadata": metadataObject
            ],
            required: ["confidence", "overall_rating", "ai_comment", "what_you_did_well", "what_to_work_on", "how_to_improve", "metadata"],
            description: "Hockey skill analysis with actionable improvement feedback"
        )
    }
}
