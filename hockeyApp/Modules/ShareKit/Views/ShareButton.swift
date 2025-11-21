import SwiftUI

// MARK: - Share Button
/// Reusable share button component with multiple style variants
/// Integrates with theme system and provides haptic feedback
public struct ShareButton: View {
    // MARK: - Properties
    private let content: ShareContent
    private let style: ShareButtonStyle
    private let label: String?
    private let onComplete: ((ShareResult) -> Void)?

    @Environment(\.theme) var theme

    // MARK: - Initialization
    public init(
        content: ShareContent,
        style: ShareButtonStyle = .primary,
        label: String? = nil,
        onComplete: ((ShareResult) -> Void)? = nil
    ) {
        self.content = content
        self.style = style
        self.label = label
        self.onComplete = onComplete
    }

    // MARK: - Body
    public var body: some View {
        Button(action: handleShare) {
            buttonContent
                .frame(maxWidth: style.shouldExpand ? .infinity : nil)
                .frame(height: style.height)
                .background(backgroundView)
                .cornerRadius(style.cornerRadius)
                .shadow(
                    color: style.shadowColor(theme: theme),
                    radius: style.shadowRadius,
                    y: style.shadowY
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Button Content
    @ViewBuilder
    private var buttonContent: some View {
        HStack(spacing: style.spacing) {
            Image(systemName: style.icon)
                .font(.system(size: style.iconSize, weight: .bold))

            if !style.isIconOnly {
                Text(displayLabel)
                    .font(.system(size: style.fontSize, weight: .bold))
            }
        }
        .foregroundColor(style.foregroundColor(theme: theme))
        .padding(.horizontal, style.horizontalPadding)
    }

    // MARK: - Background View
    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            LinearGradient(
                colors: [theme.primary, theme.primary.opacity(0.9)],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .secondary:
            RoundedRectangle(cornerRadius: style.cornerRadius)
                .stroke(theme.textSecondary.opacity(0.3), lineWidth: 1.5)
        case .icon:
            theme.surface
        case .minimal:
            Color.clear
        }
    }

    // MARK: - Computed Properties
    private var displayLabel: String {
        if let label = label {
            return label
        }

        // Generate smart label based on content type
        switch content.type {
        case .styCheck:
            return "Share with Team"
        case .skillCheck:
            return "Share My Skills"
        case .stickAnalysis:
            return "Share My Stick"
        case .shotRater:
            return "Share My Shot"
        case .aiCoachFlow:
            return "Share My Analysis"
        case .generic:
            return "Share"
        }
    }

    // MARK: - Actions
    private func handleShare() {
        // Haptic feedback
        HapticManager.shared.playImpact(style: .medium)

        // Track CTA click
        ShareAnalytics.shared.trackShareCTAClicked(
            contentType: content.type,
            buttonStyle: style.rawValue,
            location: "unknown" // Can be passed as parameter if needed
        )

        // Present share sheet
        ShareService.shared.share(content: content) { result in
            onComplete?(result)
        }
    }
}

// MARK: - Share Button Style
public enum ShareButtonStyle: String {
    case primary = "primary"
    case secondary = "secondary"
    case icon = "icon"
    case minimal = "minimal"

    var height: CGFloat {
        switch self {
        case .primary: return 56
        case .secondary: return 52
        case .icon: return 44
        case .minimal: return 40
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .primary: return 14
        case .secondary: return 14
        case .icon: return 12
        case .minimal: return 10
        }
    }

    var fontSize: CGFloat {
        switch self {
        case .primary: return 17
        case .secondary: return 15
        case .icon: return 16
        case .minimal: return 14
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .primary: return 18
        case .secondary: return 16
        case .icon: return 18
        case .minimal: return 15
        }
    }

    var icon: String {
        return "square.and.arrow.up"
    }

    var spacing: CGFloat {
        return 10
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .primary: return 0
        case .secondary: return 0
        case .icon: return 12
        case .minimal: return 8
        }
    }

    var shouldExpand: Bool {
        switch self {
        case .primary, .secondary: return true
        case .icon, .minimal: return false
        }
    }

    var isIconOnly: Bool {
        switch self {
        case .icon: return true
        default: return false
        }
    }

    var shadowRadius: CGFloat {
        switch self {
        case .primary: return 12
        case .secondary: return 0
        case .icon: return 4
        case .minimal: return 0
        }
    }

    var shadowY: CGFloat {
        switch self {
        case .primary: return 6
        case .secondary: return 0
        case .icon: return 2
        case .minimal: return 0
        }
    }

    func foregroundColor(theme: AppTheme) -> Color {
        switch self {
        case .primary: return .black
        case .secondary: return theme.text
        case .icon: return theme.primary
        case .minimal: return theme.textSecondary
        }
    }

    func shadowColor(theme: AppTheme) -> Color {
        switch self {
        case .primary: return theme.primary.opacity(0.4)
        case .secondary: return Color.clear
        case .icon: return theme.primary.opacity(0.2)
        case .minimal: return Color.clear
        }
    }
}

// MARK: - Preview Helpers
// Note: ScaleButtonStyle is defined globally in Shared/Config/Themes/NHL/NHLTeamSelector.swift
#if DEBUG
struct ShareButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Primary style
            ShareButton(
                content: ShareContent(
                    type: .styCheck,
                    score: 87,
                    title: "Grinder",
                    comment: "Great hustle!"
                ),
                style: .primary
            )

            // Secondary style
            ShareButton(
                content: ShareContent(
                    type: .skillCheck,
                    score: 92,
                    title: "Wrist Shot"
                ),
                style: .secondary
            )

            // Icon style
            ShareButton(
                content: ShareContent(
                    type: .shotRater,
                    score: 94
                ),
                style: .icon
            )

            // Minimal style
            ShareButton(
                content: ShareContent(
                    type: .generic,
                    title: "Check this out!"
                ),
                style: .minimal,
                label: "Share"
            )
        }
        .padding()
        .background(Color.black)
    }
}
#endif
