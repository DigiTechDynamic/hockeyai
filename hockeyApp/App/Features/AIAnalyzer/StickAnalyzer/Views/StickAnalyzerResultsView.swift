import SwiftUI
import AVFoundation

// MARK: - Stick Analyzer Results View
struct StickAnalyzerResultsView: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: StickAnalyzerViewModel
    
    let onComplete: ((StickAnalysisResult) -> Void)?
    
    // Animation states
    @State private var showSpecs = false
    @State private var showSticks = false
    @State private var showActions = false
    @State private var showRecommendations = false
    @StateObject private var monetization = MonetizationManager.shared
    
    var body: some View {
        ZStack {
            if let result = viewModel.analysisResult {
                ScrollView {
                    VStack(spacing: theme.spacing.xl) {
                        // Ideal Specifications
                        idealSpecsCard(result: result)
                            .opacity(showSpecs ? 1 : 0)
                            .offset(y: showSpecs ? 0 : 30)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.5), value: showSpecs)
                        
                        // Recommendations now live inside the card (dropdown),
                        // consistent with Shot Coach / Shot Rater cards.
                        
                        // Pro Upsell for non-premium users
                        if !monetization.isPremium {
                            ProUpsellCard(
                                title: "Unlock your full stick prescription",
                                subtitle: "See top matches and get personalized recommendations.",
                                bullets: [
                                    "Top model matches for your specs",
                                    "Why each choice works for you",
                                    "Unlimited re-analysis"
                                ],
                                source: "equipment_results",
                                onDismiss: { }
                            )
                        }

                        // Action buttons
                        actionButtons(result: result)
                            .opacity(showActions ? 1 : 0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(1.1), value: showActions)
                    }
                    .padding(theme.spacing.lg)
                    .padding(.bottom, theme.spacing.xl)
                }
            } else {
                // Loading state (shouldn't normally see this)
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: theme.primary))
            }
        }
        .background(theme.background)
        .onAppear {
            animateIn()
        }
    }
    
    // MARK: - Ideal Specs Card
    private func idealSpecsCard(result: StickAnalysisResult) -> some View {
        ZStack {
            // Glassmorphic background to match "Shot Analyzed" card style
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
                // Shot Coach-style analysis header (frames + confidence)
                analysisHeader(result: result)
                    .frame(maxWidth: .infinity)

                VStack(spacing: theme.spacing.md) {
                // Flex
                specRow(
                    label: "Flex",
                    value: result.recommendations.idealFlex.displayString,
                    current: nil,
                    icon: "arrow.up.and.down",
                    reason: result.recommendations.idealFlex.reasoning
                )

                // Length
                specRow(
                    label: "Length",
                    value: result.recommendations.idealLength.displayString,
                    current: nil,
                    icon: "ruler",
                    reason: result.recommendations.idealLength.reasoning
                )

                // Curve
                specRow(
                    label: "Curve",
                    value: result.recommendations.idealCurve.joined(separator: ", "),
                    current: nil,
                    icon: "waveform.path",
                    reason: result.recommendations.curveReasoning
                )

                // Kick Point
                specRow(
                    label: "Kick Point",
                    value: result.recommendations.idealKickPoint.rawValue,
                    current: nil,
                    icon: "point.topleft.down.curvedto.point.filled.bottomright.up",
                    reason: result.recommendations.kickPointReasoning
                )

                // Lie
                specRow(
                    label: "Lie",
                    value: String(result.recommendations.idealLie),
                    current: nil,
                    icon: "angle",
                    reason: result.recommendations.lieReasoning
                )
                
                // In-card dropdown for top 3 recommendations
                recommendationsDropdown(result: result)
            }
        }
            .padding(.vertical, 24)
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Shot Coach-style Header
    private func analysisHeader(result: StickAnalysisResult) -> some View {
        VStack(spacing: 6) {
            Text("STICK PRESCRIPTION")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(theme.textSecondary)
                .tracking(1.0)

            HStack(spacing: theme.spacing.md) {
                HStack(spacing: 4) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 12))
                    Text("\(framesAnalyzed(for: result.shotVideoURL)) frames")
                        .font(.system(size: 12))
                }

                Text("•")
                    .foregroundColor(theme.textSecondary.opacity(0.5))

                HStack(spacing: 4) {
                    Circle()
                        .fill(confidenceColor(result.confidence))
                        .frame(width: 6, height: 6)
                    Text("\(Int(result.confidence * 100))% confidence")
                        .font(.system(size: 12))
                }
            }
            .foregroundColor(theme.textSecondary.opacity(0.8))
        }
        .padding(.bottom, theme.spacing.md)
    }

    private func framesAnalyzed(for url: URL) -> Int {
        let asset = AVAsset(url: url)
        let durationSeconds = CMTimeGetSeconds(asset.duration)
        // Try to read nominal frame rate from the first video track
        if let track = asset.tracks(withMediaType: .video).first {
            let fps = track.nominalFrameRate
            if fps > 0 {
                return max(1, Int((durationSeconds * Double(fps)).rounded()))
            }
        }
        // Fallback to 30fps estimate
        return max(1, Int((durationSeconds * 30).rounded()))
    }

    private func confidenceColor(_ confidence: Double) -> Color {
        switch confidence {
        case 0.9...1.0: return .green
        case 0.7...0.89: return theme.primary
        case 0.5...0.69: return .orange
        default: return .red
        }
    }

    // MARK: - In-card Recommendations Dropdown
    private func recommendationsDropdown(result: StickAnalysisResult) -> some View {
        VStack(spacing: theme.spacing.sm) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showRecommendations.toggle()
                }
                HapticManager.shared.playImpact(style: .light)
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 18, weight: .bold))
                    Text(showRecommendations ? "Hide Recommendations" : "View Recommendations")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                    Spacer(minLength: 8)
                    Image(systemName: showRecommendations ? "chevron.up" : "chevron.down")
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
                                    theme.surface.opacity(0.85),
                                    theme.surface.opacity(0.65)
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
                                            theme.primary.opacity(0.3),
                                            theme.primary.opacity(0.1)
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

            if showRecommendations {
                VStack(alignment: .leading, spacing: theme.spacing.sm) {
                    ForEach(Array(topProfiles(result: result).prefix(3).enumerated()), id: \.offset) { index, profile in
                        compactProfileRow(profile: profile, rank: index + 1)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.top, theme.spacing.md)
    }

    private func topProfiles(result: StickAnalysisResult) -> [StickProfile] {
        if let profiles = result.recommendations.recommendedProfiles, !profiles.isEmpty {
            return profiles
        }

        // Map legacy sticks to profile-like rows as a fallback
        if !result.recommendations.topStickModels.isEmpty {
            return result.recommendations.topStickModels.map { stick in
                StickProfile(
                    name: stick.displayName,
                    flex: stick.flex,
                    curve: stick.curve,
                    kickPoint: stick.kickPoint.rawValue,
                    lie: Double(result.recommendations.idealLie),
                    matchScore: stick.matchScore,
                    bestFor: "",
                    whyItWorks: stick.reasoning,
                    strengths: nil,
                    tradeoffs: nil
                )
            }
        }

        // Generate default profiles based on ideal specs if no profiles or sticks provided
        let idealFlex = result.recommendations.idealFlex
        let curves = result.recommendations.idealCurve

        return [
            StickProfile(
                name: "Balanced Setup",
                flex: (idealFlex.min + idealFlex.max) / 2,
                curve: curves.first ?? "P92",
                kickPoint: result.recommendations.idealKickPoint.rawValue,
                lie: Double(result.recommendations.idealLie),
                matchScore: 95,
                bestFor: "All-around performance",
                whyItWorks: "Matches your ideal specifications for optimal performance",
                strengths: ["Balanced performance", "Versatile"],
                tradeoffs: nil
            ),
            StickProfile(
                name: "Quick Release",
                flex: idealFlex.min,
                curve: curves.count > 1 ? curves[1] : curves.first ?? "P29",
                kickPoint: "Low",
                lie: Double(result.recommendations.idealLie),
                matchScore: 90,
                bestFor: "Fast wrist shots",
                whyItWorks: "Lower flex for quickest possible release",
                strengths: ["Fastest release", "Easy loading"],
                tradeoffs: ["Less power on slap shots"]
            ),
            StickProfile(
                name: "Power Option",
                flex: idealFlex.max,
                curve: curves.last ?? "P90TM",
                kickPoint: result.recommendations.idealKickPoint == .low ? "Mid" : result.recommendations.idealKickPoint.rawValue,
                lie: Double(result.recommendations.idealLie),
                matchScore: 85,
                bestFor: "Maximum shot power",
                whyItWorks: "Stiffer flex for harder shots when needed",
                strengths: ["More power", "Better for slap shots"],
                tradeoffs: ["Slower release"]
            )
        ]
    }

    private func compactProfileRow(profile: StickProfile, rank: Int) -> some View {
        HStack(alignment: .top, spacing: theme.spacing.sm) {
            rankBadge(rank: rank)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(profile.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(theme.text)
                    Spacer()
                    Text("\(profile.matchScore)%")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(matchScoreColor(profile.matchScore))
                }
                HStack(spacing: 6) {
                    specTag("Flex \(profile.flex)")
                    specTag(profile.curve)
                    specTag(profile.kickPoint.capitalized)
                    specTag("Lie \(Int(profile.lie))")
                }
                if !profile.whyItWorks.isEmpty {
                    Text(profile.whyItWorks)
                        .font(.system(size: 12))
                        .foregroundColor(theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surface.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(theme.divider.opacity(0.6), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Spec Row
    private func specRow(label: String, value: String, current: String?, icon: String, reason: String?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(theme.primary)
                    .frame(width: 24)
                
                Text(label)
                    .font(theme.fonts.body)
                    .foregroundColor(theme.textSecondary)
                    .frame(width: 80, alignment: .leading)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    // Show a friendly placeholder when the value is empty
                    Text(value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "--" : value)
                        .font(theme.fonts.bodyBold)
                        .foregroundColor(value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? theme.textSecondary.opacity(0.6) : theme.primary)
                    
                    if let current = current, !current.isEmpty && current != "Unknown" {
                        Text("Currently: \(current)")
                            .font(.system(size: 11))
                            .foregroundColor(theme.textSecondary)
                    }
                }
            }
            if let reason = reason, !reason.isEmpty {
                Text(reason)
                    .font(.system(size: 12))
                    .foregroundColor(theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
            }
        }
    }
    
    // MARK: - Recommended Sticks Section
    private func recommendedSticksSection(result: StickAnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(theme.primary)
                Text(result.recommendations.recommendedProfiles?.isEmpty == false ? "Recommended Profiles" : "Recommended Sticks")
                    .font(theme.fonts.headline)
                    .foregroundColor(theme.text)
            }

            if let profiles = result.recommendations.recommendedProfiles, !profiles.isEmpty {
                VStack(spacing: theme.spacing.md) {
                    ForEach(Array(profiles.enumerated()), id: \.offset) { index, profile in
                        profileCard(profile: profile, rank: index + 1)
                    }
                }
            } else {
                VStack(spacing: theme.spacing.md) {
                    ForEach(Array(result.recommendations.topStickModels.enumerated()), id: \.offset) { index, stick in
                        stickCard(stick: stick, rank: index + 1)
                    }
                }
            }
        }
    }

    // MARK: - Generic Profile Card
    private func profileCard(profile: StickProfile, rank: Int) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            // Header row: rank + name + match
            HStack(alignment: .top) {
                rankBadge(rank: rank)
                Text(profile.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(theme.text)
                Spacer()
                Text("\(profile.matchScore)%")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(matchScoreColor(profile.matchScore))
            }

            // Spec tags row
            HStack(spacing: 6) {
                specTag("Flex \(profile.flex)")
                specTag(profile.curve)
                specTag(profile.kickPoint.capitalized)
                specTag("Lie \(Int(profile.lie))")
            }

            // Best for
            if !profile.bestFor.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "target")
                        .foregroundColor(theme.accent)
                        .font(.system(size: 12))
                    Text(profile.bestFor)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(theme.text)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // Why it works
            if !profile.whyItWorks.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(theme.accent)
                        .font(.system(size: 12))
                    Text(profile.whyItWorks)
                        .font(.system(size: 13))
                        .foregroundColor(theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // Strengths bullets
            if let strengths = profile.strengths, !strengths.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 12))
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(strengths.prefix(2), id: \.self) { s in
                            Text(s)
                                .font(.system(size: 12))
                                .foregroundColor(theme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }

            // Tradeoffs bullet
            if let tradeoffs = profile.tradeoffs, let t = tradeoffs.first, !t.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 12))
                    Text(t)
                        .font(.system(size: 12))
                        .foregroundColor(theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(theme.spacing.md)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .fill(rank == 1 ? theme.primary.opacity(0.08) : theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: theme.cornerRadius)
                        .stroke(
                            rank == 1 ? theme.primary : theme.divider,
                            lineWidth: rank == 1 ? 1.5 : 1
                        )
                )
        )
    }

    // Helpers for card UI
    private func rankBadge(rank: Int) -> some View {
        ZStack {
            Circle().fill(rank == 1 ? Color.yellow : theme.surface)
                .frame(width: 28, height: 28)
            Text("#\(rank)")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(rank == 1 ? .black : theme.text)
        }
    }

    private func specTag(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(theme.text)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule().fill(theme.surface.opacity(0.5))
            )
            .overlay(
                Capsule().stroke(theme.divider.opacity(0.6), lineWidth: 1)
            )
    }
    
    // MARK: - Stick Card
    private func stickCard(stick: RecommendedStick, rank: Int) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            HStack {
                // Rank badge
                ZStack {
                    Circle()
                        .fill(rank == 1 ? Color.yellow : theme.surface)
                        .frame(width: 32, height: 32)
                    
                    Text("#\(rank)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(rank == 1 ? .black : theme.text)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(stick.displayName)
                        .font(theme.fonts.bodyBold)
                        .foregroundColor(theme.text)
                    
                    HStack(spacing: theme.spacing.xs) {
                        Text("Flex \(stick.flex)")
                        Text("•")
                        Text(stick.curve)
                        Text("•")
                        Text(stick.kickPoint.rawValue)
                    }
                    .font(.system(size: 12))
                    .foregroundColor(theme.textSecondary)
                }
                
                Spacer()
                
                // Match score
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(stick.matchScore)%")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(matchScoreColor(stick.matchScore))
                    
                    Text("match")
                        .font(.system(size: 10))
                        .foregroundColor(theme.textSecondary)
                        .textCase(.uppercase)
                }
            }
            
            Text(stick.reasoning)
                .font(theme.fonts.caption)
                .foregroundColor(theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            
            if let price = stick.price {
                HStack {
                    Image(systemName: "tag")
                        .font(.system(size: 12))
                    Text(price)
                        .font(theme.fonts.caption)
                }
                .foregroundColor(theme.primary)
            }
        }
        .padding(theme.spacing.md)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .fill(rank == 1 ? theme.primary.opacity(0.1) : theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: theme.cornerRadius)
                        .stroke(rank == 1 ? theme.primary : theme.divider, lineWidth: rank == 1 ? 2 : 1)
                )
        )
    }
    
    // Comparison notes removed per new design
    
    // MARK: - Action Buttons
    private func actionButtons(result: StickAnalysisResult) -> some View {
        Button(action: {
            HapticManager.shared.playImpact(style: .medium)
            dismiss()
        }) {
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
                                        theme.primary.opacity(0.6),
                                        theme.primary.opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )

                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 20, weight: .medium))
                    Text("Done")
                        .font(.system(size: 16, weight: .semibold))
                        .tracking(0.5)
                }
                .foregroundColor(theme.text)
            }
            .frame(height: 56)
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Helpers
    private func animateIn() {
        withAnimation(.easeOut(duration: 0.3)) {
            showSpecs = true
        }
        withAnimation(.easeOut(duration: 0.3).delay(0.1)) {
            showSticks = true
        }
        withAnimation(.easeOut(duration: 0.3).delay(0.2)) {
            showActions = true
        }
    }
    
    private func matchScoreColor(_ score: Int) -> Color {
        switch score {
        case 90...100:
            return .green
        case 75...89:
            return theme.primary
        case 60...74:
            return .orange
        default:
            return .red
        }
    }
    
    private func shareResults(_ result: StickAnalysisResult) {
        // Implement share functionality
        let shareText = """
        My AI Stick Prescription 🏒
        
        Ideal Specs:
        • Flex: \(result.recommendations.idealFlex.displayString)
        • Length: \(result.recommendations.idealLength.displayString)
        • Curve: \(result.recommendations.idealCurve.joined(separator: ", "))
        • Kick Point: \(result.recommendations.idealKickPoint.rawValue)
        • Lie: \(result.recommendations.idealLie)
        
        Top Recommendation:
        \(result.recommendations.topStickModels.first?.displayName ?? "N/A")
        
        Generated with SnapHockey
        """
        
        // In production, this would open a share sheet
        print(shareText)
    }
}
