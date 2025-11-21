import Foundation

// MARK: - Shot Rater Schema
/// Simplified schema with flat structure for shot analysis
struct ShotRaterSchema: Codable {}

extension ShotRaterSchema: AISchemaConvertible {
    static var schemaDefinition: JSONSchema {
        // Define metadata object
        let metadataObject = SchemaBuilder.nestedObject(
            properties: [
                "frames_analyzed": SchemaBuilder.integer(description: "Total frames analyzed from video", minimum: 0),
                "fps": SchemaBuilder.integer(description: "Frames per second used for analysis", minimum: 1, maximum: 120),
                "video_duration": SchemaBuilder.number(description: "Video duration in seconds", minimum: 0)
            ],
            required: ["frames_analyzed", "fps", "video_duration"]
        )

        // Main schema with flat top-level fields
        return SchemaBuilder.object(
            properties: [
                "confidence": SchemaBuilder.number(description: "Analysis confidence level (0.0 to 1.0)", minimum: 0, maximum: 1),
                "overall_rating": SchemaBuilder.integer(description: "Overall shot rating (0-100)", minimum: 0, maximum: 100),
                "technique_score": SchemaBuilder.integer(description: "Technique score (0-100)", minimum: 0, maximum: 100),
                "technique_reason": SchemaBuilder.string(description: "Explanation for technique score based on video observation"),
                "power_score": SchemaBuilder.integer(description: "Power score (0-100)", minimum: 0, maximum: 100),
                "power_reason": SchemaBuilder.string(description: "Explanation for power score based on video observation"),
                "summary": SchemaBuilder.string(description: "Brief analysis summary (2-3 sentences) describing the shot quality and key observations"),
                "metadata": metadataObject
            ],
            required: ["confidence", "overall_rating", "technique_score", "technique_reason", "power_score", "power_reason", "summary", "metadata"],
            description: "Hockey shot analysis with technique and power evaluation"
        )
    }
}

