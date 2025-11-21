import Foundation

struct SampleExercises {
    static let all: [Exercise] = [
        // MARK: - Shooting Exercises (8)

        Exercise(
            name: "Quick Release Snap Shots",
            description: "Master the fastest shot in hockey with rapid snap shots",
            category: .shooting,
            config: .countBased(targetCount: 50),
            equipment: [.stick, .pucks, .net],
            instructions: "1. Set up 5-10 pucks in your shooting zone\n2. Focus on minimal windup, quick weight transfer\n3. Snap wrists through release point\n4. Aim for specific targets (corners, five-hole)\n5. Reset quickly between shots",
            tips: "Keep hands apart on stick for maximum leverage. Release should be one fluid motion—load, snap, follow through to target. Practice catching passes and immediately releasing.",
            benefits: "Develops the most dangerous skill in hockey—getting shots off before goalies can set. Essential for scoring on quick transitions and catching goalies moving. Builds muscle memory for game-speed releases."
        ),

        Exercise(
            name: "Top Shelf Corner Accuracy",
            description: "Perfect your top-corner sniping ability",
            category: .shooting,
            config: .countBased(targetCount: 40),
            equipment: [.stick, .pucks, .net],
            instructions: "1. Mark or visualize top corners of net\n2. Start from multiple angles (slot, circles, off-wing)\n3. Focus on elevating puck with wrist roll\n4. Aim for exact corner placement\n5. Vary shot types (wrist, snap, backhand)",
            tips: "To go top shelf, roll wrists UP through release and follow through high. Start shot with puck on heel of blade, roll to toe. Lean slightly back to help elevation.",
            benefits: "Top corner shots are the hardest for goalies to stop. Develops precision shooting under pressure and the ability to pick corners in game situations. Builds confidence to shoot high in tight."
        ),

        Exercise(
            name: "Backhand Shelf Shots",
            description: "Master the deceptive backhand top-corner shot",
            category: .shooting,
            config: .countBased(targetCount: 30),
            equipment: [.stick, .pucks, .net],
            instructions: "1. Set up on backhand side\n2. Cup puck on blade, weight on back foot\n3. Transfer weight forward while rolling wrists UP\n4. Follow through high toward target\n5. Practice from in-tight and from circles",
            tips: "The key is cupping the puck and rolling wrists up HARD through release. Unlike forehand, really exaggerate the upward wrist motion. Lean back slightly to help lift.",
            benefits: "Goalies struggle with high backhands because shooters rarely practice them. Makes you a dual-threat scorer and opens up wraparound opportunities. Essential for beating goalies from sharp angles."
        ),

        Exercise(
            name: "One-Timer Spot Shooting",
            description: "Perfect the most dangerous power-play weapon",
            category: .shooting,
            config: .countBased(targetCount: 40),
            equipment: [.stick, .pucks, .net],
            instructions: "1. Set up in one-timer position (circles, point, bumper)\n2. Have partner feed passes or self-feed\n3. Time your load-up with incoming puck\n4. Meet puck at optimal contact point\n5. Follow through toward net",
            tips: "Load weight on back foot as puck arrives. Meet the puck—don't wait for it. Keep blade square to target and follow through low for hard, accurate shots. Practice from both circles.",
            benefits: "One-timers are the highest-percentage power-play shots. Develops timing, hand-eye coordination, and the ability to shoot in rhythm. Makes you a threat on the power play and creates goals off quick passes."
        ),

        Exercise(
            name: "Catch and Release",
            description: "Master receiving passes and shooting in one motion",
            category: .shooting,
            config: .timeBased(duration: 180),
            equipment: [.stick, .pucks, .net],
            instructions: "1. Have partner make passes from different angles\n2. Receive pass with soft hands\n3. In one motion, transfer to shooting position\n4. Release shot immediately without extra touches\n5. Focus on quick hands and weight transfer",
            tips: "As puck arrives, cushion it but immediately load for shot. Practice both forehand and backhand receptions. The faster your release, the less time goalies have to set.",
            benefits: "Elite scorers shoot off the pass without taking extra touches. Develops quick hands, hand-eye coordination, and the ability to surprise goalies. Essential for scoring on rush plays and quick transitions."
        ),

        Exercise(
            name: "Wrist Shot Rapid Fire",
            description: "Build shooting endurance and quick-release mechanics",
            category: .shooting,
            config: .timeBased(duration: 120),
            equipment: [.stick, .pucks, .net],
            instructions: "1. Set up 20+ pucks in shooting position\n2. Shoot continuously with 1-2 second intervals\n3. Maintain proper form despite fatigue\n4. Focus on consistency and accuracy\n5. Vary targets throughout set",
            tips: "Don't sacrifice form for speed. Each shot should have proper weight transfer and follow-through. This builds shooting stamina for late in games when you're tired.",
            benefits: "Builds shooting endurance so your shot stays strong in the third period. Develops muscle memory and consistency. Improves ability to shoot effectively when fatigued during games."
        ),

        Exercise(
            name: "Low Blocker Side Shots",
            description: "Exploit the most common goalie weakness",
            category: .shooting,
            config: .countBased(targetCount: 40),
            equipment: [.stick, .pucks, .net],
            instructions: "1. Identify goalie's blocker side (right for right-handed goalies)\n2. Aim for lower third of net, blocker side\n3. Practice from various angles and distances\n4. Use wrist shots and snap shots\n5. Focus on accuracy over power",
            tips: "Low blocker is statistically the hardest save for goalies. Shoot for the ice-to-pad area. This is especially effective on breakaways and when coming across the slot.",
            benefits: "Targets the highest-percentage scoring area in hockey. Develops the ability to pick spots under pressure. Creates goals against even elite goalies by attacking their weakness."
        ),

        Exercise(
            name: "Off-Balance Quick Shots",
            description: "Learn to shoot effectively in game-realistic situations",
            category: .shooting,
            config: .timeBased(duration: 120),
            equipment: [.stick, .pucks, .net],
            instructions: "1. Shoot while moving laterally, forward, backward\n2. Shoot while off one foot\n3. Shoot while turning or pivoting\n4. Shoot immediately after stickhandling moves\n5. Simulate defenders disrupting your balance",
            tips: "In games you rarely get perfect setups. Practice shooting from awkward positions. Focus on quick release and getting the puck on net even with bad balance.",
            benefits: "Real games require shooting in traffic, while being checked, and off-balance. Develops the ability to score in realistic game situations. Makes you dangerous even when not in perfect position."
        ),

        // MARK: - Stickhandling Exercises (9)

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
            tips: "Keep your knees bent and stay low for better control. Use quick, short touches on the puck. Look ahead to the next cone, not down at the puck. The tighter your turns, the better your control will be.",
            benefits: "Develops agility and tight-space puck control. Improves ability to navigate through defenders. Builds confidence handling the puck at speed while changing directions."
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
            tips: "Start puck on heel, drag with bottom hand toward toe, cup and pull across. The key is one smooth, quick motion—don't pause. Sell the move with a head fake or shoulder dip. Practice until it's second nature.",
            benefits: "The toe drag is one of the most effective 1-on-1 moves for beating defenders. Creates space and deception. Essential for getting around defenders in tight situations and zone entries."
        ),

        Exercise(
            name: "One-Hand Control Wide Moves",
            description: "Develop elite puck protection and reach",
            category: .stickhandling,
            config: .timeBased(duration: 90),
            equipment: [.stick, .pucks, .cones],
            instructions: "1. Practice controlling puck with one hand only\n2. Make wide moves extending puck away from body\n3. Pull puck back to body using only one hand\n4. Alternate between right and left hand\n5. Maintain control while moving",
            tips: "Keep elbow slightly bent for control. Use your wrist to cup and guide the puck. This move creates separation from defenders by extending the puck out of their reach.",
            benefits: "One-hand control allows you to protect the puck with your body while extending reach. Essential for winning puck battles along boards and maintaining possession under pressure. Elite players use this constantly."
        ),

        Exercise(
            name: "The Crosby Tight Turns",
            description: "Master Sidney Crosby's signature puck protection move",
            category: .stickhandling,
            config: .timeBased(duration: 120),
            equipment: [.stick, .pucks, .cones],
            instructions: "1. Skate forward with puck, make tight 360° turn\n2. Keep puck on outside of turn, protect with body\n3. Use edges to maintain speed through turn\n4. Keep head up to see ice\n5. Exit turn with speed and puck control",
            tips: "Plant outside foot and rotate around it. Keep puck away from pressure using your body as a shield. Practice both directions. The key is maintaining speed through the turn.",
            benefits: "Crosby's signature move for buying time and protecting the puck below goal line. Develops elite puck protection skills and the ability to hold possession under pressure. Essential for power play down-low work."
        ),

        Exercise(
            name: "Forehand-Backhand Transitions",
            description: "Develop seamless puck transfers for deception",
            category: .stickhandling,
            config: .countBased(targetCount: 100),
            equipment: [.stick, .pucks],
            instructions: "1. Perform quick forehand-to-backhand-to-forehand transitions\n2. Keep puck in contact with blade throughout\n3. Practice both stationary and while moving\n4. Increase speed as you improve\n5. Add fakes and head fakes",
            tips: "Roll your wrists to transition smoothly. The puck should never leave your blade. Practice both pulling puck across body and pushing it across. Add shoulder fakes to sell moves.",
            benefits: "Quick transitions freeze defenders and create shooting lanes. Essential for beating goalies in tight and getting around defenders. Develops the soft hands needed for elite playmaking."
        ),

        Exercise(
            name: "Wide-Narrow Pulls",
            description: "Master puck handling at varying distances from body",
            category: .stickhandling,
            config: .timeBased(duration: 90),
            equipment: [.stick, .pucks, .cones],
            instructions: "1. Push puck wide away from body (full extension)\n2. Pull puck back in tight to skates\n3. Repeat continuously while moving\n4. Practice on both forehand and backhand\n5. Keep head up throughout",
            tips: "Wide pushes create space from defenders. Tight pulls protect the puck. Practice the rhythm: push wide, pull tight, push wide. This creates unpredictable movement defenders can't read.",
            benefits: "Varying puck distance makes you unpredictable and hard to defend. Develops the ability to protect the puck or create space as needed. Essential for zone entries and maintaining possession."
        ),

        Exercise(
            name: "The Patrick Kane Dribbles",
            description: "Master rapid small touches for ultimate puck control",
            category: .stickhandling,
            config: .timeBased(duration: 120),
            equipment: [.stick, .pucks, .cones],
            instructions: "1. Make very quick, small touches on puck\n2. Keep puck close to blade with rapid taps\n3. Move forward while maintaining rapid touches\n4. Practice through cones and obstacles\n5. Vary speed and direction",
            tips: "Use soft, quick touches—don't slap the puck. Keep puck within stick-length at all times. This creates unpredictability and makes it impossible for defenders to time poke checks.",
            benefits: "Kane's signature move for beating defenders in tight spaces. Rapid touches make puck unpredictable and difficult to strip. Develops elite hand speed and puck control for 1-on-1 situations."
        ),

        Exercise(
            name: "Tennis Ball Speed Hands",
            description: "Develop lightning-quick hand speed and coordination",
            category: .stickhandling,
            config: .timeBased(duration: 180),
            equipment: [.stick],
            instructions: "1. Use tennis ball or street hockey ball\n2. Practice all stickhandling moves with lighter ball\n3. Ball's lighter weight requires more hand speed\n4. Work on toe drags, pulls, transitions\n5. Practice both stationary and while moving",
            tips: "Tennis balls are harder to control than pucks, forcing you to develop quicker hands. Do this regularly and pucks will feel easy. Great for summer training off-ice.",
            benefits: "Lighter ball requires faster hands and better coordination. When you return to pucks, they feel heavier and easier to control. Develops elite hand speed and stickhandling ability."
        ),

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
            tips: "Start slow and focus on maintaining control around your entire body. As you improve, increase speed. Keep head up and eyes forward as much as possible. Use your wrists and forearms to guide the puck, not just your arms.",
            benefits: "Develops complete 360° puck control and awareness. Builds core strength and coordination. Improves ability to protect puck from all angles. Essential for maintaining possession under pressure from any direction."
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
            tips: "Think of this as stickhandling in a phone booth—you have no space. Use small, rapid touches instead of wide moves. This simulates being in traffic during a game. Keep your feet moving and head up. The tighter the space, the better.",
            benefits: "Develops elite hand speed in confined spaces. Simulates real game situations where you're surrounded by defenders. Improves puck control under pressure. Essential for maintaining possession in traffic and tight areas around the net."
        ),

        // MARK: - Agility Exercises (15)

        Exercise(
            name: "Lateral Bounds",
            description: "Build explosive side-to-side power for skating",
            category: .agility,
            config: .repsSets(reps: 20, sets: 3),
            equipment: [.none],
            instructions: "1. Stand on one leg, explode laterally to other leg\n2. Land on single leg, stabilize, immediately bound back\n3. Cover maximum distance with each bound\n4. Focus on explosive push-off and controlled landing\n5. Rest 60 seconds between sets",
            tips: "Drive hard off outside leg and swing arms for power. Stick each landing before next bound. This mirrors the explosive lateral movement in skating crossovers.",
            benefits: "Builds explosive lateral power essential for crossovers and quick direction changes. Develops single-leg strength and stability critical for skating. Improves defensive gap control and offensive east-west movement."
        ),

        Exercise(
            name: "Lateral Crossover Lunges",
            description: "Strengthen crossover skating mechanics off-ice",
            category: .agility,
            config: .repsSets(reps: 12, sets: 3),
            equipment: [.none],
            instructions: "1. Step one leg behind and across other leg (crossover motion)\n2. Lower into lunge position\n3. Push explosively back to start\n4. Alternate sides\n5. Keep chest up and core engaged",
            tips: "This mimics skating crossover mechanics. Really drive off that back leg. Feel the glute and hip activation. Keep movements controlled but powerful.",
            benefits: "Directly trains crossover skating strength and mechanics. Develops hip mobility and glute strength essential for powerful crossovers. Improves speed around corners and lateral agility."
        ),

        Exercise(
            name: "Single-Leg Skater Hops",
            description: "Build skating-specific lateral explosiveness",
            category: .agility,
            config: .repsSets(reps: 16, sets: 3),
            equipment: [.none],
            instructions: "1. Start on one leg, hop laterally to other leg\n2. Land softly on opposite leg, hold briefly\n3. Immediately hop back to starting leg\n4. Alternate continuously for reps\n5. Focus on distance and soft landings",
            tips: "These mimic the lateral push-off in skating. Drive knees forward and pump arms. Land softly with bent knee to absorb impact. Build up speed as you get stronger.",
            benefits: "Develops the exact explosive lateral power used in skating stride. Builds single-leg stability and power essential for edge work. Improves acceleration and speed through crossovers."
        ),

        Exercise(
            name: "Explosive Starts",
            description: "Train first-step quickness for game situations",
            category: .agility,
            config: .repsSets(reps: 8, sets: 4),
            equipment: [.cones],
            instructions: "1. Start in athletic stance\n2. Explode forward on command for 10 yards\n3. Focus on powerful first three steps\n4. Drive knees and pump arms aggressively\n5. Rest fully between reps",
            tips: "First three steps determine your acceleration. Stay low, drive knees forward, pump arms violently. Imagine exploding out of the blocks. This is about MAX effort, not conditioning.",
            benefits: "First-step quickness is the difference between beating defenders and getting caught. Develops explosive acceleration for loose pucks, backchecking, and creating separation. Essential for every position."
        ),

        Exercise(
            name: "Backward Running",
            description: "Build backward skating strength and mechanics",
            category: .agility,
            config: .distance(distance: 100, unit: .meters),
            equipment: [.none],
            instructions: "1. Run backward maintaining good posture\n2. Stay on balls of feet, drive knees\n3. Keep chest up and core engaged\n4. Look over shoulder periodically\n5. Focus on smooth, powerful strides",
            tips: "This builds the specific muscles used in backward skating. Stay low with knees bent. Push off balls of feet. Keep strides short and quick, not long and slow.",
            benefits: "Strengthens muscles used in backward skating—critical for defensemen. Improves backward mobility, speed, and balance. Develops the ability to defend rushes and gap control skating backward."
        ),

        Exercise(
            name: "5-10-5 Shuttle",
            description: "Test and train explosive change of direction",
            category: .agility,
            config: .repsSets(reps: 6, sets: 3),
            equipment: [.cones],
            instructions: "1. Start at center cone\n2. Sprint 5 yards right, touch line\n3. Sprint 10 yards left, touch line\n4. Sprint 5 yards right back to start\n5. Rest 90 seconds between sets",
            tips: "This is a classic combine drill. Focus on explosive direction changes and staying low. Don't slow down before changes—work on quick deceleration and acceleration.",
            benefits: "Trains the explosive multi-directional changes constant in hockey. Improves ability to quickly change direction in all situations. Essential for defensive pivots, forechecking, and puck pursuit."
        ),

        Exercise(
            name: "Cone Weave Sprint",
            description: "Develop agility while maintaining speed",
            category: .agility,
            config: .timeBased(duration: 60),
            equipment: [.cones],
            instructions: "1. Set up 5-6 cones in straight line, 5 feet apart\n2. Sprint through cones weaving in and out\n3. Stay low with quick feet\n4. Maintain speed throughout pattern\n5. Perform continuously for time",
            tips: "Don't just run around cones—make sharp cuts at each one. Stay on balls of feet. This builds the agility needed for weaving through traffic and avoiding checks.",
            benefits: "Develops the agility and body control needed to navigate traffic at speed. Improves ability to dodge checks, find lanes, and maintain speed through congestion. Essential for zone entries."
        ),

        Exercise(
            name: "Lateral Shuffle to Sprint",
            description: "Train defensive stance transitions to pursuit",
            category: .agility,
            config: .repsSets(reps: 10, sets: 3),
            equipment: [.cones],
            instructions: "1. Start in defensive stance, shuffle laterally 10 yards\n2. Plant and explode forward in sprint for 10 yards\n3. Focus on quick transition from shuffle to sprint\n4. Alternate directions\n5. Rest between sets",
            tips: "The transition is key—don't waste time between shuffle and sprint. Plant hard on outside foot and drive forward explosively. This mimics defensive transitions to pursuit.",
            benefits: "Essential for defensemen transitioning from backward to forward skating. Develops the ability to quickly pursue after defending. Improves reaction time and explosive transition speed."
        ),

        Exercise(
            name: "Box Drill",
            description: "Train all-direction movement and transitions",
            category: .agility,
            config: .timeBased(duration: 45),
            equipment: [.cones],
            instructions: "1. Set up 4 cones in 10-yard square\n2. Sprint forward to cone, shuffle left to next cone\n3. Backpedal to third cone, shuffle right to start\n4. Perform continuously for time\n5. Focus on quick transitions between movements",
            tips: "This drill combines all movement patterns. Don't cheat the backpedaling or shuffling. Sharp turns at each cone. This builds the all-direction movement needed in hockey.",
            benefits: "Trains all movement patterns in one drill—forward, backward, lateral. Develops ability to quickly transition between movement types. Essential for any position, mimics game movement patterns."
        ),

        Exercise(
            name: "Quick Feet Ladder Drill",
            description: "Build rapid foot speed and coordination",
            category: .agility,
            config: .timeBased(duration: 120),
            equipment: [.cones],
            instructions: "1. Set up ladder pattern with cones or tape\n2. Perform various patterns: one foot per box, two feet per box, lateral, etc.\n3. Stay on balls of feet\n4. Maintain rhythm and speed\n5. Keep upper body stable",
            tips: "Stay light on your feet. Look ahead, not down. The faster you can move your feet, the faster you can skate. Do this regularly to maintain quick feet.",
            benefits: "Develops rapid foot turnover essential for skating speed. Improves coordination and balance. Translates directly to quicker skating strides and ability to maintain speed with quick foot movements."
        ),

        Exercise(
            name: "T-Drill",
            description: "Train forward, backward, and lateral movement",
            category: .agility,
            config: .repsSets(reps: 6, sets: 3),
            equipment: [.cones],
            instructions: "1. Set up T-shape: 10 yards forward, 5 yards each side\n2. Sprint forward, shuffle left to cone, shuffle right across, shuffle to center, backpedal to start\n3. Focus on sharp direction changes\n4. Time yourself and try to improve\n5. Rest between sets",
            tips: "This is a classic hockey agility test. Stay low throughout. Don't round corners—make sharp cuts. This tests your ability to move in all directions efficiently.",
            benefits: "Tests and improves all-direction mobility essential for hockey. Develops quick direction changes and movement pattern transitions. Widely used to evaluate hockey agility."
        ),

        Exercise(
            name: "Reaction Cone Drill",
            description: "Train reactive agility and decision-making speed",
            category: .agility,
            config: .timeBased(duration: 90),
            equipment: [.cones],
            instructions: "1. Set up multiple cones in different locations\n2. Partner calls out cone colors/numbers randomly\n3. Sprint to called cone, touch it, return to center\n4. React and sprint to next called cone\n5. Focus on reaction speed",
            tips: "This trains reactive speed, not just planned movement. Stay ready in athletic stance. First step should be explosive. Hockey is about reacting, not just planned movement.",
            benefits: "Hockey requires constant reaction to unpredictable situations. This trains your ability to quickly process info and move explosively. Improves reaction time to loose pucks and defensive situations."
        ),

        Exercise(
            name: "Figure-8 Cone Sprint",
            description: "Build curved running agility and hip mobility",
            category: .agility,
            config: .timeBased(duration: 60),
            equipment: [.cones],
            instructions: "1. Set up two cones 10 yards apart\n2. Sprint in figure-8 pattern around both cones\n3. Stay low and lean into curves\n4. Maintain speed throughout pattern\n5. Perform continuously for time",
            tips: "Lean into curves and use outside leg to push off. Keep feet quick around turns. This builds the hip strength and mobility needed for tight turns on skates.",
            benefits: "Mimics the curved skating patterns constant in hockey. Builds hip mobility and strength for tight turns. Improves ability to maintain speed through turns and curved routes."
        ),

        Exercise(
            name: "Diagonal Cuts",
            description: "Master sharp angle changes at speed",
            category: .agility,
            config: .repsSets(reps: 12, sets: 3),
            equipment: [.cones],
            instructions: "1. Sprint forward, plant hard and cut diagonally (45-90°)\n2. Explode out of cut back to full speed\n3. Alternate directions\n4. Focus on sharp cuts without losing speed\n5. Rest between sets",
            tips: "Plant hard on outside foot and drive off it explosively. Don't round the cut—make it sharp. The sharper you can cut, the more separation you create from defenders.",
            benefits: "Sharp cuts at speed create separation from defenders. Essential for beating forechecks, creating lanes, and offensive zone movement. Develops the ability to change direction without losing speed."
        ),

        Exercise(
            name: "Deceleration Drill",
            description: "Train controlled stopping from full speed",
            category: .agility,
            config: .repsSets(reps: 10, sets: 3),
            equipment: [.cones],
            instructions: "1. Sprint to cone at full speed\n2. Stop as quickly as possible at cone\n3. Hold balanced position\n4. Focus on controlled deceleration, not falling forward\n5. Rest between reps",
            tips: "Get low and dig in to stop. Core tight, chest up. The ability to stop quickly is as important as speed. This prevents overcommitting and improves defensive positioning.",
            benefits: "Quick stops are essential for defensive gap control and avoiding getting beat. Develops lower body strength and control. Improves ability to stop on a dime without losing defensive position."
        ),

        // MARK: - Conditioning Exercises (20)

        Exercise(
            name: "Explosive Push-Ups",
            description: "Build explosive upper body power for checking",
            category: .conditioning,
            config: .repsSets(reps: 15, sets: 3),
            equipment: [.none],
            instructions: "1. Start in push-up position\n2. Lower chest to ground\n3. Explode up so hands leave ground\n4. Land with control and immediately repeat\n5. Rest 60 seconds between sets",
            tips: "Focus on explosive power, not just going through the motions. If you can't do full explosive push-ups, do them from knees. Work up to clapping hands at top.",
            benefits: "Develops explosive upper body power for checking, shot release, and puck battles. Builds chest, shoulders, and triceps strength. Improves ability to win physical battles along boards."
        ),

        Exercise(
            name: "Bulgarian Split Squats",
            description: "Build single-leg skating strength and balance",
            category: .conditioning,
            config: .repsSets(reps: 12, sets: 3),
            equipment: [.bench],
            instructions: "1. Place rear foot on bench behind you\n2. Lower front leg until thigh parallel to ground\n3. Drive through front heel to return to start\n4. Complete all reps one side, then switch\n5. Can add dumbbells for resistance",
            tips: "Keep front knee tracking over toes. Don't let knee cave inward. This builds the single-leg strength critical for skating power. Feel it in your glutes and quads.",
            benefits: "Skating is single-leg movement. This builds unilateral leg strength essential for powerful strides. Develops glute and quad strength while improving balance. Reduces injury risk and power imbalances."
        ),

        Exercise(
            name: "Single-Leg RDLs",
            description: "Strengthen hamstrings and develop skating balance",
            category: .conditioning,
            config: .repsSets(reps: 10, sets: 3),
            equipment: [.dumbbells],
            instructions: "1. Stand on one leg, hold dumbbell in opposite hand\n2. Hinge at hip, lower weight toward ground\n3. Keep back flat, feel stretch in hamstring\n4. Drive through heel to return to start\n5. Complete all reps, then switch sides",
            tips: "Balance is as important as strength here. Keep planted leg slightly bent. Focus on hip hinge, not rounding back. Feel this in your hamstring and glute.",
            benefits: "Builds hamstring strength critical for stride recovery and injury prevention. Develops single-leg balance essential for skating. Strengthens posterior chain for powerful stride push-off."
        ),

        Exercise(
            name: "Mountain Climbers",
            description: "Build conditioning and core strength for hockey",
            category: .conditioning,
            config: .timeSets(duration: 45, sets: 3, restTime: 45),
            equipment: [.none],
            instructions: "1. Start in push-up position\n2. Drive one knee to chest, then quickly switch legs\n3. Maintain plank position throughout\n4. Move legs as fast as possible\n5. Keep core engaged entire time",
            tips: "Don't let hips sag or pike up. This should be tough on your core and get your heart rate up. Great for conditioning and core strength in one exercise.",
            benefits: "Builds cardiovascular conditioning and core strength simultaneously. Develops the core stability needed for balance on skates. Improves stamina for maintaining speed throughout games."
        ),

        Exercise(
            name: "Plank Shoulder Taps",
            description: "Build anti-rotation core strength for body contact",
            category: .conditioning,
            config: .timeSets(duration: 45, sets: 3, restTime: 30),
            equipment: [.none],
            instructions: "1. Hold plank position\n2. Lift one hand and tap opposite shoulder\n3. Alternate hands continuously\n4. Resist rotating hips—keep them square\n5. Maintain stable plank throughout",
            tips: "The challenge is keeping hips from rotating. Widen your feet for more stability. This builds the core strength to resist being moved in puck battles.",
            benefits: "Develops anti-rotation core strength essential for maintaining position in puck battles. Builds shoulder stability. Improves ability to resist checks and maintain balance under contact."
        ),

        Exercise(
            name: "Jump Squats",
            description: "Build explosive leg power for first-step quickness",
            category: .conditioning,
            config: .repsSets(reps: 15, sets: 3),
            equipment: [.none],
            instructions: "1. Start in squat position\n2. Explode up into max vertical jump\n3. Land softly with bent knees\n4. Immediately descend into next rep\n5. Focus on maximum power each rep",
            tips: "These are about explosive power, not endurance. Jump as high as possible each rep. Land softly to protect knees. This builds the fast-twitch power needed for explosive skating.",
            benefits: "Develops explosive leg power and fast-twitch muscle fibers. Increases first-step quickness and acceleration speed. Builds the explosive power essential for beating opponents to loose pucks."
        ),

        Exercise(
            name: "Burpees",
            description: "Ultimate full-body conditioning for hockey",
            category: .conditioning,
            config: .repsSets(reps: 20, sets: 3),
            equipment: [.none],
            instructions: "1. Start standing, drop to push-up position\n2. Perform push-up\n3. Jump feet to hands\n4. Explode into jump with hands overhead\n5. Land and immediately repeat",
            tips: "Burpees are brutal but effective. Maintain good form even when tired. Can modify by removing push-up or jump until you build strength. Work up to doing these unbroken.",
            benefits: "Builds cardiovascular endurance, explosive power, and mental toughness. Develops full-body conditioning needed for high-intensity shifts. Improves ability to maintain performance when fatigued."
        ),

        Exercise(
            name: "Lateral Lunges",
            description: "Strengthen adductors for skating and injury prevention",
            category: .conditioning,
            config: .repsSets(reps: 12, sets: 3),
            equipment: [.none],
            instructions: "1. Step wide to one side, bend that knee\n2. Keep other leg straight, feel stretch in inner thigh\n3. Push back to start through bent leg\n4. Alternate sides\n5. Can add weight for difficulty",
            tips: "Keep chest up and back flat. Feel this in your inner thighs (adductors) and glutes. These muscles are critical for skating and frequently injured—keep them strong.",
            benefits: "Strengthens adductors essential for lateral skating movement and injury prevention. Builds hip mobility for better stride mechanics. Reduces risk of common groin injuries in hockey."
        ),

        Exercise(
            name: "Goblet Squats",
            description: "Build leg strength with perfect squat form",
            category: .conditioning,
            config: .weightRepsSets(weight: 45, reps: 12, sets: 3, unit: .lbs),
            equipment: [.dumbbells],
            instructions: "1. Hold dumbbell at chest level\n2. Squat down until thighs parallel or below\n3. Keep chest up, core tight\n4. Drive through heels to stand\n5. Weight at chest helps maintain upright posture",
            tips: "The dumbbell at chest forces you to stay upright. This teaches perfect squat form. Go as deep as you can with good form. Feel this in quads and glutes.",
            benefits: "Builds leg strength essential for powerful skating. Front-loaded weight improves squat form and core engagement. Develops quads, glutes, and core strength for skating power."
        ),

        Exercise(
            name: "Single-Arm Dumbbell Rows",
            description: "Build back strength for shooting and puck battles",
            category: .conditioning,
            config: .weightRepsSets(weight: 50, reps: 12, sets: 3, unit: .lbs),
            equipment: [.dumbbells, .bench],
            instructions: "1. Place one hand on bench for support\n2. Pull dumbbell to hip, keep elbow close to body\n3. Squeeze shoulder blade back at top\n4. Lower with control\n5. Complete all reps, switch sides",
            tips: "Don't rotate torso—keep it stable. Pull with your back, not just your arm. Squeeze your shoulder blade back at the top. This builds the pulling strength for puck battles.",
            benefits: "Builds back and shoulder strength essential for shot power. Develops pulling strength for winning puck battles. Strengthens muscles used in body positioning and protecting the puck."
        ),

        Exercise(
            name: "Dumbbell Step-Ups",
            description: "Build single-leg power for skating stride",
            category: .conditioning,
            config: .weightRepsSets(weight: 35, reps: 12, sets: 3, unit: .lbs),
            equipment: [.dumbbells, .box],
            instructions: "1. Hold dumbbells at sides\n2. Step up onto box with one leg\n3. Drive through heel to stand on box\n4. Step down with control\n5. Alternate legs or complete all reps one side",
            tips: "Drive through the heel of your stepping leg. Don't push off the ground with your rear leg—make the working leg do all the work. This builds skating-specific strength.",
            benefits: "Develops single-leg strength and power essential for skating. Mimics the single-leg drive in skating stride. Builds glutes, quads, and improves balance under load."
        ),

        Exercise(
            name: "Half-Kneeling Shoulder Press",
            description: "Build shoulder strength and core stability",
            category: .conditioning,
            config: .weightRepsSets(weight: 30, reps: 10, sets: 3, unit: .lbs),
            equipment: [.dumbbells],
            instructions: "1. Kneel with one knee down, one knee up (90° angles)\n2. Hold dumbbell at shoulder\n3. Press overhead while maintaining balance\n4. Lower with control\n5. Complete all reps, switch sides",
            tips: "Half-kneeling position forces core engagement. Don't lean back as you press. This builds shoulder strength while training core stability—both essential for hockey.",
            benefits: "Develops shoulder strength for checking and shot power. Half-kneeling position trains core stability and balance. Builds resilience against shoulder injuries from physical play."
        ),

        Exercise(
            name: "Dumbbell Romanian Deadlifts",
            description: "Strengthen posterior chain for skating power",
            category: .conditioning,
            config: .weightRepsSets(weight: 50, reps: 12, sets: 3, unit: .lbs),
            equipment: [.dumbbells],
            instructions: "1. Hold dumbbells at thighs, feet hip-width\n2. Hinge at hips, lower weights down legs\n3. Keep back flat, feel stretch in hamstrings\n4. Drive through heels to return to start\n5. Don't round back—chest up throughout",
            tips: "This is a hip hinge, not a squat. Feel it in your hamstrings and glutes. Keep weights close to legs. This builds the posterior chain strength critical for powerful skating.",
            benefits: "Strengthens hamstrings and glutes essential for skating stride recovery. Develops posterior chain power for explosive acceleration. Reduces hamstring injury risk common in hockey."
        ),

        Exercise(
            name: "Dumbbell Bench Press",
            description: "Build pressing strength for physical play",
            category: .conditioning,
            config: .weightRepsSets(weight: 60, reps: 10, sets: 3, unit: .lbs),
            equipment: [.dumbbells, .bench],
            instructions: "1. Lie on bench with dumbbells at chest level\n2. Press weights up until arms extended\n3. Lower with control until elbows at 90°\n4. Press back up explosively\n5. Keep feet flat on floor",
            tips: "Dumbbells allow greater range of motion than barbell. Squeeze chest at top. Lower with control, press explosively. This builds the pushing strength for body contact.",
            benefits: "Develops chest and shoulder strength for checking and puck protection. Builds pressing power for winning physical battles. Strengthens muscles used in board play and maintaining position."
        ),

        Exercise(
            name: "Dumbbell Walking Lunges",
            description: "Build leg endurance and stride strength",
            category: .conditioning,
            config: .weightRepsSets(weight: 35, reps: 20, sets: 3, unit: .lbs),
            equipment: [.dumbbells],
            instructions: "1. Hold dumbbells at sides\n2. Step forward into lunge (both knees at 90°)\n3. Drive through front heel to step forward into next lunge\n4. Continue walking forward\n5. Keep torso upright throughout",
            tips: "Don't let front knee go past toes. Take big steps and get full depth. This builds leg endurance critical for maintaining skating power late in games.",
            benefits: "Builds leg strength and muscular endurance for skating. Develops single-leg strength and balance. Improves ability to maintain powerful strides throughout long shifts and full games."
        ),

        Exercise(
            name: "Renegade Rows",
            description: "Build core stability and back strength simultaneously",
            category: .conditioning,
            config: .weightRepsSets(weight: 35, reps: 10, sets: 3, unit: .lbs),
            equipment: [.dumbbells],
            instructions: "1. Hold plank position with hands on dumbbells\n2. Row one dumbbell to hip while maintaining plank\n3. Lower dumbbell back down\n4. Alternate arms\n5. Resist rotating hips throughout",
            tips: "The challenge is keeping your hips square while rowing. Widen feet for more stability. This builds core strength and back strength simultaneously—both critical for hockey.",
            benefits: "Develops anti-rotation core strength for puck battles. Builds back and shoulder strength. Trains ability to maintain stable position while generating force—essential for physical play."
        ),

        Exercise(
            name: "Box Jumps",
            description: "Develop maximum explosive lower body power",
            category: .conditioning,
            config: .repsOnly(reps: 15),
            equipment: [.box],
            instructions: "1. Start facing box in athletic stance\n2. Dip down and explode up onto box\n3. Land softly with bent knees\n4. Step down with control\n5. Reset and repeat",
            tips: "Jump as high as you can each rep. Land softly—knees bent, quiet landing. Step down, don't jump down. This builds explosive power for first-step quickness.",
            benefits: "Develops explosive leg power and fast-twitch muscle fibers. Increases first-step quickness and acceleration speed. Builds vertical power that translates to explosive skating starts."
        ),

        Exercise(
            name: "Skater Hops",
            description: "Build skating-specific lateral explosive power",
            category: .conditioning,
            config: .timeBased(duration: 45),
            equipment: [.none],
            instructions: "1. Hop laterally from one leg to other\n2. Land on single leg, bring other leg behind\n3. Immediately bound to opposite leg\n4. Cover maximum distance with each hop\n5. Continue for full time",
            tips: "Drive off outside leg explosively. Land softly on opposite leg. This directly mimics the lateral explosive movement in skating. The motion should feel like speed skating.",
            benefits: "Mimics skating stride mechanics—explosive lateral push-off and single-leg landing. Builds lateral explosive power and balance. Directly improves skating acceleration and stride power."
        ),

        Exercise(
            name: "Dumbbell Hang Cleans",
            description: "Develop total-body explosive power",
            category: .conditioning,
            config: .weightRepsSets(weight: 55, reps: 8, sets: 3, unit: .lbs),
            equipment: [.dumbbells],
            instructions: "1. Hold dumbbells at thighs, slight knee bend\n2. Explosively extend hips, knees, ankles\n3. Shrug and pull dumbbells up to shoulders\n4. Catch in quarter squat with weights at shoulders\n5. Stand and lower back to start",
            tips: "This is about explosive power, not muscle. The power comes from your hips extending explosively. Think: jump with weights and catch them at shoulders. Great for total-body power.",
            benefits: "Develops total-body explosive power essential for hockey. Builds hip extension power for skating. Improves rate of force development—how quickly you can generate power."
        ),

        Exercise(
            name: "Squat Jumps to Box",
            description: "Build explosive power with landing mechanics",
            category: .conditioning,
            config: .repsOnly(reps: 12),
            equipment: [.box],
            instructions: "1. Start in squat position facing box\n2. Explode up and forward onto box\n3. Land softly in squat position on box\n4. Step down and reset\n5. Focus on maximum explosion and soft landing",
            tips: "Start low, explode high. Swing arms for momentum. Land softly in a squat to absorb impact. This builds explosive power and teaches proper landing mechanics to prevent injury.",
            benefits: "Develops explosive lower body power for acceleration. Teaches proper landing mechanics to reduce injury risk. Builds the explosive power needed for beating opponents to loose pucks and creating separation."
        )
    ]
}
