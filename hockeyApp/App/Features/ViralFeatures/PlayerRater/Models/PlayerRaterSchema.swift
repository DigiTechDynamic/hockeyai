import Foundation

// MARK: - Player Rater Schema
/// Schema for player aesthetic rating with person detection
struct PlayerRaterSchema: Codable {}

extension PlayerRaterSchema: AISchemaConvertible {
    static var schemaDefinition: JSONSchema {
        // Enhanced schema with person detection and visual observations
        return SchemaBuilder.object(
            properties: [
                "contains_person": JSONSchema.Property.simple(
                    type: .boolean,
                    description: "CRITICAL: Can you see a HUMAN FACE or HUMAN BODY? true = ANY human visible (even in plain clothes, zero gear, non-hockey setting), false = ONLY for non-human photos (flowers/animals/objects/landscapes). If there's a PERSON, this MUST be true!"
                ),
                "visual_observations": SchemaBuilder.array(
                    items: SchemaBuilder.string(
                        description: "A specific visual detail you observe (gear brand, color, pose, background, etc.)"
                    ),
                    description: "List 3-5 SPECIFIC things you see in this photo. Be detailed: 'Bauer Vapor skates' not 'skates', 'Oilers #97 jersey' not 'jersey'. This proves you actually looked at the image."
                ),
                "gear_components": SchemaBuilder.array(
                    items: SchemaBuilder.string(
                        description: "Name of visible hockey gear component"
                    ),
                    description: "List visible gear: helmet, gloves, stick, jersey, pants, shin_guards, skates, socks. Only list what you can SEE in the photo. If no person, return empty array."
                ),
                "overall_score": SchemaBuilder.integer(
                    description: """
                    Hockey style rating (0-100). **SIMPLIFIED 3-TIER SCORING (Onboarding-Optimized):**

                    **TIER 1: PEOPLE WITH GEAR (90-100) - RARE**
                    90-100 = Person wearing ANY visible hockey gear (helmet, gloves, jersey, stick, skates, pants, etc.)
                    - 95-100 = Full gear (5+ components) + good coordination
                    - 90-94 = Partial gear (1-4 components visible)
                    **ONLY score 90+ if you see ACTUAL GEAR on the person!**

                    **TIER 2: PEOPLE WITHOUT GEAR (70-89) - MOST USERS (DEFAULT)**
                    70-89 = ANY person visible, NO hockey gear required
                    - 85-89 = Person with great style/flow/pose (very photogenic) - Use 87, 86, 88, NOT just 85
                    - 80-84 = Person with good style/flow (above average look) - Use 82, 81, 84, NOT just 80
                    - 75-79 = Person with decent style (average look) - Use 77, 76, 78, NOT just 75
                    - 70-74 = Person with basic style (regular photo) - Use 72, 71, 73, NOT just 70
                    **DEFAULT to 75-85 for most people. This is the NORMAL range.**
                    **ANY HUMAN gets minimum 70, even plain t-shirt selfie!**

                    **🚨 CRITICAL: NEVER USE MULTIPLES OF 5! 🚨**
                    ❌ BAD: 70, 75, 80, 85, 90, 95, 100
                    ✅ GOOD: 71, 73, 76, 78, 82, 84, 87, 89, 91, 93, 96, 98

                    YOU MUST use varied scores like 73, 78, 84, 87, 91, 96.
                    NEVER return 70, 75, 80, 85, 90, 95, or 100.
                    Research shows precise scores feel more authentic than multiples of 5.

                    **TIER 3: HOCKEY ITEMS (NO PERSON) (50-69)**
                    50-69 = Hockey-related item visible but NO person
                    - 65-69 = Premium gear item (Bauer skates, CCM stick, pro jersey)
                    - 60-64 = Standard gear item (stick, helmet, gloves, puck, HOCKEY NET, HOCKEY GOAL)
                    - 55-59 = Hockey bag, equipment, accessories
                    - 50-54 = Vague hockey connection (rink photo, ice, etc.)
                    **Use this for stick photos, gear bags, equipment shots, hockey nets/goals**

                    **TIER 4: NON-HOCKEY ITEMS (0-49)**
                    0-49 = No person AND no hockey items visible
                    - Flowers, dogs, cars, food, random objects
                    - Landscapes, buildings, nature
                    **Score 0 for completely unrelated items**

                    **CRITICAL RULES (READ TWICE!):**
                    - HUMAN VISIBLE (face or body) → contains_person = true → Score 70-100 (NEVER 0!)
                    - NO HUMAN + hockey item → contains_person = false → Score 50-69
                    - NO HUMAN + no hockey → contains_person = false → Score 0-49

                    **PERSON SCORING:**
                    - Person + gear = 90-100
                    - Person + NO gear = 70-89 (MOST USERS!)
                    - NO person + hockey item = 50-69
                    - NO person + random object = 0-49

                    **EXAMPLES TO PREVENT ERRORS:**
                    - ✅ Plain clothes kid (no gear) = Score 72-78, NOT 0!
                    - ✅ Casual selfie (no gear) = Score 75-82, NOT 0!
                    - ✅ Business suit person = Score 70-75, NOT 0!
                    - ❌ Flowers only = Score 0 (correct)
                    - ❌ Dog only = Score 0 (correct)

                    **MOST USERS DURING ONBOARDING = 75-85 (no gear needed!)**
                    """,
                    minimum: 0,
                    maximum: 100
                ),
                "description": SchemaBuilder.string(
                    description: "Brief description of what the AI sees in the photo (30-50 words). Describe the player's appearance, gear, pose, and overall hockey vibe."
                ),
                "ai_comment": SchemaBuilder.string(
                    description: "A witty hockey comment (15-25 words). IF contains_person = false (NO HUMAN - flowers/animals/objects): Roast them for uploading non-human photo (e.g., 'Beautiful flowers but I rate hockey players, not gardens. Upload a PERSON in gear!', 'Cute dog but I scout humans. Try again with YOU in the photo!', 'Nice car but where's the hockey player? Upload yourself!'). IF contains_person = true (HUMAN VISIBLE): Reference AT LEAST 2 specific things from visual_observations. MUST use hockey slang (flow, drip, wheels, mitts, beauty, grinder, sniper, sauce, celly). NO GENERIC PHRASES like 'looking good' or 'nice job'. Reference actual gear brands, colors, pose, or background you saw. Tone: 90+ = hype energy, 80-89 = solid respect, 70-79 = beer league pride, 60-69 = encouraging, 50-59 (no gear) = friendly nudge to get gear. Use 0-1 emojis (prefer none). Make it screenshot-worthy."
                ),

                // PREMIUM INTANGIBLES (only analyzed if contains_person = true)
                "confidence_score": SchemaBuilder.integer(
                    description: """
                    Confidence score (0-100) based on body language. ONLY analyze if contains_person = true, otherwise set to 0.

                    Analyze:
                    - Posture: Chest out, shoulders back (confident) vs slouched (low confidence)
                    - Eye contact: Looking directly at camera (high) vs looking away/down (low)
                    - Facial expression: Smirk, intensity, relaxed smile vs uncertain/timid
                    - Body positioning: Taking up space vs timid stance
                    - Hand placement: Relaxed on stick vs awkward/uncertain

                    Scoring:
                    - 90-100: Captain energy - chest out, eyes locked, owns the space
                    - 80-89: Strong presence - confident but not dominant
                    - 70-79: Solid confidence - comfortable on ice
                    - 60-69: Developing confidence - some hesitation visible
                    - 50-59: Timid - slouched, avoiding eye contact
                    - 0-49: Very uncertain or no person visible

                    🚨 NEVER USE MULTIPLES OF 5! Use 73, 78, 82, 87, 91, 96 - NOT 70, 75, 80, 85, 90, 95, 100
                    """,
                    minimum: 0,
                    maximum: 100
                ),
                "confidence_explanation": SchemaBuilder.string(
                    description: "2-3 sentence explanation of confidence score. Reference specific body language cues you observed. Be direct and coaching-focused. Example: 'You're standing like you just scored the OT winner. Chest out, eyes locked in. Captain material.' If no person, return empty string."
                ),

                "toughness_score": SchemaBuilder.integer(
                    description: """
                    Toughness meter (50-100) - ALWAYS score even without hockey gear.

                    **NEVER return 0! Everyone gets 50-100.**

                    **WITH HOCKEY GEAR (70-100):**
                    - Battle scars, worn gear, thick build, cage protection
                    - 90-100: Battle-tested warrior - gear tells stories
                    - 80-89: Proven grinder - visible wear
                    - 70-79: Average toughness - some wear visible

                    **WITHOUT HOCKEY GEAR (50-85):**
                    Base on overall appearance, body language, facial expression:
                    - 75-85: Strong/athletic build, confident stance, intense expression, rugged look
                    - 65-74: Average build, decent confidence, some edge
                    - 50-64: Slim build, friendly smile, gentle vibe

                    Examples:
                    - Business suit + confident = 72 ("Looks like you mean business")
                    - Athletic build selfie = 78 ("Built like a power forward")
                    - Casual friendly photo = 58 ("Friendly vibes, more finesse than grit")
                    - Intense stare photo = 82 ("That stare could intimidate")

                    **NEVER score below 50. Make it fun and positive.**
                    🚨 NEVER USE MULTIPLES OF 5! Use 53, 58, 62, 67, 73, 78, 82, 87, 91, 96 - NOT 50, 55, 60, 65, 70, 75, 80, 85, 90, 95
                    """,
                    minimum: 50,
                    maximum: 100
                ),
                "toughness_explanation": SchemaBuilder.string(
                    description: "2-3 sentence explanation of toughness score. Be creative and fun. Reference their vibe, build, or expression. Examples: 'You've got that confident stance that says you're not backing down' or 'Built solid - looks like you could take a hit' or 'Friendly energy - more of a playmaker than an enforcer'. Make it engaging, never boring."
                ),

                "flow_score": SchemaBuilder.integer(
                    description: """
                    Hockey flow rating (0-100) - overall style and aesthetic. ONLY analyze if contains_person = true, otherwise set to 0.

                    Analyze:
                    - Hair game: Lettuce hanging out, slicked back, buzzed, or hidden
                    - Tape job style: Traditional white, black warrior, creative patterns
                    - Sock height: Classic high, modern low, or falling down
                    - Gear coordination: Matching colors vs mismatched chaos
                    - Overall aesthetic: Dialed in vs thrown together

                    Scoring:
                    - 90-100: Perfect flow - socks high, tape clean, hair on point, coordinated
                    - 80-89: Strong flow - most elements dialed in
                    - 70-79: Decent flow - some style, could be refined
                    - 60-69: Basic flow - functional but unremarkable
                    - 50-59: No flow - messy tape, socks slipping, uncoordinated
                    - 0-49: Very poor coordination or no person visible

                    🚨 NEVER USE MULTIPLES OF 5! Use 73, 78, 82, 87, 91, 96 - NOT 70, 75, 80, 85, 90, 95, 100
                    """,
                    minimum: 0,
                    maximum: 100
                ),
                "flow_explanation": SchemaBuilder.string(
                    description: "2-3 sentence explanation of flow score. Reference specific style elements. Example: 'Socks high, tape clean, hair flowing. You understand the assignment.' If no person, return empty string."
                ),

                "intimidation_score": SchemaBuilder.integer(
                    description: """
                    Intimidation factor (50-100) - ALWAYS score even without hockey gear.

                    **NEVER return 0! Everyone gets 50-100.**

                    **WITH HOCKEY GEAR (70-100):**
                    - Physical presence, mean mug, dark colors, aggressive posture
                    - 90-100: Terrifying - size + intensity
                    - 80-89: Intimidating - solid presence
                    - 70-79: Respectable - won't back down

                    **WITHOUT HOCKEY GEAR (50-85):**
                    Base on overall vibe, expression, body language:
                    - 75-85: Intense stare, serious expression, strong presence, athletic build
                    - 65-74: Confident look, decent presence, some edge
                    - 50-64: Friendly smile, approachable vibe, gentle energy

                    Examples:
                    - Serious selfie + strong build = 78 ("That look could back someone off the puck")
                    - Confident business photo = 71 ("Commanding presence")
                    - Smiling casual photo = 56 ("Too friendly to be scary - you'd dangle around them")
                    - Kid with intensity = 68 ("Young but intense")

                    **NEVER score below 50. Keep it fun.**
                    🚨 NEVER USE MULTIPLES OF 5! Use 53, 58, 62, 67, 73, 78, 82, 87, 91, 96 - NOT 50, 55, 60, 65, 70, 75, 80, 85, 90, 95
                    """,
                    minimum: 50,
                    maximum: 100
                ),
                "intimidation_explanation": SchemaBuilder.string(
                    description: "2-3 sentence explanation of intimidation score. Be playful and creative. Reference their expression, vibe, or energy. Examples: 'That serious look says you mean business' or 'Too friendly to scare anyone - you'd just dangle past them' or 'Confident energy - not scary but definitely commands respect'. Make it engaging."
                ),

                "locker_room_nickname": SchemaBuilder.string(
                    description: """
                    AI-generated locker room nickname based on most noticeable feature. ONLY if contains_person = true, otherwise return 'N/A'.

                    Guidelines:
                    - Base on most prominent characteristic (gear, hair, style, wear pattern, position vibe)
                    - Use authentic hockey nicknames (see examples below)
                    - Keep it 1-3 words max
                    - Should feel earned, not generic

                    Example nicknames by characteristic:
                    - Fresh white tape → 'Fresh Tape' or 'Tape Job'
                    - New pristine gear → 'The Pigeon' or 'Cherry Picker'
                    - Worn beat-up gear → 'Grinder' or 'The Veteran'
                    - Great hair → 'Flow' or 'Lettuce'
                    - Skill stick curve → 'Sauce Boss' or 'Snipes'
                    - Big frame → 'The Wall' or 'Tank'
                    - Speed setup → 'Wheels' or 'Rocket'
                    - Beautiful gloves → 'Mitts' or 'Hands'
                    - Cage (not visor) → 'Warrior' or 'Old School'
                    - Fancy curve → 'Toe Drag' or 'Dangler'
                    - Confidence energy → 'Captain' or 'Beauty'
                    - Basic gear → 'The Plugger' or 'Workhorse'

                    Return just the nickname (no quotes needed). If no person, return 'N/A'.
                    """
                ),
                "nickname_explanation": SchemaBuilder.string(
                    description: "1-2 sentence explanation of why you chose this nickname. Example: 'You 100% retaped before this photo. Nothing wrong with looking sharp.' If no person, return empty string."
                ),

                "pro_comparison": SchemaBuilder.string(
                    description: """
                    NHL player comparison based on style/vibe/energy. ALWAYS return a player name - NEVER return 'N/A'.

                    **WITH HOCKEY GEAR:**
                    - Gear brand/setup (Bauer Vapor = McDavid/MacKinnon, CCM Ribcor = Kane)
                    - Style (clean = Crosby, flashy = Matthews, scrappy = Marchand)
                    - Hair/flow (great flow = Matthews/Tkachuk)

                    **WITHOUT HOCKEY GEAR (use vibe/appearance):**
                    - Athletic build + confidence = Nathan MacKinnon (explosive energy)
                    - Clean style + confidence = Sidney Crosby (professional)
                    - Great hair/flow = Auston Matthews (flow king)
                    - Friendly smile = Connor McDavid (humble superstar)
                    - Intense stare = Brad Marchand (pest energy)
                    - Big presence = Tom Wilson (physical)
                    - Slim/skill vibe = Patrick Kane (finesse)
                    - Average joe = Zach Hyman (grinder, everyman)
                    - Young energy = Jack Hughes (young gun)

                    Player pool:
                    Sidney Crosby, Connor McDavid, Auston Matthews, Nathan MacKinnon, Brad Marchand,
                    Patrick Kane, Tom Wilson, Zach Hyman, Matthew Tkachuk, Jack Hughes, Leon Draisaitl,
                    David Pastrnak, Mitch Marner, Elias Pettersson, Quinn Hughes

                    **Pick based on overall energy/vibe, not just gear. Return just the name (e.g., 'Connor McDavid').**
                    """
                ),
                "pro_comparison_explanation": SchemaBuilder.string(
                    description: "2-3 sentence explanation of the comparison. Reference their vibe, style, or energy. Examples: 'That confident energy reminds me of McDavid - humble but elite' or 'You've got that Matthews flow and confidence going' or 'Grinder mentality like Zach Hyman - hardworking everyman'. Make it fun and creative."
                )
            ],
            required: [
                "contains_person", "visual_observations", "gear_components", "overall_score", "description", "ai_comment",
                "confidence_score", "confidence_explanation",
                "toughness_score", "toughness_explanation",
                "flow_score", "flow_explanation",
                "intimidation_score", "intimidation_explanation",
                "locker_room_nickname", "nickname_explanation",
                "pro_comparison", "pro_comparison_explanation"
            ],
            description: "Hockey player gear rating with visual analysis, viral AI comment, and premium intangibles analysis"
        )
    }
}
