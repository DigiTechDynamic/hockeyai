import SwiftUI

// MARK: - Shot Rater Results View
struct ShotRaterResultsView: View {
    @Environment(\.theme) var theme
    let analysisResult: ShotAnalysisResult?
    let onExit: () -> Void
    
    @AppStorage("showRawAnalyzerSections") private var showRawAnalyzerSections = false
    @State private var showRawInspector = false
    @State private var showContent = false
    @State private var progressAnimation = false
    @State private var starAnimations = [Bool](repeating: false, count: 5)
    @State private var particleTrigger = false
    @State private var showFrameAnalysisToggle = false
    @StateObject private var monetization = MonetizationManager.shared
    
    var body: some View {
        ZStack {
            // Unified themed background for visual consistency
            ThemedBackground()

            ScrollView {
            VStack(spacing: theme.spacing.xl) {
                // Current Shot Result
                if let result = analysisResult {
                    currentShotCard(result)
                        .onAppear {
                            print("🔍 [ShotResultsView] Showing result: type=\(result.type), hasMetadata=\(result.analysisMetadata != nil)")
                        }
                }
                
                // Pro Upsell for non-premium users
                if !monetization.isPremium {
                    ProUpsellCard(
                        title: "Unlock full breakdown",
                        subtitle: "Get detailed technique tips, unlimited analyses, and history.",
                        bullets: [
                            "Advanced metrics and insights",
                            "Unlimited AI analyses",
                            "Saved history and progress"
                        ],
                        source: "ShotRater_results",
                        onDismiss: { }
                    )
                }
                // Frame-by-Frame Debug Analysis - Removed for video upload approach
                // Previously showed extracted frames in debug mode
                
                // Action Buttons
                actionButtonsSection

            }
            .padding()
            }
            // Background now provided by ThemedBackground()
            .onAppear {
                withAnimation(.easeOut(duration: 0.5)) {
                    showContent = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    triggerProgressAnimations()
                }
                
                if analysisResult?.overallScore ?? 0 >= 80 {
                    particleTrigger = true
                }
                
                // Frame analysis toggle removed - using video upload approach
            }
            .overlay(
                particleTrigger ? celebrationParticles : nil
            )

            // Debug toggle removed - using video upload approach
        }
        // Deep link state now managed by NotificationKit
    }
    
    
    // MARK: - Gradient Styles
    private var glassmorphicBackground: some ShapeStyle {
        LinearGradient(
            colors: [
                theme.surface.opacity(0.95),
                theme.surface.opacity(0.8),
                Color.black.opacity(0.85)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var glassmorphicOverlay: some ShapeStyle {
        LinearGradient(
            colors: [
                Color.white.opacity(0.1),
                Color.white.opacity(0.02)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var glassmorphicStroke: some ShapeStyle {
        LinearGradient(
            colors: [
                theme.primary.opacity(0.6),
                theme.accent.opacity(0.3)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Current Shot Card
    private func currentShotCard(_ result: ShotAnalysisResult) -> some View {
        cardContainer {
            VStack(spacing: theme.spacing.lg) {
                // Always show regular shot analysis
                regularShotAnalysisView(result)

                // Raw inspector button relocated below Done
            }
            .padding(theme.spacing.xl)
        }
        .scaleEffect(showContent ? 1.0 : 0.95)
        .opacity(showContent ? 1.0 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.4), value: showContent)
    }
    
    // MARK: - Card Container
    @ViewBuilder
    private func cardContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack {
            // Glassmorphism background
            RoundedRectangle(cornerRadius: 20)
                .fill(glassmorphicBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(glassmorphicOverlay)
                        .blur(radius: 20)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(glassmorphicStroke, lineWidth: 2)
                )
                .shadow(color: theme.primary.opacity(0.4), radius: 25)
            
            content()
        }
    }
    
    // MARK: - Regular Shot Analysis View
    private func regularShotAnalysisView(_ result: ShotAnalysisResult) -> some View {
        VStack(spacing: theme.spacing.xl) {
            // Shot Type Header
            shotTypeHeader(result)
            
            // Overall Score Circle (only show if we have a score)
            if let overallScore = result.overallScore {
                scoreCircleView(score: overallScore)
                    .onAppear {
                        print("📊 [ShotResultsView] Displaying score: \(overallScore)")
                    }
            } else {
                Text("Score not available")
                    .foregroundColor(theme.textSecondary)
                    .onAppear {
                        print("⚠️ [ShotResultsView] No score available in result")
                    }
            }
            
            // Metrics - Show compact metric cards
            compactMetricsView(result)
            
            // Why this score section (short summary)
            whyThisScoreSection(result)
        }
    }
    
    // MARK: - Shot Type Header
    private func shotTypeHeader(_ result: ShotAnalysisResult) -> some View {
        HStack {
            Text(result.type.displayName)
                .font(theme.fonts.headline)
                .foregroundColor(theme.text)

            Spacer()

            // Star Rating (only show if we have a rating)
            if let starRating = result.starRating {
                starRatingView(rating: starRating)
            }
        }
    }
    
    // MARK: - Star Rating View
    private func starRatingView(rating: Int) -> some View {
        HStack(spacing: 3) {
            ForEach(0..<5) { index in
                Image(systemName: index < rating ? "star.fill" : "star")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(index < rating ? theme.primary : theme.textSecondary.opacity(0.3))
                    .scaleEffect(starAnimations[index] ? 1.3 : 1.0)
                    .rotationEffect(.degrees(starAnimations[index] ? 360 : 0))
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.6)
                        .delay(Double(index) * 0.1),
                        value: starAnimations[index]
                    )
            }
        }
    }
    
    // MARK: - Score Circle View
    private func scoreCircleView(score: Int) -> some View {
        ZStack {
            // Background circle with gradient
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            theme.surface.opacity(0.15),
                            theme.surface.opacity(0.05)
                        ]),
                        center: .center,
                        startRadius: 50,
                        endRadius: 100
                    )
                )
                .frame(width: 180, height: 180)
            
            // Background circle stroke
            Circle()
                .stroke(theme.surface.opacity(0.2), lineWidth: 8)
                .frame(width: 160, height: 160)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: progressAnimation ? CGFloat(score) / 100 : 0)
                .stroke(
                    LinearGradient(
                        colors: [theme.primary, theme.accent],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 160, height: 160)
                .rotationEffect(.degrees(-90))
                .shadow(color: theme.primary.opacity(0.4), radius: 10)
                .animation(.spring(response: 1.0, dampingFraction: 0.7), value: progressAnimation)
            
            // Score text (brand glow style)
            VStack(spacing: 0) {
                Text("\(score)")
                    .font(.system(size: 60, weight: .heavy))
                    .glowingHeaderText()
                    .scaleEffect(progressAnimation ? 1.0 : 0.5)
                    .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.5), value: progressAnimation)
                    .onAppear {
                        print("🔢 [ShotResultsView] Score text displaying: \(score), animation: \(progressAnimation)")
                    }
                
                Text("/100")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(theme.textSecondary.opacity(0.7))
                    .offset(y: -4)
            }
        }
        .padding(.vertical, theme.spacing.md)
        .scaleEffect(showContent ? 1.0 : 0.8)
        .opacity(showContent ? 1.0 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3), value: showContent)
    }
    
    // MARK: - Score Progress Circle
    private func scoreProgressCircle(score: Int) -> some View {
        Circle()
            .trim(from: 0, to: progressAnimation ? CGFloat(score) / 100 : 0)
            .stroke(
                AngularGradient(
                    colors: [
                        theme.primary,
                        theme.accent,
                        theme.accent,
                        theme.primary
                    ],
                    center: .center
                ),
                style: StrokeStyle(lineWidth: 12, lineCap: .round)
            )
            .frame(width: 140, height: 140)
            .rotationEffect(.degrees(-90))
            .shadow(color: theme.primary.opacity(0.6), radius: 15)
            .animation(.spring(response: 1.0, dampingFraction: 0.7), value: progressAnimation)
    }
    
    // MARK: - Compact Metrics View
    private func compactMetricsView(_ result: ShotAnalysisResult) -> some View {
        HStack(spacing: theme.spacing.md) {
            // Technique metric card
            if let techniqueScore = result.metrics.technique.score {
                metricCard(
                    title: "Technique",
                    score: techniqueScore,
                    icon: "star",
                    color: theme.primary
                )
            }
            
            // Power metric card
            if let powerScore = result.metrics.power.score {
                metricCard(
                    title: "Power",
                    score: powerScore,
                    icon: "bolt",
                    color: theme.accent
                )
            }
        }
    }
    
    // MARK: - Metric Card
    private func metricCard(title: String, score: Int, icon: String, color: Color) -> some View {
        VStack(spacing: theme.spacing.xs) {
            HStack(spacing: theme.spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.textSecondary)
            }
            
            Text("\(score)")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(theme.text)
            
            // Mini progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(theme.surface.opacity(0.2))
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(score) / 100, height: 4)
                }
            }
            .frame(height: 4)
        }
        .frame(maxWidth: .infinity)
        .padding(theme.spacing.md)
        .background(theme.surface.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Why This Score Section
    private func whyThisScoreSection(_ result: ShotAnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            Text("Why this score?")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(theme.text)

            Text(whyText(for: result))
                .font(.system(size: 14))
                .foregroundColor(theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func whyText(for result: ShotAnalysisResult) -> String {
        // Use the tips text directly
        let text = result.tips.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.contains("\"sections\":") || text.contains("{") { // crude guard if JSON leaked
            if let score = result.overallScore, let t = result.metrics.technique.score, let p = result.metrics.power.score {
                return "Technique \(t)/100. Power \(p)/100. Overall \(score)/100."
            }
            return "Analysis complete. See score and metrics above."
        }
        return text
    }
    
    
    // MARK: - Full Tips View (Always shows detailed analysis)
    private func fullTipsView(_ result: ShotAnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            Label("Detailed Analysis", systemImage: "lightbulb.fill")
                .font(theme.fonts.bodyBold)
                .foregroundColor(theme.primary)
            
            // Show the detailed part (after |||) or full tips if no separator
            Text(result.tips.components(separatedBy: "|||").last ?? result.tips)
                .font(theme.fonts.body)
                .foregroundColor(theme.text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(theme.surface.opacity(0.5))
        .cornerRadius(AppSettings.Constants.Layout.cornerRadiusMedium)
    }
    
    
    
    // Type mismatch view removed - always analyze as selected type
    /*
    private func typeMismatchView(_ result: ShotAnalysisResult) -> some View {
        // Removed - now we always analyze as the selected shot type
        EmptyView()
    }
    */
    
    
    
    // MARK: - Action Buttons
    private var actionButtonsSection: some View {
        Button {
            onExit()
        } label: {
            ZStack {
                // Glassmorphic background matching AI Coach style
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                theme.surface.opacity(0.8),
                                theme.surface.opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        theme.success.opacity(0.6),
                                        theme.success.opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                
                Text("Done")
                    .font(.system(size: 16, weight: .semibold))
                    .tracking(0.5)
                    .foregroundColor(theme.text)
            }
            .frame(height: 56)
            .frame(maxWidth: .infinity)
        }
        .padding(.top, theme.spacing.lg)
    }
    
    
    // MARK: - Helper Functions
    private func triggerProgressAnimations() {
        withAnimation {
            progressAnimation = true
        }
        
        // Animate stars
        if let starRating = analysisResult?.starRating {
            for i in 0..<starRating {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.15) {
                    withAnimation {
                        starAnimations[i] = true
                    }
                }
            }
        }
    }
    
    // MARK: - Celebration Particles
    @ViewBuilder
    private var celebrationParticles: some View {
        if particleTrigger {
            BackgroundAnimationView(
                type: .particles,
                isActive: true,
                intensity: 0.8
            )
            .allowsHitTesting(false)
            .opacity(0.5)
            .animation(.easeOut(duration: 3.0), value: particleTrigger)
        }
    }
    
}



// MARK: - Metric Row Component
private struct MetricRow: View {
    @Environment(\.theme) var theme
    let name: String
    let score: Int
    let icon: String
    
    @State private var animateBar = false
    
    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(getMetricColor(score).opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(getMetricColor(score))
            }
            
            Text(name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(theme.text)
            
            Spacer()
            
            // Progress Bar with gradient
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(theme.surface.opacity(0.3))
                        .frame(height: 10)
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [
                                    getMetricColor(score),
                                    getMetricColor(score).opacity(0.7)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: animateBar ? geometry.size.width * CGFloat(score) / 100 : 0, height: 10)
                        .shadow(color: getMetricColor(score).opacity(0.5), radius: 8)
                        .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3), value: animateBar)
                }
            }
            .frame(width: 100, height: 10)
            
            Text("\(score)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(getMetricColor(score))
                .frame(width: 35, alignment: .trailing)
        }
        .onAppear {
            animateBar = true
        }
    }
    
    private func getMetricColor(_ value: Int) -> Color {
        switch value {
        case 80...100: return theme.primary
        case 60..<80: return Color.yellow
        default: return Color.red
        }
    }
}
