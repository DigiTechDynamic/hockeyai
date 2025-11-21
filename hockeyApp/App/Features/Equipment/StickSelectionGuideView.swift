import SwiftUI

// MARK: - Stick Selection Guide View
/// Comprehensive guide to help users understand hockey stick selection
/// Based on extensive research of professional equipment guides and biomechanics
struct StickSelectionGuideView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.theme) var theme
    @State private var expandedSections: Set<String> = []

    let onLaunchAnalyzer: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            // Background
            theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Custom Header
                header

                // Content
                ScrollView {
                    VStack(spacing: theme.spacing.md) {
                        // Introduction
                        introCard

                        // Guide Sections
                        guideSection(
                            id: "flex",
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Flex Rating",
                            subtitle: "The foundation of your shot",
                            content: { flexContent }
                        )

                        guideSection(
                            id: "length",
                            icon: "ruler",
                            title: "Stick Length",
                            subtitle: "Finding your perfect fit",
                            content: { lengthContent }
                        )

                        guideSection(
                            id: "curve",
                            icon: "waveform.path",
                            title: "Curve Patterns",
                            subtitle: "Match your shooting style",
                            content: { curveContent }
                        )

                        guideSection(
                            id: "lie",
                            icon: "angle",
                            title: "Lie Angle",
                            subtitle: "Blade contact matters",
                            content: { lieContent }
                        )

                        guideSection(
                            id: "kickpoint",
                            icon: "arrow.up.forward",
                            title: "Kick Point",
                            subtitle: "Quick release vs power",
                            content: { kickpointContent }
                        )

                        guideSection(
                            id: "position",
                            icon: "figure.hockey",
                            title: "Position Guide",
                            subtitle: "Forward vs Defense",
                            content: { positionContent }
                        )

                        guideSection(
                            id: "pro",
                            icon: "star.fill",
                            title: "Pro Examples",
                            subtitle: "What the pros use",
                            content: { proContent }
                        )

                        guideSection(
                            id: "mistakes",
                            icon: "exclamationmark.triangle.fill",
                            title: "Common Mistakes",
                            subtitle: "Avoid these errors",
                            content: { mistakesContent }
                        )

                        guideSection(
                            id: "testing",
                            icon: "checkmark.circle.fill",
                            title: "Testing Tips",
                            subtitle: "Evaluate before buying",
                            content: { testingContent }
                        )

                        // CTA Card
                        aiAnalyzerCTA
                    }
                    .padding(.horizontal, theme.spacing.md)
                    .padding(.top, theme.spacing.md)
                    .padding(.bottom, 100)
                }
            }
        }
    }

    // MARK: - Header
    private var header: some View {
        VStack(spacing: 0) {
            HStack {
                // Left: Title only (icon removed for consistency)
                Text("Stick Selection Guide")
                    .font(.system(size: 24, weight: .black))
                    .glowingHeaderText()
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)

                Spacer()

                // Close button (glass style)
                Button(action: { dismiss() }) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        theme.primary.opacity(0.15),
                                        theme.primary.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 42, height: 42)
                            .overlay(
                                Circle()
                                    .stroke(theme.primary.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(color: theme.primary.opacity(0.2), radius: 8, x: 0, y: 2)

                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(theme.primary)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 10)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    // Glass morphism background
                    Rectangle()
                        .fill(.ultraThinMaterial)

                    // Gradient overlay
                    LinearGradient(
                        colors: [
                            theme.surface.opacity(0.9),
                            theme.background.opacity(0.7)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .ignoresSafeArea(edges: .top)
            )

            // Subtle separator line, matching other pages
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            theme.primary.opacity(0),
                            theme.primary.opacity(0.3),
                            theme.primary.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
        }
    }

    // MARK: - Introduction Card
    private var introCard: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            HStack(spacing: theme.spacing.sm) {
                Image(systemName: "book.fill")
                    .font(.system(size: 20))
                    .foregroundColor(theme.primary)

                Text("Complete Stick Selection Guide")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(theme.text)
            }

            Text("Choosing the right hockey stick can dramatically improve your game. This comprehensive guide covers everything from flex and curve to kick points and position-specific requirements. Tap each section to explore.")
                .font(theme.fonts.body)
                .foregroundColor(theme.textSecondary)
                .lineSpacing(4)
        }
        .padding(theme.spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .fill(theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .stroke(theme.primary.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Guide Section
    private func guideSection(
        id: String,
        icon: String,
        title: String,
        subtitle: String,
        content: () -> some View
    ) -> some View {
        VStack(spacing: 0) {
            // Header
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    if expandedSections.contains(id) {
                        expandedSections.remove(id)
                    } else {
                        expandedSections.insert(id)
                    }
                }
            }) {
                HStack(spacing: theme.spacing.md) {
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(theme.primary)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(theme.text)

                        Text(subtitle)
                            .font(theme.fonts.caption)
                            .foregroundColor(theme.textSecondary)
                    }

                    Spacer()

                    Image(systemName: expandedSections.contains(id) ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.textSecondary)
                }
                .padding(theme.spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: theme.cornerRadius)
                        .fill(theme.surface)
                )
            }
            .buttonStyle(PlainButtonStyle())

            // Content
            if expandedSections.contains(id) {
                content()
                    .padding(theme.spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: theme.cornerRadius)
                            .fill(theme.surface.opacity(0.5))
                    )
                    .padding(.top, 2)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            }
        }
    }

    // MARK: - AI Analyzer CTA
    private var aiAnalyzerCTA: some View {
        VStack(spacing: theme.spacing.md) {
            Image(systemName: "sparkles")
                .font(.system(size: 32))
                .foregroundColor(theme.primary)

            Text("Skip the Research")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(theme.text)

            Text("Let our AI analyze your profile, playing style, and shooting technique to find your perfect stick in minutes—not hours.")
                .font(theme.fonts.body)
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Button(action: { onLaunchAnalyzer() }) {
                HStack(spacing: 8) {
                    Image(systemName: "cpu")
                    Text("Try AI Stick Analyzer")
                }
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: theme.cornerRadius)
                        .fill(theme.primary)
                )
            }
        }
        .padding(theme.spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            theme.primary.opacity(0.15),
                            theme.accent.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .stroke(
                    LinearGradient(
                        colors: [
                            theme.primary.opacity(0.6),
                            theme.accent.opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Content Sections
extension StickSelectionGuideView {

    // MARK: - Flex Content
    private var flexContent: some View {
        VStack(alignment: .leading, spacing: theme.spacing.lg) {
            sectionHeader("What is Flex?")

            Text("Flex rating measures the stiffness of your stick shaft. It's the pounds of force needed to bend the stick one inch. Lower numbers = more flexible, higher numbers = stiffer.")
                .font(theme.fonts.body)
                .foregroundColor(theme.textSecondary)
                .lineSpacing(4)

            divider

            sectionHeader("Choosing Your Flex")

            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                bulletPoint("**General Rule**: Start with half your body weight")
                bulletPoint("**Beginners**: Go 10 flex lower than your weight")
                bulletPoint("**Most Popular**: 75-90 flex for adult players")
                bulletPoint("**Wrist Shot Players**: Lower flex for quick release")
                bulletPoint("**Slap Shot Players**: Higher flex for maximum power")
            }

            divider

            sectionHeader("Weight-Based Chart")

            VStack(spacing: 8) {
                flexRow(weight: "100-120 lbs", flex: "40-50", playerType: "Youth")
                flexRow(weight: "120-150 lbs", flex: "50-65", playerType: "Junior")
                flexRow(weight: "150-180 lbs", flex: "65-85", playerType: "Intermediate")
                flexRow(weight: "180-210 lbs", flex: "85-95", playerType: "Senior")
                flexRow(weight: "210+ lbs", flex: "95-110", playerType: "Senior")
            }

            divider

            warningBox(
                icon: "exclamationmark.triangle.fill",
                title: "Critical: Cutting Increases Flex",
                message: "Every inch you cut adds 3-5 flex points. An 85 flex cut 2 inches becomes ~95 flex."
            )

            divider

            sectionHeader("How Flex Affects Your Shot")

            Text("When you shoot, your stick bends as it contacts the ice, storing energy like a spring. As the stick snaps back, it transfers that energy into the puck, increasing shot power and velocity. The right flex lets you fully load the stick for maximum energy transfer.")
                .font(theme.fonts.body)
                .foregroundColor(theme.textSecondary)
                .lineSpacing(4)
        }
    }

    // MARK: - Length Content
    private var lengthContent: some View {
        VStack(alignment: .leading, spacing: theme.spacing.lg) {
            sectionHeader("Measuring Your Stick")

            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                bulletPoint("**With Skates On**: Top of stick should reach between chin and nose")
                bulletPoint("**Without Skates**: Stick should be between chin and nose")
                bulletPoint("**Alternative Method**: Blade flat on ground, shaft reaches your nose")
            }

            divider

            sectionHeader("Length Preferences")

            VStack(spacing: theme.spacing.md) {
                preferenceRow(
                    length: "Shorter (Chin)",
                    benefits: "Better puck handling, quicker movements, improved stickhandling",
                    bestFor: "Forwards, skilled players"
                )

                preferenceRow(
                    length: "Medium (Mid-Nose)",
                    benefits: "Balanced reach and control, all-around performance",
                    bestFor: "Versatile players"
                )

                preferenceRow(
                    length: "Longer (Nose+)",
                    benefits: "Extended reach, poke-checking, powerful slap shots",
                    bestFor: "Defensemen"
                )
            }

            divider

            sectionHeader("Current Trend")

            highlightBox(
                "The modern trend favors shorter sticks (chin height or lower) for improved puck control and agility. Many NHL players use shorter sticks than traditional guidelines suggest."
            )

            divider

            warningBox(
                icon: "scissors",
                title: "Cutting Considerations",
                message: "Remember: Cutting your stick makes it stiffer. If you buy a 70 flex and cut 2 inches, it becomes ~80 flex. Factor this into your flex selection."
            )
        }
    }

    // MARK: - Curve Content
    private var curveContent: some View {
        VStack(alignment: .leading, spacing: theme.spacing.lg) {
            sectionHeader("Understanding Curve Patterns")

            Text("Your blade curve affects shooting, passing, and puck control. Curves are defined by location (heel/mid/toe), depth (shallow/deep), and face angle (open/closed).")
                .font(theme.fonts.body)
                .foregroundColor(theme.textSecondary)
                .lineSpacing(4)

            divider

            sectionHeader("Popular Curve Patterns")

            VStack(spacing: theme.spacing.md) {
                curveCard(
                    name: "P92 / P29 (Mid-Toe)",
                    description: "The most versatile and popular curve",
                    characteristics: [
                        "Medium curve depth",
                        "Slightly open face",
                        "Curve starts mid-blade"
                    ],
                    bestFor: "All-around play, balance of shooting and passing",
                    pros: "Excellent versatility, good for beginners",
                    cons: "Not specialized for any specific skill"
                )

                curveCard(
                    name: "P88 (Heel/Mid)",
                    description: "A flatter, more traditional curve",
                    characteristics: [
                        "Shallow curve depth",
                        "Closed face angle",
                        "Curve in middle"
                    ],
                    bestFor: "Passing accuracy, backhand shots",
                    pros: "Superior puck control, excellent backhands",
                    cons: "Harder to elevate puck in tight"
                )

                curveCard(
                    name: "P28 (Toe Curve)",
                    description: "Aggressive toe curve with open face",
                    characteristics: [
                        "Deep curve depth",
                        "Very open face",
                        "Curve at toe"
                    ],
                    bestFor: "Quick wrist shots, toe drags, lifting puck",
                    pros: "Excellent for elevating puck, toe control",
                    cons: "Can cause puck flutter if not used correctly"
                )
            }

            divider

            sectionHeader("Curve Depth Explained")

            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                bulletPoint("**Slight (3/8\")**: Better passing, easier backhands, harder to lift")
                bulletPoint("**Moderate (1/2\")**: Most popular, balanced performance")
                bulletPoint("**Deep (5/8\"+)**: Easy to lift, reduced passing/backhand accuracy")
            }

            divider

            sectionHeader("Face Angle (Loft)")

            Text("Face angle determines how much the blade 'opens' toward the sky. More open = easier to lift the puck. Closed = better for low shots and backhands.")
                .font(theme.fonts.body)
                .foregroundColor(theme.textSecondary)
                .lineSpacing(4)

            divider

            highlightBox(
                "Beginners should start with moderate curves (P92/P29). Deep curves require more skill to control passing and backhand shots."
            )
        }
    }

    // MARK: - Lie Content
    private var lieContent: some View {
        VStack(alignment: .leading, spacing: theme.spacing.lg) {
            sectionHeader("What is Lie?")

            Text("Lie is the angle between the blade and shaft when the blade is flat on the ice. It's measured in degrees and typically ranges from 4-7.")
                .font(theme.fonts.body)
                .foregroundColor(theme.textSecondary)
                .lineSpacing(4)

            divider

            sectionHeader("Common Lie Angles")

            VStack(spacing: 8) {
                lieRow(lie: "Lie 4", angle: "137° / 43°", style: "Very low skating stance")
                lieRow(lie: "Lie 5", angle: "135° / 45°", style: "Most common, balanced")
                lieRow(lie: "Lie 6", angle: "133° / 47°", style: "Upright skating, puck close")
                lieRow(lie: "Lie 7", angle: "131° / 49°", style: "Very upright stance")
            }

            Text("*Angle shown as blade-to-shaft / ice-to-shaft")
                .font(theme.fonts.caption)
                .foregroundColor(theme.textSecondary.opacity(0.7))

            divider

            sectionHeader("How to Test Your Lie")

            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                bulletPoint("Stand in your natural skating position")
                bulletPoint("Hold the stick where you normally would")
                bulletPoint("Look at the blade on the ground:")
                bulletPoint("  • **Flat on floor** = Correct lie")
                bulletPoint("  • **Toe up** = Need lower lie number")
                bulletPoint("  • **Heel up** = Need higher lie number")
            }

            divider

            sectionHeader("Why It Matters")

            highlightBox(
                "Proper lie ensures maximum blade contact with the ice, improving puck control, shot accuracy, and reducing uneven blade wear. Forwards typically use higher lies (6-7) for upright skating, while defensemen prefer lower lies (4-5) for a lower stance."
            )
        }
    }

    // MARK: - Kick Point Content
    private var kickpointContent: some View {
        VStack(alignment: .leading, spacing: theme.spacing.lg) {
            sectionHeader("What is Kick Point?")

            Text("The kick point (flex point) is where your stick bends most when loaded for a shot. It determines how the stick releases energy into the puck.")
                .font(theme.fonts.body)
                .foregroundColor(theme.textSecondary)
                .lineSpacing(4)

            divider

            sectionHeader("Kick Point Types")

            VStack(spacing: theme.spacing.md) {
                kickPointCard(
                    type: "Low Kick",
                    location: "Closer to blade",
                    shotStyle: "Quick Release",
                    brands: "Bauer Vapor, Warrior Covert, CCM RibCor, True Hzrdus",
                    benefits: [
                        "Lightning-fast shot release",
                        "Ideal for wrist/snap shots",
                        "Perfect for in-close scoring"
                    ],
                    tradeoffs: "Less overall shot power",
                    bestFor: "Forwards attacking near the net"
                )

                kickPointCard(
                    type: "Mid Kick",
                    location: "Middle of shaft",
                    shotStyle: "Maximum Power",
                    brands: "Bauer Supreme, CCM Tacks, Warrior Alpha",
                    benefits: [
                        "Powerful slap shots",
                        "Longer load time for energy",
                        "Balanced performance"
                    ],
                    tradeoffs: "Slower release than low kick",
                    bestFor: "Defensemen, power forwards"
                )

                kickPointCard(
                    type: "Hybrid/Variable",
                    location: "Adapts to your shot",
                    shotStyle: "Versatile",
                    brands: "Some modern sticks",
                    benefits: [
                        "Flexible for different shots",
                        "Best of both worlds",
                        "Adapts to technique"
                    ],
                    tradeoffs: "May not excel at either extreme",
                    bestFor: "All-around players"
                )
            }

            divider

            sectionHeader("The Power vs Speed Trade-off")

            highlightBox(
                "There's an inverse relationship: quicker release = less power, more power = slower release. Choose based on your position and shooting situations."
            )
        }
    }

    // MARK: - Position Content
    private var positionContent: some View {
        VStack(alignment: .leading, spacing: theme.spacing.lg) {
            sectionHeader("Forwards vs Defensemen")

            VStack(spacing: theme.spacing.md) {
                positionCard(
                    position: "FORWARDS",
                    icon: "figure.hockey",
                    specs: [
                        "**Length**: Shorter (chin height)",
                        "**Flex**: Lower (quick loading)",
                        "**Kick Point**: Low (quick release)",
                        "**Lie**: Higher (5-7, upright skating)",
                        "**Curve**: Moderate to deep (P28, P92)"
                    ],
                    reasoning: "Forwards need quick hands, fast shots, and excellent puck control in tight spaces. Shorter sticks and lower flex enable rapid stickhandling and quick-release wrist shots."
                )

                positionCard(
                    position: "DEFENSEMEN",
                    icon: "shield.fill",
                    specs: [
                        "**Length**: Longer (nose+ height)",
                        "**Flex**: Higher (shot power)",
                        "**Kick Point**: Mid (powerful slap shots)",
                        "**Lie**: Lower (4-5, defensive stance)",
                        "**Curve**: Moderate to slight (P88, P92)"
                    ],
                    reasoning: "Defensemen need reach for poke-checks, passing lanes, and point shots. Longer sticks with higher flex produce powerful slap shots from the blue line."
                )
            }

            divider

            sectionHeader("Position-Specific Examples")

            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                bulletPoint("**Skilled Forward** (McDavid): 85 flex, P28 toe curve, short stick")
                bulletPoint("**Power Forward** (Matthews): 80 flex, P92 mid curve, medium stick")
                bulletPoint("**Two-Way Forward** (Crosby): 100 flex, P29 mid curve")
                bulletPoint("**Offensive D-man**: 90-100 flex, mid kick, longer reach")
                bulletPoint("**Stay-at-Home D**: 95-110 flex, P88 flat curve, max length")
            }
        }
    }

    // MARK: - Pro Content
    private var proContent: some View {
        VStack(alignment: .leading, spacing: theme.spacing.lg) {
            sectionHeader("NHL Player Stick Specs")

            Text("See what equipment the pros trust for their multi-million dollar careers.")
                .font(theme.fonts.body)
                .foregroundColor(theme.textSecondary)
                .lineSpacing(4)

            divider

            VStack(spacing: theme.spacing.md) {
                proPlayerCard(
                    name: "Connor McDavid",
                    stats: "190 lbs / Center",
                    flex: "85",
                    curve: "P28 (Toe Curve)",
                    length: "Short",
                    kickpoint: "Low",
                    note: "Prioritizes lightning-quick release and toe control for precision snipes."
                )

                proPlayerCard(
                    name: "Auston Matthews",
                    stats: "208 lbs / Center",
                    flex: "80-85",
                    curve: "P92 (Mid Curve)",
                    length: "Medium",
                    kickpoint: "Low-Mid",
                    note: "Uses the most popular all-around curve with a softer flex for quick shots."
                )

                proPlayerCard(
                    name: "Sidney Crosby",
                    stats: "201 lbs / Center",
                    flex: "100",
                    curve: "P29 (Same as P92)",
                    length: "Medium",
                    kickpoint: "Mid",
                    note: "Prefers a stiffer stick (higher than body weight rule) for power and board battles."
                )
            }

            divider

            highlightBox(
                "Notice: Even pros vary from the 'rules'. McDavid and Matthews use flex below the 50% bodyweight guideline for quick release, while Crosby goes higher for power. Find what works for YOUR game."
            )
        }
    }

    // MARK: - Mistakes Content
    private var mistakesContent: some View {
        VStack(alignment: .leading, spacing: theme.spacing.lg) {
            sectionHeader("Common Beginner Mistakes")

            VStack(spacing: theme.spacing.md) {
                mistakeCard(
                    number: "1",
                    mistake: "Buying Too Stiff",
                    why: "Can't fully load the stick = weak shots",
                    solution: "Start 10 flex below bodyweight for beginners. You can always go stiffer later."
                )

                mistakeCard(
                    number: "2",
                    mistake: "Buying Too Long",
                    why: "Parents think it'll last longer as kids grow",
                    solution: "Long sticks hurt development. Fit for NOW, not the future. Replace as they grow."
                )

                mistakeCard(
                    number: "3",
                    mistake: "Forgetting Cutting = Stiffer",
                    why: "Cut 2 inches off a 70 flex → now it's 80 flex",
                    solution: "Buy flex based on your FINAL length after cutting, not the original length."
                )

                mistakeCard(
                    number: "4",
                    mistake: "Choosing Deep Curves as Beginners",
                    why: "Harder to pass and shoot backhands accurately",
                    solution: "Start with moderate curves (P92). Progress to deep curves (P28) as skills develop."
                )

                mistakeCard(
                    number: "5",
                    mistake: "Ignoring Lie Angle",
                    why: "Toe or heel-heavy contact reduces control and wears blade unevenly",
                    solution: "Test in your skating stance. The whole blade should sit flat on the ice."
                )

                mistakeCard(
                    number: "6",
                    mistake: "Copying Pros Blindly",
                    why: "Pro specs are highly personalized and may not suit your game",
                    solution: "Use pro examples as reference, but test what works for YOUR body and style."
                )
            }
        }
    }

    // MARK: - Testing Content
    private var testingContent: some View {
        VStack(alignment: .leading, spacing: theme.spacing.lg) {
            sectionHeader("Before You Buy")

            Text("The best stick is the one that feels right for YOU. Here's how to evaluate sticks before purchasing.")
                .font(theme.fonts.body)
                .foregroundColor(theme.textSecondary)
                .lineSpacing(4)

            divider

            sectionHeader("In-Store Testing")

            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                bulletPoint("**Hold at Balance Point**: Does the blade feel heavy or balanced?")
                bulletPoint("**Assume Skating Stance**: Is the blade flat on the ground?")
                bulletPoint("**Stickhandle**: Use a puck or ball. Does it feel natural?")
                bulletPoint("**Flex Test**: Push down on the shaft. Can you bend it comfortably?")
                bulletPoint("**Check Lie**: In your stance, is toe or heel lifting off the ground?")
            }

            divider

            sectionHeader("What to Feel For")

            VStack(spacing: theme.spacing.md) {
                testingCriteriaCard(
                    aspect: "Comfort",
                    goodSign: "Feels natural in your hands, balanced",
                    badSign: "Awkward grip, blade-heavy, unbalanced"
                )

                testingCriteriaCard(
                    aspect: "Flex",
                    goodSign: "Can load the stick with moderate pressure",
                    badSign: "Can't bend it OR it feels like a noodle"
                )

                testingCriteriaCard(
                    aspect: "Blade Contact",
                    goodSign: "Entire blade flat in your skating stance",
                    badSign: "Only toe or only heel touching"
                )

                testingCriteriaCard(
                    aspect: "Puck Feel",
                    goodSign: "Receptions feel cushioned, control is smooth",
                    badSign: "Puck bounces off ('pingy'), feels disconnected"
                )
            }

            divider

            sectionHeader("Break-In Period")

            highlightBox(
                "Give a new stick 2-3 ice sessions before judging. Sticks need break-in time, and you need time to adjust. The perfect stick should 'disappear' in your hands—you shouldn't think about it."
            )

            divider

            warningBox(
                icon: "lightbulb.fill",
                title: "Pro Tip",
                message: "Many hockey shops have shooting areas. Take advantage! A few shots tell you more than any spec sheet."
            )
        }
    }
}

// MARK: - Helper Components
extension StickSelectionGuideView {

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(theme.text)
    }

    private var divider: some View {
        Rectangle()
            .fill(theme.divider.opacity(0.3))
            .frame(height: 1)
    }

    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(theme.fonts.body)
                .foregroundColor(theme.primary)

            Text(.init(text))
                .font(theme.fonts.body)
                .foregroundColor(theme.textSecondary)
                .lineSpacing(4)
        }
    }

    private func highlightBox(_ text: String) -> some View {
        HStack(alignment: .top, spacing: theme.spacing.sm) {
            Image(systemName: "star.fill")
                .font(.system(size: 16))
                .foregroundColor(theme.primary)

            Text(text)
                .font(theme.fonts.body)
                .foregroundColor(theme.textSecondary)
                .lineSpacing(4)
        }
        .padding(theme.spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.primary.opacity(0.1))
        )
    }

    private func warningBox(icon: String, title: String, message: String) -> some View {
        HStack(alignment: .top, spacing: theme.spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.orange)

                Text(message)
                    .font(theme.fonts.callout)
                    .foregroundColor(theme.textSecondary)
                    .lineSpacing(4)
            }
        }
        .padding(theme.spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.1))
        )
    }

    private func flexRow(weight: String, flex: String, playerType: String) -> some View {
        HStack {
            Text(weight)
                .font(theme.fonts.callout)
                .foregroundColor(theme.text)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(flex)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(theme.primary)
                .frame(maxWidth: .infinity, alignment: .center)

            Text(playerType)
                .font(theme.fonts.caption)
                .foregroundColor(theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, theme.spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(theme.surface.opacity(0.5))
        )
    }

    private func preferenceRow(length: String, benefits: String, bestFor: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(length)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(theme.primary)

            Text(benefits)
                .font(theme.fonts.callout)
                .foregroundColor(theme.textSecondary)
                .lineSpacing(3)

            Text("Best for: \(bestFor)")
                .font(theme.fonts.caption)
                .foregroundColor(theme.text.opacity(0.7))
                .italic()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(theme.spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.surface.opacity(0.5))
        )
    }

    private func curveCard(name: String, description: String, characteristics: [String], bestFor: String, pros: String, cons: String) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            Text(name)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(theme.primary)

            Text(description)
                .font(theme.fonts.callout)
                .foregroundColor(theme.text)
                .italic()

            VStack(alignment: .leading, spacing: 4) {
                ForEach(characteristics, id: \.self) { char in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(theme.primary.opacity(0.6))
                            .frame(width: 4, height: 4)
                        Text(char)
                            .font(theme.fonts.caption)
                            .foregroundColor(theme.textSecondary)
                    }
                }
            }

            divider

            VStack(alignment: .leading, spacing: 4) {
                Text("Best for: \(bestFor)")
                    .font(theme.fonts.caption)
                    .foregroundColor(theme.text)

                HStack(alignment: .top, spacing: 4) {
                    Text("✓")
                        .foregroundColor(.green)
                    Text(pros)
                        .font(theme.fonts.caption)
                        .foregroundColor(theme.textSecondary)
                }

                HStack(alignment: .top, spacing: 4) {
                    Text("✗")
                        .foregroundColor(.red)
                    Text(cons)
                        .font(theme.fonts.caption)
                        .foregroundColor(theme.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(theme.spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.surface.opacity(0.5))
        )
    }

    private func lieRow(lie: String, angle: String, style: String) -> some View {
        HStack {
            Text(lie)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(theme.primary)
                .frame(width: 60, alignment: .leading)

            Text(angle)
                .font(theme.fonts.callout)
                .foregroundColor(theme.text)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(style)
                .font(theme.fonts.caption)
                .foregroundColor(theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, theme.spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(theme.surface.opacity(0.5))
        )
    }

    private func kickPointCard(type: String, location: String, shotStyle: String, brands: String, benefits: [String], tradeoffs: String, bestFor: String) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            HStack {
                Text(type)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(theme.primary)

                Spacer()

                Text(shotStyle)
                    .font(theme.fonts.caption)
                    .foregroundColor(theme.text)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(theme.primary.opacity(0.2))
                    )
            }

            Text("Flex Location: \(location)")
                .font(theme.fonts.callout)
                .foregroundColor(theme.textSecondary)
                .italic()

            VStack(alignment: .leading, spacing: 4) {
                ForEach(benefits, id: \.self) { benefit in
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                            .frame(width: 14, alignment: .center)
                        Text(benefit)
                            .font(theme.fonts.caption)
                            .foregroundColor(theme.textSecondary)
                    }
                }
            }

            divider

            VStack(alignment: .leading, spacing: 4) {
                Text("Tradeoff: \(tradeoffs)")
                    .font(theme.fonts.caption)
                    .foregroundColor(.orange)

                Text("Best for: \(bestFor)")
                    .font(theme.fonts.caption)
                    .foregroundColor(theme.text)
                    .bold()

                Text("Brands: \(brands)")
                    .font(theme.fonts.caption)
                    .foregroundColor(theme.textSecondary.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(theme.spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.surface.opacity(0.5))
        )
    }

    private func positionCard(position: String, icon: String, specs: [String], reasoning: String) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            HStack(spacing: theme.spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(theme.primary)

                Text(position)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(theme.primary)
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(specs, id: \.self) { spec in
                    Text(.init(spec))
                        .font(theme.fonts.callout)
                        .foregroundColor(theme.textSecondary)
                }
            }

            divider

            Text(reasoning)
                .font(theme.fonts.callout)
                .foregroundColor(theme.text)
                .lineSpacing(4)
                .italic()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(theme.spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.surface.opacity(0.5))
        )
    }

    private func proPlayerCard(name: String, stats: String, flex: String, curve: String, length: String, kickpoint: String, note: String) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(theme.primary)

                    Text(stats)
                        .font(theme.fonts.caption)
                        .foregroundColor(theme.textSecondary)
                }

                Spacer()
            }

            VStack(spacing: 4) {
                specRow(label: "Flex", value: flex)
                specRow(label: "Curve", value: curve)
                specRow(label: "Length", value: length)
                specRow(label: "Kick Point", value: kickpoint)
            }

            divider

            Text(note)
                .font(theme.fonts.caption)
                .foregroundColor(theme.text)
                .lineSpacing(3)
                .italic()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(theme.spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.surface.opacity(0.5))
        )
    }

    private func specRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(theme.fonts.caption)
                .foregroundColor(theme.textSecondary)
                .frame(width: 80, alignment: .leading)

            Text(value)
                .font(theme.fonts.callout)
                .foregroundColor(theme.text)
        }
    }

    private func mistakeCard(number: String, mistake: String, why: String, solution: String) -> some View {
        HStack(alignment: .top, spacing: theme.spacing.sm) {
            Text(number)
                .font(.system(size: 20, weight: .black))
                .foregroundColor(.red)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(Color.red.opacity(0.15))
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(mistake)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(theme.text)

                HStack(alignment: .top, spacing: 4) {
                    Text("Why:")
                        .font(theme.fonts.caption)
                        .foregroundColor(.red)
                        .bold()

                    Text(why)
                        .font(theme.fonts.caption)
                        .foregroundColor(theme.textSecondary)
                }

                HStack(alignment: .top, spacing: 4) {
                    Text("Fix:")
                        .font(theme.fonts.caption)
                        .foregroundColor(.green)
                        .bold()

                    Text(solution)
                        .font(theme.fonts.caption)
                        .foregroundColor(theme.text)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(theme.spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.surface.opacity(0.5))
        )
    }

    private func testingCriteriaCard(aspect: String, goodSign: String, badSign: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(aspect)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(theme.primary)

            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.green)
                    .frame(width: 16, alignment: .center)

                Text(goodSign)
                    .font(theme.fonts.callout)
                    .foregroundColor(theme.textSecondary)
            }

            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.red)
                    .frame(width: 16, alignment: .center)

                Text(badSign)
                    .font(theme.fonts.callout)
                    .foregroundColor(theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(theme.spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.surface.opacity(0.5))
        )
    }
}

// MARK: - Preview
struct StickSelectionGuideView_Previews: PreviewProvider {
    static var previews: some View {
        StickSelectionGuideView(onLaunchAnalyzer: {
            print("Launch analyzer from preview")
        })
        .preferredColorScheme(.dark)
    }
}
