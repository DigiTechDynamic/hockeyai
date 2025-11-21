import Foundation

// MARK: - Player Rater Onboarding Schema
/// Simplified schema for quick onboarding validation (5 fields only)
/// Used during onboarding flow to validate user uploaded a person
struct PlayerRaterOnboardingSchema: Codable {}

extension PlayerRaterOnboardingSchema: AISchemaConvertible {
    static var schemaDefinition: JSONSchema {
        return SchemaBuilder.object(
            properties: [
                "contains_person": JSONSchema.Property.simple(
                    type: .boolean,
                    description: "CRITICAL: Can you see a HUMAN FACE or HUMAN BODY? true = ANY human visible (even in plain clothes, zero gear, non-hockey setting), false = ONLY for non-human photos (flowers/animals/objects/landscapes). If there's a PERSON, this MUST be true!"
                ),
                "overall_score": SchemaBuilder.integer(
                    description: """
                    Quick validation score (0-100).

                    SIMPLE RULES:
                    - Person detected → Score 70-85 (validated for onboarding)
                    - No person → Score 0

                    🚨 NEVER USE MULTIPLES OF 5!
                    ✅ GOOD: 71, 73, 76, 78, 82, 84
                    ❌ BAD: 70, 75, 80, 85

                    Use varied scores to feel authentic.
                    """,
                    minimum: 0,
                    maximum: 100
                ),
                "tier": SchemaBuilder.string(
                    description: "For onboarding, always return 'Validated' if person detected, 'Invalid' if not"
                ),
                "ai_comment": SchemaBuilder.string(
                    description: """
                    Brief validation comment (3-4 sentences, ~20-30 words total).

                    STRUCTURE:
                    - Sentence 1-2: Specific observation + compliment using hockey slang
                    - Sentence 3: Validation confirmation
                    - Sentence 4: Social nudge to share/flex

                    Hockey slang to use naturally:
                    - flow/lettuce = hair
                    - drip = style
                    - beauty = cool person
                    - bud = friend
                    - boys/lineys = teammates

                    Social nudges:
                    - "Drop this in the group chat"
                    - "Flex on the boys"
                    - "Prove you got in first"
                    - "Show the lineys"

                    EXAMPLES:
                    - "That lettuce is looking sharp, my dude! You're bringing some solid chill vibes. No doubt you're ready to flex on the boys with this shot!"
                    - "Great drip bud! That style is clean. You're validated and ready to roll. Show the lineys you got early access!"
                    - "Nice flow! Looking like a beauty. Onboarding complete, you're in. Time to drop this in the group chat!"

                    Keep it fun, natural, and screenshot-worthy. Reference what you actually see.
                    """
                ),
                "visual_observations": SchemaBuilder.array(
                    items: SchemaBuilder.string(
                        description: "A specific thing you observe"
                    ),
                    description: "List 2-3 SPECIFIC things you see. Examples: 'Good hair/flow', 'Confident stance', 'Blue shirt', 'Outdoor setting'. Keep it simple for onboarding."
                )
            ],
            required: [
                "contains_person",
                "overall_score",
                "tier",
                "ai_comment",
                "visual_observations"
            ],
            description: "Simplified onboarding validation - just checks if person is present and generates quick validation comment"
        )
    }
}
