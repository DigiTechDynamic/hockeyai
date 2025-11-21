import SwiftUI

// MARK: - AI Coach Results View (Unified Card Design)
/// Single cohesive card with organized sections and collapsible coaching guide
struct AICoachFlowResultsView: View {
    let analysisResult: AICoachAnalysisResult
    let onAnalyzeNext: () -> Void
    let onExit: () -> Void

    @Environment(\.theme) var theme
    @State private var showCoachingGuide = false
    @StateObject private var monetization = MonetizationManager.shared

    var body: some View {
        ZStack {
            Color(theme.background)
                .ignoresSafeArea(.all)

            ScrollView {
                VStack(spacing: theme.spacing.xl) {
                    // Main Analysis Card
                    analysisCard
                        .padding(.horizontal, theme.spacing.lg)
                        .padding(.top, theme.spacing.sm)

                    // Pro Upsell
                    if !monetization.isPremium {
                        ProUpsellCard(
                            title: "Unlock Advanced Coaching",
                            subtitle: "Get detailed breakdowns and personalized drill progressions",
                            bullets: [
                                "Complete biomechanical analysis",
                                "Video-based drill demonstrations",
                                "Progress tracking over time"
                            ],
                            source: "ai_coach_results",
                            onDismiss: { }
                        )
                        .padding(.horizontal, theme.spacing.lg)
                    }

                    // Action button
                    actionButton
                        .padding(.horizontal, theme.spacing.lg)
                        .padding(.bottom, theme.spacing.xl)
                }
            }
        }
        .trackScreen("ai_coach_results")
    }

    // MARK: - Unified Analysis Card
    private var analysisCard: some View {
        ZStack {
            // Glassmorphic background
            RoundedRectangle(cornerRadius: 28)
                .fill(
                    LinearGradient(
                        colors: [
                            theme.surface.opacity(0.95),
                            theme.surface.opacity(0.85)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Material.ultraThin)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.05),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .center
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    theme.primary.opacity(0.3),
                                    theme.primary.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: theme.primary.opacity(0.1), radius: 20, x: 0, y: 10)

            VStack(alignment: .leading, spacing: theme.spacing.md) {
                // Header
                analysisHeader
                    .frame(maxWidth: .infinity)

                Divider()
                    .background(theme.divider.opacity(0.3))
                    .padding(.vertical, 4)

                // What We Saw
                whatWeSawSection

                Divider()
                    .background(theme.divider.opacity(0.3))
                    .padding(.vertical, 4)

                // Strengths & Areas to Develop
                metricsSection

                Divider()
                    .background(theme.divider.opacity(0.3))
                    .padding(.vertical, 4)

                // Primary Focus
                primaryFocusIndicator

                // Coaching Guide Dropdown
                coachingGuideDropdown
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Analysis Header
    private var analysisHeader: some View {
        VStack(spacing: 6) {
            Text("\(analysisResult.shotType.displayName.uppercased()) ANALYZED")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(theme.textSecondary)
                .tracking(1.0)

            HStack(spacing: theme.spacing.md) {
                HStack(spacing: 4) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 12))
                    Text("\(analysisResult.framesAnalyzed) frames")
                        .font(.system(size: 12))
                }

                Text("•")
                    .foregroundColor(theme.textSecondary.opacity(0.5))

                HStack(spacing: 4) {
                    Image(systemName: "video.fill")
                        .font(.system(size: 12))
                    Text("2 angles")
                        .font(.system(size: 12))
                }

                Text("•")
                    .foregroundColor(theme.textSecondary.opacity(0.5))

                HStack(spacing: 4) {
                    Circle()
                        .fill(confidenceColor)
                        .frame(width: 6, height: 6)
                    Text(confidenceLabel)
                        .font(.system(size: 12))
                }
            }
            .foregroundColor(theme.textSecondary.opacity(0.8))
        }
    }

    // MARK: - What We Saw Section
    private var whatWeSawSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "eye.fill")
                    .font(.system(size: 12))
                    .foregroundColor(theme.primary)
                Text("What We Saw")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(theme.textSecondary)
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(analysisResult.response.video_context.items, id: \.text) { item in
                    HStack(spacing: 6) {
                        Text("•")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(theme.primary.opacity(0.6))
                        Text(item.text)
                            .font(.system(size: 11))
                            .foregroundColor(theme.text.opacity(0.9))
                        Spacer()
                    }
                }
            }
        }
    }

    // MARK: - Metrics Section (Strengths & Areas to Develop)
    private var metricsSection: some View {
        let categorized = categorizeMetrics()

        return VStack(alignment: .leading, spacing: theme.spacing.lg) {
            // Strengths section
            if !categorized.strengths.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 6) {
                        Text("✓")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(theme.success)
                        Text("Strengths")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(theme.textSecondary)
                    }

                    VStack(spacing: 14) {
                        ForEach(categorized.strengths, id: \.label) { metric in
                            metricRow(
                                label: metric.label,
                                reasoning: metric.reasoning
                            )
                        }
                    }
                    .padding(.leading, 4)
                }
            }

            // Areas to develop section
            if !categorized.areasToImprove.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 6) {
                        Text("⚠")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(theme.warning)
                        Text("Areas to Develop")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(theme.textSecondary)
                    }

                    VStack(spacing: 14) {
                        ForEach(categorized.areasToImprove, id: \.label) { metric in
                            metricRow(
                                label: metric.label,
                                reasoning: metric.reasoning
                            )
                        }
                    }
                    .padding(.leading, 4)
                }
            }
        }
    }

    // MARK: - Metric Row (Minimal with Bullet)
    private func metricRow(label: String, reasoning: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text("•")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(theme.primary.opacity(0.6))

                Text(label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.text)
            }

            Text(reasoning)
                .font(.system(size: 12))
                .foregroundColor(theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(3)
                .padding(.leading, 24)
        }
    }

    // MARK: - Primary Focus Indicator
    private var primaryFocusIndicator: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "target")
                    .font(.system(size: 12))
                    .foregroundColor(theme.warning)
                Text("Your #1 Priority")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(theme.textSecondary)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(analysisResult.biomechanics.focusArea.metric.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(theme.text)

                Text(analysisResult.biomechanics.focusArea.specificIssue)
                    .font(.system(size: 12))
                    .foregroundColor(theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Coaching Guide Dropdown
    private var coachingGuideDropdown: some View {
        VStack(spacing: theme.spacing.sm) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showCoachingGuide.toggle()
                }
                HapticManager.shared.playImpact(style: .light)
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 18, weight: .bold))
                    Text(showCoachingGuide ? "Hide Coaching Guide" : "View Coaching Guide")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                    Spacer(minLength: 8)
                    Image(systemName: showCoachingGuide ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.textSecondary)
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [
                                    theme.warning.opacity(0.15),
                                    theme.warning.opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            theme.warning.opacity(0.4),
                                            theme.warning.opacity(0.2)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                )
                .foregroundColor(theme.text)
            }
            .buttonStyle(PlainButtonStyle())

            if showCoachingGuide {
                VStack(alignment: .leading, spacing: theme.spacing.md) {
                    // Why it matters
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Why This Matters")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(theme.textSecondary.opacity(0.7))
                            .tracking(0.5)

                        Text(analysisResult.biomechanics.focusArea.whyItMatters)
                            .font(.system(size: 13))
                            .foregroundColor(theme.text.opacity(0.9))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // How to improve
                    VStack(alignment: .leading, spacing: theme.spacing.sm) {
                        Text("HOW TO IMPROVE")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(theme.textSecondary.opacity(0.7))
                            .tracking(0.5)

                        ProgressiveCoachingSteps(
                            fullText: analysisResult.biomechanics.focusArea.howToImprove ?? analysisResult.biomechanics.focusArea.improvementTip
                        )
                    }

                    // Coaching cues
                    if !analysisResult.biomechanics.focusArea.coachingCues.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("KEY COACHING CUES")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(theme.textSecondary.opacity(0.7))
                                .tracking(0.5)

                            ForEach(analysisResult.biomechanics.focusArea.coachingCues, id: \.self) { cue in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•")
                                        .foregroundColor(theme.primary)
                                        .font(.system(size: 16, weight: .bold))
                                    Text(cue)
                                        .font(.system(size: 13))
                                        .foregroundColor(theme.text)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }

                    // Practice drill
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "figure.hockey")
                                .font(.system(size: 12))
                                .foregroundColor(theme.accent)
                            Text("PRACTICE DRILL")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(theme.textSecondary.opacity(0.7))
                                .tracking(0.5)
                        }

                        Text(analysisResult.biomechanics.focusArea.drill)
                            .font(.system(size: 13))
                            .foregroundColor(theme.text)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(4)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(theme.accent.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(theme.accent.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                .padding(.top, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.top, theme.spacing.sm)
    }

    // MARK: - Action Button
    private var actionButton: some View {
        Button(action: {
            HapticManager.shared.playImpact(style: .medium)
            onAnalyzeNext()
        }) {
            HStack(spacing: 10) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 20, weight: .medium))
                Text("Analyze Another Shot")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(theme.text)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
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
            )
        }
    }

    // MARK: - Helper Methods

    private var confidenceColor: Color {
        switch analysisResult.confidence {
        case 0.85...1.0: return theme.success
        case 0.70...0.849: return theme.primary
        default: return theme.warning
        }
    }

    private var confidenceLabel: String {
        switch analysisResult.confidence {
        case 0.85...1.0: return "High confidence"
        case 0.70...0.849: return "Good confidence"
        default: return "Moderate confidence"
        }
    }

    private func categorizeMetrics() -> (strengths: [MetricDisplay], areasToImprove: [MetricDisplay]) {
        let allMetrics: [MetricDisplay] = [
            MetricDisplay(
                label: "Stance",
                icon: "figure.stand",
                score: analysisResult.biomechanics.stance.score,
                reasoning: analysisResult.response.metric_reasoning.stance
            ),
            MetricDisplay(
                label: "Balance",
                icon: "scalemass.fill",
                score: analysisResult.biomechanics.balance.score,
                reasoning: analysisResult.response.metric_reasoning.balance
            ),
            MetricDisplay(
                label: "Power",
                icon: "bolt.fill",
                score: analysisResult.biomechanics.explosivePower.score,
                reasoning: analysisResult.response.metric_reasoning.power
            ),
            MetricDisplay(
                label: "Release",
                icon: "target",
                score: analysisResult.biomechanics.releasePoint.score,
                reasoning: analysisResult.response.metric_reasoning.release
            ),
            MetricDisplay(
                label: "Follow Through",
                icon: "arrow.right.circle.fill",
                score: analysisResult.biomechanics.followThrough.score,
                reasoning: analysisResult.response.metric_reasoning.follow_through
            )
        ]

        let strengths = allMetrics.filter { $0.score >= 80 }
        let areasToImprove = allMetrics.filter { $0.score < 80 }

        return (strengths, areasToImprove)
    }
}

// MARK: - Metric Display Model
struct MetricDisplay {
    let label: String
    let icon: String
    let score: Int
    let reasoning: String
}

// MARK: - Progressive Coaching Steps Component
struct ProgressiveCoachingSteps: View {
    let fullText: String
    @Environment(\.theme) var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            if let steps = parseSteps(from: fullText), !steps.isEmpty {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    CoachingStepCard(
                        stepNumber: index + 1,
                        title: step.title,
                        description: step.description
                    )
                }
            } else {
                ForEach(Array(chunkText(fullText).enumerated()), id: \.offset) { index, chunk in
                    CoachingStepCard(
                        stepNumber: index + 1,
                        title: chunkTitle(for: index),
                        description: chunk
                    )
                }
            }
        }
    }

    private func parseSteps(from text: String) -> [(title: String, description: String)]? {
        var steps: [(String, String)] = []

        // Look for numbered patterns like "(1)", "(2)", "(3)"
        let numberedPattern = #"\((\d+)\)\s*([^:]+):\s*([^(]+)"#
        if let regex = try? NSRegularExpression(pattern: numberedPattern) {
            let nsString = text as NSString
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))

            for match in matches {
                if match.numberOfRanges >= 4 {
                    let stepNum = nsString.substring(with: match.range(at: 1))
                    let stepType = nsString.substring(with: match.range(at: 2)).trimmingCharacters(in: .whitespaces)
                    let stepDesc = nsString.substring(with: match.range(at: 3)).trimmingCharacters(in: .whitespaces)

                    let title: String
                    if stepType.lowercased().contains("without") || stepType.lowercased().contains("no puck") {
                        title = "Step 1: No Puck"
                    } else if stepType.lowercased().contains("stick") && (stepType.lowercased().contains("no puck") || !stepType.lowercased().contains("puck")) {
                        title = "Step 2: Stick Only"
                    } else if stepType.lowercased().contains("puck") {
                        title = "Step 3: With Puck"
                    } else {
                        title = "Step \(stepNum): \(stepType.capitalized)"
                    }

                    steps.append((title, stepDesc))
                }
            }
        }

        if steps.count >= 2 {
            return steps
        }

        // Fallback: Look for sentence-based progressive indicators
        steps = []
        let sentences = text.components(separatedBy: ". ")
        var currentStep = ""
        var stepTitle = ""

        for sentence in sentences {
            let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }

            let lower = trimmed.lowercased()

            if lower.starts(with: "start by") || lower.starts(with: "first") || lower.contains("without a puck") {
                if !currentStep.isEmpty {
                    steps.append((stepTitle, currentStep))
                }
                stepTitle = "Step 1: No Puck"
                currentStep = trimmed
            } else if lower.contains("with stick") || lower.contains("add your stick") || lower.contains("integrate your stick") {
                if !currentStep.isEmpty {
                    steps.append((stepTitle, currentStep))
                }
                stepTitle = "Step 2: Stick Only"
                currentStep = trimmed
            } else if lower.starts(with: "finally") || lower.contains("with a puck") || lower.contains("apply this") {
                if !currentStep.isEmpty {
                    steps.append((stepTitle, currentStep))
                }
                stepTitle = "Step 3: With Puck"
                currentStep = trimmed
            } else {
                if !currentStep.isEmpty {
                    currentStep += ". " + trimmed
                } else {
                    currentStep = trimmed
                }
            }
        }

        if !currentStep.isEmpty {
            steps.append((stepTitle, currentStep))
        }

        return steps.count >= 2 ? steps : nil
    }

    private func chunkText(_ text: String) -> [String] {
        let sentences = text.components(separatedBy: ". ").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        guard sentences.count >= 3 else {
            return [text]
        }

        let chunkSize = sentences.count / 3
        var chunks: [String] = []

        let chunk1 = sentences[0..<min(chunkSize, sentences.count)].joined(separator: ". ") + "."
        chunks.append(chunk1)

        if chunkSize < sentences.count {
            let chunk2 = sentences[chunkSize..<min(chunkSize * 2, sentences.count)].joined(separator: ". ") + "."
            chunks.append(chunk2)
        }

        if chunkSize * 2 < sentences.count {
            let chunk3 = sentences[(chunkSize * 2)...].joined(separator: ". ")
            chunks.append(chunk3.hasSuffix(".") ? chunk3 : chunk3 + ".")
        }

        return chunks.filter { !$0.isEmpty }
    }

    private func chunkTitle(for index: Int) -> String {
        switch index {
        case 0: return "Step 1: Foundation"
        case 1: return "Step 2: Add Movement"
        case 2: return "Step 3: Full Execution"
        default: return "Step \(index + 1)"
        }
    }
}

// MARK: - Coaching Step Card
struct CoachingStepCard: View {
    let stepNumber: Int
    let title: String
    let description: String
    @Environment(\.theme) var theme

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(stepColor.opacity(0.15))
                    .frame(width: 32, height: 32)

                Text("\(stepNumber)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(stepColor)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(theme.text)

                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(theme.text.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(4)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(theme.surface.opacity(0.5))
        )
    }

    private var stepColor: Color {
        switch stepNumber {
        case 1: return .blue
        case 2: return .purple
        case 3: return .green
        default: return .gray
        }
    }
}
