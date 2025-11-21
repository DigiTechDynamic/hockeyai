import Foundation

// MARK: - Stick Analyzer Schema
/// Schema definition for stick analysis AI response
extension StickAnalysisResponse: AISchemaConvertible {
    public static var schemaDefinition: JSONSchema {
        SchemaBuilder.object(
            properties: [
                "confidence": SchemaBuilder.number(
                    description: "Confidence in the analysis",
                    minimum: 0,
                    maximum: 1
                ),
                "ideal_flex_min": SchemaBuilder.integer(
                    description: "Minimum recommended flex",
                    minimum: 30,
                    maximum: 120
                ),
                "ideal_flex_max": SchemaBuilder.integer(
                    description: "Maximum recommended flex",
                    minimum: 30,
                    maximum: 120
                ),
                "flex_reasoning": SchemaBuilder.string(
                    description: "Explanation for flex recommendation"
                ),
                "ideal_length_min": SchemaBuilder.number(
                    description: "Minimum recommended length in inches",
                    minimum: 46,
                    maximum: 70
                ),
                "ideal_length_max": SchemaBuilder.number(
                    description: "Maximum recommended length in inches",
                    minimum: 46,
                    maximum: 70
                ),
                "length_reasoning": SchemaBuilder.string(
                    description: "Explanation for length recommendation"
                ),
                "ideal_curves": SchemaBuilder.array(
                    items: SchemaBuilder.string(),
                    description: "Recommended curve patterns (1-5 curves)"
                ),
                "curve_reasoning": SchemaBuilder.string(
                    description: "Explanation for curve recommendations"
                ),
                "ideal_kick_point": SchemaBuilder.string(
                    description: "Recommended kick point",
                    enumValues: ["Low", "Mid", "High"]
                ),
                "kick_point_reasoning": SchemaBuilder.string(
                    description: "Explanation for kick point recommendation"
                ),
                "ideal_lie": SchemaBuilder.integer(
                    description: "Recommended lie angle",
                    minimum: 3,
                    maximum: 7
                ),
                "lie_reasoning": SchemaBuilder.string(
                    description: "Explanation for lie angle recommendation"
                ),
                "recommended_sticks": SchemaBuilder.array(
                    items: SchemaBuilder.nestedObject(
                        properties: [
                            "brand": SchemaBuilder.string(),
                            "model": SchemaBuilder.string(),
                            "flex": SchemaBuilder.integer(),
                            "curve": SchemaBuilder.string(),
                            "kick_point": SchemaBuilder.string(),
                            "price": SchemaBuilder.string(),
                            "reasoning": SchemaBuilder.string(),
                            "match_score": SchemaBuilder.integer(minimum: 0, maximum: 100)
                        ],
                        required: ["brand", "model", "flex", "curve", "kick_point", "reasoning", "match_score"]
                    ),
                    description: "3-5 recommended stick models"
                )
            ],
            required: [
                "confidence",
                "ideal_flex_min", "ideal_flex_max", "flex_reasoning",
                "ideal_length_min", "ideal_length_max", "length_reasoning",
                "ideal_curves", "curve_reasoning",
                "ideal_kick_point", "kick_point_reasoning",
                "ideal_lie", "lie_reasoning",
                "recommended_sticks"
            ]
        )
    }

    /// Critical fields that must exist for valid response
    public static var criticalFields: [String]? {
        ["confidence", "recommended_sticks"]
    }
}
