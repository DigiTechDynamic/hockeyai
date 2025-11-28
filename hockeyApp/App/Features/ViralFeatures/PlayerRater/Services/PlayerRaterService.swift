import Foundation
import UIKit

// MARK: - Player Rater Service
class PlayerRaterService {

    // MARK: - Public Methods

    /// Analyze player photo and get aesthetic rating
    static func analyzePlayer(photo: UIImage, isOnboarding: Bool = false) async throws -> PlayerRating {

        let startTime = Date()

        // Use OpenAI provider for fast image analysis (2-3s vs Gemini's 13-20s on cellular)
        let provider = AIProviderConfig.selectProvider(for: .image)

        print("🤖 [PlayerRaterService] Using provider: \(provider.providerName)")
        print("🎯 [PlayerRaterService] Onboarding mode: \(isOnboarding)")

        // Optimize image for analysis
        let optimizedImage: UIImage
        let compressionQuality: CGFloat

        if isOnboarding {
            // Onboarding: Balanced optimization for speed and quality
            // - Resize to 1024px max (OpenAI recommended)
            // - Compress to 0.85 quality (improved from 0.6 for better validation)
            // - Still fast but with better image quality
            optimizedImage = resizeImage(photo, maxDimension: 1024)
            compressionQuality = 0.85
            print("📸 [PlayerRaterService] Onboarding optimization: resize to 1024px, quality 0.85")
        } else {
            // Full STY Check: High quality for detailed gear analysis
            // - Increased from 0.75 to 0.9 for better quality
            optimizedImage = resizeImage(photo, maxDimension: 1536)
            compressionQuality = 0.9
            print("📸 [PlayerRaterService] Full check: resize to 1536px, quality 0.9")
        }

        // Convert to JPEG data
        guard let imageData = optimizedImage.jpegData(compressionQuality: compressionQuality) else {
            throw AIAnalyzerError.aiProcessingFailed("Could not process image")
        }

        let imageSizeKB = imageData.count / 1024
        print("📸 [PlayerRaterService] Optimized image size: \(imageSizeKB)KB")

        // Create analysis prompt (simpler for onboarding)
        let prompt = isOnboarding ? createOnboardingPrompt() : createAnalysisPrompt()

        // Use provider with async/await
        return try await withCheckedThrowingContinuation { continuation in
            provider.analyzeImage(
                imageData: imageData,
                prompt: prompt,
                generationConfig: [
                    "temperature": 0.75,  // Higher for creativity and humor (research-backed)
                    "maxOutputTokens": isOnboarding ? 1024 : 8192,  // Onboarding needs far fewer tokens
                    "response_mime_type": "application/json",
                    "response_schema": isOnboarding
                        ? PlayerRaterOnboardingSchema.schemaDefinition.toDictionary(includeAdditionalProperties: true)  // Simplified 5 fields
                        : PlayerRaterSchema.schemaDefinition.toDictionary(includeAdditionalProperties: true)  // Full 17 fields
                ]
            ) { result in
                switch result {
                case .success(let rawResponse):
                    // Clean and parse the response
                    let cleanedResponse = AIAnalysisFacade.sanitizeJSON(from: rawResponse)
                    let data = cleanedResponse.data(using: .utf8) ?? Data()

                    print("📄 [PlayerRaterService] Cleaned response length: \(cleanedResponse.count) chars")

                    do {
                        // Decode response based on mode
                        let decoder = JSONDecoder()
                        let raterResponse: PlayerRaterResponse

                        if isOnboarding {
                            // Parse simplified onboarding response and convert to full format
                            let onboardingResponse = try decoder.decode(PlayerRaterOnboardingResponse.self, from: data)
                            raterResponse = onboardingResponse.toFullResponse()
                            print("✅ [PlayerRaterService] Successfully parsed ONBOARDING response (5 fields)")
                        } else {
                            // Parse full response with premium intangibles
                            raterResponse = try decoder.decode(PlayerRaterResponse.self, from: data)
                            print("✅ [PlayerRaterService] Successfully parsed FULL response (17 fields)")
                        }

                        print("   - Contains person: \(raterResponse.contains_person)")
                        print("   - Score: \(raterResponse.overall_score)/100")
                        print("   - Gear components: \(raterResponse.gear_components.count)")
                        print("   - Visual observations: \(raterResponse.visual_observations.count)")
                        print("   - AI Comment: \"\(raterResponse.ai_comment)\"")

                        // Log premium intangibles if person detected
                        if let premium = raterResponse.premiumIntangibles {
                            print("   - 💎 PREMIUM INTANGIBLES:")
                            print("     • Confidence: \(premium.confidenceScore)/100")
                            print("     • Toughness: \(premium.toughnessScore)/100")
                            print("     • Flow: \(premium.flowScore)/100")
                            print("     • Intimidation: \(premium.intimidationScore)/100")
                            print("     • Nickname: \(premium.lockerRoomNickname)")
                            print("     • Pro Comp: \(premium.proComparison)")
                        }

                        let duration = Date().timeIntervalSince(startTime)
                        print("⏱️ [PlayerRaterService] Total analysis time: \(String(format: "%.2f", duration))s")

                        // Create PlayerRating from response (includes premium intangibles)
                        let rating = PlayerRating(
                            overallScore: raterResponse.overall_score,
                            archetype: raterResponse.tier,
                            archetypeEmoji: raterResponse.tierEmoji,
                            photo: photo,
                            aiComment: raterResponse.ai_comment,
                            visualObservations: raterResponse.visual_observations,
                            gearComponents: raterResponse.gear_components,
                            description: raterResponse.description,
                            premiumIntangibles: raterResponse.premiumIntangibles
                        )

                        print("📦 [PlayerRaterService] Created PlayerRating:")
                        print("   - Score: \(rating.overallScore)")
                        print("   - Archetype: \(rating.archetype)")
                        print("   - AI Comment: \(rating.aiComment ?? "NIL")")
                        print("   - Premium Data: \(rating.premiumIntangibles != nil ? "✅ Included" : "❌ Not available")")

                        continuation.resume(returning: rating)

                    } catch let parseError {
                        #if DEBUG
                        print("❌ [PlayerRaterService] Parsing failed")
                        print("📄 Response preview: \(String(cleanedResponse.prefix(500)))")
                        print("💥 Error: \(parseError.localizedDescription)")
                        #endif

                        continuation.resume(throwing: AIAnalyzerError.analysisParsingFailed(
                            "Rating completed but results couldn't be processed. Please try again."
                        ))
                    }

                case .failure(let error):
                    continuation.resume(throwing: AIAnalyzerError.from(error))
                }
            }
        }
    }

    // MARK: - Private Methods

    private static func createAnalysisPrompt() -> String {
        return """
        You are Greeny, a hockey scout with 2.4M TikTok followers known for witty gear observations and hockey humor.

        STEP 1: PERSON DETECTION (ULTRA-CRITICAL - READ CAREFULLY)

        **QUESTION: Can you see a HUMAN FACE or HUMAN BODY in this photo?**

        **IF YES (Human visible):**
        - Set contains_person = true
        - CONTINUE to scoring (person will get 70-100, NEVER 0)
        - Does NOT matter if they have gear or not
        - Does NOT matter if photo is "hockey related" or not
        - **ANY HUMAN = MINIMUM SCORE 70**

        **IF NO (No human visible):**
        - Set contains_person = false
        - Score 0-69 based on content
        - Examples: flowers, dogs, cars, hockey stick laying on ground, empty rink

        **EXAMPLES OF contains_person = TRUE (MINIMUM SCORE 70):**
        - ✅ Person in plain t-shirt and jeans (NO gear) → Score 70-89
        - ✅ Person in casual clothes with good hair → Score 75-85
        - ✅ Person in business suit (zero hockey connection) → Score 70-75
        - ✅ Kid in school uniform (zero gear) → Score 72-78
        - ✅ Selfie in bedroom, no gear visible → Score 70-80
        - ✅ ANY photo with a human face/body → Score 70-100

        **EXAMPLES OF contains_person = FALSE (CAN score 0-69):**
        - ❌ Flowers, garden, plants → Score 0
        - ❌ Dogs, cats, animals → Score 0
        - ❌ Food, cars, objects → Score 0
        - ✅ Hockey net/goal (no person) → Score 60-65 (HOCKEY ITEM!)
        - ✅ Hockey stick on ground (no person) → Score 60-65 (HOCKEY ITEM!)
        - ✅ Gear bag (no person wearing it) → Score 55-60 (HOCKEY ITEM!)
        - ✅ Empty hockey rink → Score 50-55 (HOCKEY CONNECTION!)

        **CRITICAL RULE:**
        If you can see a HUMAN (even in plain clothes, even with zero hockey gear, even in a non-hockey setting):
        - contains_person = TRUE
        - Score = 70-89 (NOT 0!)
        - Comment encourages them to get gear, but stays positive

        ONLY give score 0-49 if there is NO HUMAN in the photo!

        IF HUMAN DETECTED: Continue below ↓

        STEP 2: VISUAL ANALYSIS (Prove you're looking at the image)
        Look at this photo and list 3-5 SPECIFIC things you see. Be detailed:
        - Gear brands: "Bauer Vapor skates" not just "skates"
        - Jerseys: "Oilers #97 McDavid jersey" not just "jersey"
        - Colors: "Green helmet with matching gloves" not just "helmet"
        - Pose: "Pre-shot stance, stick on ice" not just "holding stick"
        - Background: "Outdoor rink with snow" not just "ice"

        STEP 3: GEAR INVENTORY
        List what hockey gear you can SEE (only what's visible):
        - helmet, gloves, stick, jersey, pants, shin_guards, skates, socks

        STEP 4: SCORE USING SIMPLIFIED 3-TIER SYSTEM (ONBOARDING-OPTIMIZED)

        **ULTRA-SIMPLE SCORING - FOLLOW EXACTLY:**

        **TIER 1: PERSON WITH GEAR = 90-100 (RARE)**
        If you see a PERSON wearing ANY hockey gear (helmet, jersey, gloves, stick, skates, pants):
        - 95-100 = Full gear (5+ components) + good coordination/brands
        - 90-94 = Partial gear (1-4 components visible on person)
        **ONLY use 90+ if person is WEARING gear!**

        **TIER 2: PERSON WITHOUT GEAR = 70-89 (MOST USERS - DEFAULT)**
        If you see a PERSON but NO hockey gear at all:
        - 85-89 = Very photogenic, great style/flow/pose (e.g., 87, 86, 88)
        - 80-84 = Above average style/flow, good photo (e.g., 82, 81, 84)
        - 75-79 = Average style, decent photo (e.g., 77, 76, 78) (DEFAULT for most)
        - 70-74 = Basic photo, regular style (e.g., 72, 71, 73)
        **ANY person (even plain t-shirt selfie) = MINIMUM 70!**
        **DEFAULT to 75-85 for regular person photos - this will be 90% of users!**

        **CRITICAL: USE VARIED SCORES - NOT JUST 70, 75, 80, 85!**
        - ✅ GOOD: 73, 77, 82, 84, 88 (feels authentic, personalized)
        - ❌ BAD: 70, 75, 80, 85, 90 (feels generic, bucketed)
        - Reason: Precise numbers (78) feel more credible than round numbers (80)
        - Industry standard (FIFA, NBA 2K, NHL) uses exact scores across full range

        **TIER 3: HOCKEY ITEM (NO PERSON) = 50-69**
        If NO person but you see a hockey-related item:
        - 65-69 = Premium gear item (Bauer skates, pro stick, jersey on hanger)
        - 60-64 = Standard gear item (stick, helmet, gloves, puck, HOCKEY NET, HOCKEY GOAL)
        - 55-59 = Hockey bag, equipment pile, accessories
        - 50-54 = Vague connection (rink photo, ice surface, hockey poster)
        **Use this when user uploads gear photo without wearing it**

        **EXAMPLES:**
        - ✅ Hockey net/goal (no person) → Score 60-65
        - ✅ Hockey stick on ground → Score 60-64
        - ✅ Hockey bag → Score 55-59
        - ✅ Empty rink photo → Score 50-54
        - ❌ Flowers → Score 0 (NOT hockey related)

        **TIER 4: NON-HOCKEY = 0-49**
        If NO person AND no hockey items:
        - 0-49 = Flowers, dogs, food, cars, random objects, nature
        **Score 0 for completely unrelated items**

        **CRITICAL DECISION TREE:**
        1. Is there a PERSON? → YES = Score 70-100 (go to step 2)
        2. Is person WEARING gear? → YES = Score 90-100 | NO = Score 70-89
        3. If NO person: Is there a hockey item? → YES = 50-69 | NO = 0-49

        **KEY RULES:**
        - Person + gear = 90-100
        - Person + NO gear = 70-89 (MOST USERS!)
        - No person + hockey item = 50-69
        - No person + no hockey = 0-49
        - **90% of onboarding users will score 75-85 (person without gear)**

        STEP 5: CREATE GREENY-STYLE COMMENT (15-25 words)

        IF NO PERSON (score = 0):
        - Roast them for uploading flowers/objects/animals
        - Be funny but clear they need to upload themselves
        - Examples above in Step 1

        IF PERSON VISIBLE (score 50-100):
        - Reference AT LEAST 2 things from your visual observations
        - Prove you saw the photo

        HOCKEY SLANG (use naturally):
        - flow/lettuce/salad = hair
        - drip = style
        - wheels = speed/skating
        - mitts = hands/skills/gloves
        - beauty = skilled player
        - grinder = hard worker
        - sniper = goal scorer
        - sauce = pass
        - celly = celebration
        - bucket = helmet
        - silky = smooth

        TONE BY SCORE (ADJUSTED):
        - 95-100 (LEGENDARY): "Championship-level setup. NHL scouts notice gear like this. Absolute beauty"
        - 85-94 (ELITE): "Elite setup. That [specific gear] combo is top-line quality. You're ready for the show"
        - 75-84 (HIGH-LEVEL): "Solid gear coordination. That [specific item] brings it together. High-level vibes"
        - 65-74 (SOLID): "Nice setup. [Specific observation]. Add [X] and you're there"
        - 55-64 (BEER LEAGUE): "Beer league certified. [Observation]. Build that arsenal beauty"
        - 50-54 (FUTURE BEAUTY): "Great foundation. Get some gear and you'll be dangerous. Potential is there"

        BANNED PHRASES (NEVER use these):
        ❌ "You look great!"
        ❌ "Nice job!"
        ❌ "Looking good!"
        ❌ "Keep it up!"
        ❌ Any generic compliment
        ❌ "is fire" / "fire" (too slang-heavy)
        ❌ Forced exclamation after name ("Captain!" "Beauty!")
        ❌ "I rate hockey players not X" (DO NOT say this - just mention missing gear)

        GREENY COMMENT EXAMPLES (ADJUSTED FOR NEW SCORING):

        Legendary (95-100):
        - "Full Bauer Vapor setup with perfect color match. NHL scouts notice gear like this. Absolute beauty"
        - "That captain's C with CCM Ribcor wheels is championship-level coordination. Elite"
        - "Oilers jersey with pro-level Hyperlite skates. McDavid-tier setup right here"

        Elite (85-94):
        - "Elite setup. Bauer bucket with matching gloves and that tape job. Top-line quality"
        - "That Warrior stick and CCM skates combo is high-level. Respectable multi-brand coordination"
        - "Full gear with coordinated colors. That stance says sniper. You're ready for the show"

        High-Level (75-84):
        - "Solid drip! Bauer gear with that green tape is cooking. High-level vibes for sure"
        - "Nice setup! That jersey and those wheels are clean. Add a bucket and you're elite"
        - "5-6 components visible. Respectable mix of brands. Above-average hockey aesthetic"

        Solid (65-74):
        - "Nice shirt and flow bud! Throw on a jersey and some gloves, you'll be cooking"
        - "Great flow! That lettuce deserves to be under a bucket. Get some gear beauty"
        - "Solid start with that jersey. Add some wheels and mitts, you're on your way"

        Beer League (55-64):
        - "Beer league certified! Jersey game is there. Build that gear arsenal and come back"
        - "That stick is a start. Add some gloves and wheels, you'll be a grinder in no time"
        - "Love the hockey vibes! Get yourself some full gear and let's see that transformation"

        Future Beauty (50-54):
        - "Great flow bud! Get yourself some hockey gear and you'll be a beauty. Potential is there"
        - "Nice look! Throw on a jersey next time and let's see that hockey drip develop"
        - "Solid foundation! Add some gear (even just a team hat) and reupload. Let's go"

        EMOJIS: Use 0-1 max (PREFER ZERO). Only: 💀 ⚡ 🔥 🎯 😤

        Return ONLY valid JSON matching the schema. No markdown, no code blocks.
        """
    }

    // MARK: - Onboarding Simplified Prompt
    private static func createOnboardingPrompt() -> String {
        return """
        You are Greeny, a hockey scout known for witty observations.

        TASK: Quick STY validation check.

        1. PERSON CHECK:
        - contains_person = true if human visible, false otherwise
        - Person detected → score 70-85 (validated)
        - No person → score 0

        2. COMMENT (3-4 sentences):
        - Sentence 1-2: Specific observation + compliment
        - Sentence 3: Validation confirmation
        - Sentence 4: Social nudge ("drop this in the group chat", "flex on the boys", "prove you got in first")

        Use hockey slang naturally: flow/lettuce (hair), drip (style), beauty, bud, boys, lineys.

        FIELDS:
        - contains_person: true/false
        - overall_score: 70-85 (person) or 0 (no person)
        - tier: "Validated"
        - ai_comment: Single 3-4 sentence comment
        - visual_observations: 2-3 things you see
        - gear_components: []

        Return ONLY valid JSON. No markdown.
        """
    }

    // MARK: - Image Optimization Helper

    /// Resize image to fit within maxDimension while maintaining aspect ratio
    private static func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size

        // If image is already smaller, return as-is
        if size.width <= maxDimension && size.height <= maxDimension {
            return image
        }

        // Calculate new size maintaining aspect ratio
        let aspectRatio = size.width / size.height
        let newSize: CGSize

        if size.width > size.height {
            // Landscape or square
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            // Portrait
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }

        // Resize using high-quality graphics context
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0) // Use scale 1.0 for consistency
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage ?? image
    }
}
