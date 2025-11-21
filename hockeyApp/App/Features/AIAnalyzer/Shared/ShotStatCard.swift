import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Shot Stat Card
/// Card component for displaying shot statistics in AI Coach view
struct ShotStatCard: View {
    @Environment(\.theme) var theme
    @StateObject private var monetization = MonetizationManager.shared
    
    let type: ShotType
    let analysisResult: ShotAnalysisResult?
    let isAnalyzing: Bool
    let onStart: () -> Void
    let onOpenResults: (() -> Void)?
    let onAnalyzeAgain: (() -> Void)?
    let onCancel: (() -> Void)?

    @State private var showCancelConfirm = false
    
    // Try to load bundled PNG if not present in asset catalog
    private var hockeyUIImage: UIImage? {
        #if canImport(UIKit)
        if let img = UIImage(named: "hockey_icon_white") { return img }
        if let path = Bundle.main.path(forResource: "hockey_icon_white", ofType: "png"),
           let img = UIImage(contentsOfFile: path) {
            return img
        }
        #endif
        return nil
    }
    
    private var hasResult: Bool {
        analysisResult != nil
    }
    
    private var score: Int {
        analysisResult?.overallScore ?? 0
    }
    
    private var scoreColor: Color {
        guard let score = analysisResult?.overallScore else { return theme.textSecondary }
        
        switch score {
        case 80...100:
            return .green
        case 60..<80:
            return .yellow
        case 40..<60:
            return .orange
        default:
            return .red
        }
    }
    
    var body: some View {
        ZStack {
            HStack(spacing: theme.spacing.md) {
                // Icon with background
                ZStack {
                    // Soft outer glow behind the circle
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    theme.primary.opacity(0.35),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 34
                            )
                        )
                        .frame(width: 68, height: 68)
                        .blur(radius: 10)
                        .allowsHitTesting(false)

                    // Circle background
                    Circle()
                        .fill(theme.primary.opacity(0.12))
                        .frame(width: 52, height: 52)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.35), theme.primary.opacity(0.6)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.2
                                )
                        )

                    // Use custom hockey icon instead of SF Symbols
                    if let uiImg = hockeyUIImage {
                        Image(uiImage: uiImg)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .foregroundColor(theme.primary)
                            // subtle inner glow
                            .shadow(color: theme.primary.opacity(0.6), radius: 6)
                    } else {
                        Image(systemName: type.icon)
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundColor(theme.primary)
                            .shadow(color: theme.primary.opacity(0.6), radius: 6)
                    }
                }

                // Text content
                VStack(alignment: .leading, spacing: 8) {
                    // Title row with optional PRO on the right when idle
                    HStack(spacing: 8) {
                        Text(type.displayName)
                            .font(.system(size: 20, weight: .black))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color.white,
                                        Color.white.opacity(0.9)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: Color.white.opacity(0.25), radius: 0, x: 0, y: 0)
                            .shadow(color: Color.white.opacity(0.15), radius: 3, x: 0, y: 0)
                        if !hasResult && !isAnalyzing && !monetization.isPremium {
                            ProChip()
                        }
                    }

                    if hasResult {
                        // Buttons below title when results are ready
                        HStack(spacing: 6) {
                            Button(action: { onOpenResults?() }) {
                                Text("Results")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(theme.primary)
                                    )
                            }

                            Button(action: { onAnalyzeAgain?() }) {
                                Text("Analyze Again")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.gray.opacity(0.3))
                                    )
                            }
                        }
                    } else if isAnalyzing {
                        HStack(spacing: 8) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                            Text("Analyzing in background…")
                                .font(theme.fonts.caption)
                                .foregroundColor(theme.textSecondary)
                        }
                    } else {
                        Text(type.description)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(theme.textSecondary.opacity(0.7))
                            .lineLimit(2)
                    }
                }

                Spacer()

                // Right side content - only show score when results are available
                if hasResult {
                    // Score display
                    VStack(alignment: .trailing, spacing: 0) {
                        Text("\(score)")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(scoreColor)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                        Text("SCORE")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(theme.textSecondary.opacity(0.7))
                            .tracking(0.3)
                    }
                    .frame(minWidth: 45)
                } else if isAnalyzing {
                    Button(action: { showCancelConfirm = true }) {
                        Text("Cancel")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .shadow(color: Color.white.opacity(0.85), radius: 1.5)
                            .shadow(color: Color.white.opacity(0.35), radius: 3.5)
                            .shadow(color: theme.destructive.opacity(0.35), radius: 6)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(theme.destructive)
                            )
                            .fixedSize()
                    }
                } else {
                    Image(systemName: "chevron.right")
                        .font(theme.fonts.caption)
                        .foregroundColor(theme.textSecondary)
                }
            }
            .padding(theme.spacing.md)
            .background(
                // Match Stick Analysis card background
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    theme.surface.opacity(0.9),
                                    theme.background.opacity(0.7)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                theme.primary.opacity(0.6),
                                theme.accent.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
            .shadow(color: theme.primary.opacity(0.2), radius: 12, x: 0, y: 4)

            // No overlay controls; actions are inline on the trailing side
        }
        // Pro tag is inline with text when idle
        .contentShape(Rectangle())
        .onTapGesture {
            // Only start when idle (no result, not analyzing)
            guard !isAnalyzing, !hasResult else { return }
            HapticManager.shared.playImpact(style: .light)
            onStart()
        }
        .confirmationDialog(
            "Cancel analysis?",
            isPresented: $showCancelConfirm,
            titleVisibility: .visible
        ) {
            Button("Stop Analysis", role: .destructive) { onCancel?() }
            Button("Keep Running", role: .cancel) {}
        }
    }
}

// Note: ShotType.icon and ShotType.description are already defined in ShotRaterModels.swift
