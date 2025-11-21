import Foundation

// MARK: - Green Machine Weekly Featured Workout
/// This workout changes weekly and is featured at the top of the Train view
/// Partner: @greenmachinehockey (2.4M TikTok followers)

struct GreenMachineContent {
    // MARK: - Featured Workout
    static let featuredWorkout = Workout(
        id: UUID(uuidString: "GM-FEATURED-SKILLS-BUILDER") ?? UUID(),
        name: "Elite Skills Builder",
        exercises: [
            Exercise(
                name: "Around the World",
                description: "Move puck in full circle around your body to develop 360° control",
                category: .stickhandling,
                config: .timeBased(duration: 120),
                equipment: [.stick, .pucks],
                instructions: """
                1. Start with puck in front of your body
                2. Move puck clockwise around entire body in continuous circle
                3. Use blade and hands to guide puck behind back, around side, back to front
                4. Complete 60 seconds clockwise
                5. Switch to counter-clockwise for 60 seconds
                6. Keep movements smooth and controlled throughout
                """,
                tips: "Start slow and focus on maintaining control around your entire body. As you improve, increase speed. Keep head up and eyes forward as much as possible.",
                benefits: "Develops complete 360° puck control and awareness. Builds core strength and coordination.",
                videoFileName: "PlaceHolderVideo.mp4"
            ),
            Exercise(
                name: "Quick Hands in a Box",
                description: "Stickhandle in tight space to develop rapid hand speed",
                category: .stickhandling,
                config: .timeBased(duration: 90),
                equipment: [.stick, .pucks, .cones],
                instructions: """
                1. Mark or tape a 3×3 foot box on the ground
                2. Stay inside the box while stickhandling
                3. Use rapid, quick touches on the puck
                4. Continuously change direction (forward, back, side to side)
                5. Practice toe drags, pulls, and quick transitions
                6. Keep puck in constant motion for full 90 seconds
                """,
                tips: "Think of this as stickhandling in a phone booth—you have no space. Use small, rapid touches instead of wide moves. Keep your feet moving and head up.",
                benefits: "Develops elite hand speed in confined spaces. Simulates real game situations where you're surrounded by defenders.",
                videoFileName: "PlaceHolderVideo.mp4"
            ),
            Exercise(
                name: "Figure-8 Weave",
                description: "Weave through cones in a figure-8 pattern for agility and control",
                category: .stickhandling,
                config: .timeBased(duration: 120),
                equipment: [.stick, .pucks, .cones],
                instructions: """
                1. Set up 4-6 cones in two parallel lines, 3 feet apart
                2. Start at one end with puck on your stick
                3. Weave through cones in a figure-8 pattern
                4. Make tight turns around each cone
                5. Keep puck close to blade throughout
                6. Maintain speed while keeping control
                """,
                tips: "Keep your knees bent and stay low for better control. Use quick, short touches on the puck. Look ahead to the next cone, not down at the puck.",
                benefits: "Develops agility and tight-space puck control. Improves ability to navigate through defenders.",
                videoFileName: "PlaceHolderVideo.mp4"
            ),
            Exercise(
                name: "Toe Drags",
                description: "Master the deceptive toe drag move to beat defenders",
                category: .stickhandling,
                config: .timeBased(duration: 90),
                equipment: [.stick, .pucks],
                instructions: """
                1. Start with puck on heel of blade (forehand)
                2. Drag puck from heel toward toe of blade
                3. Cup the puck at the toe
                4. Pull puck quickly across your body
                5. Complete the move in one fluid motion
                6. Practice both forehand and backhand toe drags
                """,
                tips: "Start puck on heel, drag with bottom hand toward toe, cup and pull across. The key is one smooth, quick motion—don't pause.",
                benefits: "One of the most effective 1-on-1 moves for beating defenders. Creates space and deception.",
                videoFileName: "PlaceHolderVideo.mp4"
            ),
            Exercise(
                name: "Quick Release Snap Shots",
                description: "Master the fastest shot in hockey with rapid snap shots",
                category: .shooting,
                config: .countBased(targetCount: 30),
                equipment: [.stick, .pucks, .net],
                instructions: """
                1. Set up 5-10 pucks in your shooting zone
                2. Focus on minimal windup, quick weight transfer
                3. Snap wrists through release point
                4. Aim for specific targets (corners, five-hole)
                5. Reset quickly between shots
                """,
                tips: "Keep hands apart on stick for maximum leverage. Release should be one fluid motion—load, snap, follow through to target.",
                benefits: "Develops the most dangerous skill in hockey—getting shots off before goalies can set. Essential for scoring on quick transitions.",
                videoFileName: "PlaceHolderVideo.mp4"
            ),
            Exercise(
                name: "Top Shelf Corner Accuracy",
                description: "Perfect your top-corner sniping ability",
                category: .shooting,
                config: .countBased(targetCount: 20),
                equipment: [.stick, .pucks, .net],
                instructions: """
                1. Mark or visualize top corners of net
                2. Start from multiple angles (slot, circles, off-wing)
                3. Focus on elevating puck with wrist roll
                4. Aim for exact corner placement
                5. Vary shot types (wrist, snap, backhand)
                """,
                tips: "To go top shelf, roll wrists UP through release and follow through high. Start shot with puck on heel of blade, roll to toe.",
                benefits: "Top corner shots are the hardest for goalies to stop. Develops precision shooting under pressure.",
                videoFileName: "PlaceHolderVideo.mp4"
            )
        ],
        estimatedTimeMinutes: 22
    )

    // MARK: - Video Preview Info
    static let featuredVideoPreview = "Essential Skills Training"
    static let featuredVideoDuration = "1:00"
    static let featuredDifficulty = "Beginner"
}
