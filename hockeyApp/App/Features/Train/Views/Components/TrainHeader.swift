import SwiftUI

// MARK: - Train Header (customizable clone of UnifiedAIHeader)
// This header mirrors the AI flow header but lives in Train so we can
// evolve styling independently (glow, underline, padding, etc.).
struct TrainHeader: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss

    // Core content
    let title: String
    let subtitle: String?

    // Controls
    let showBackButton: Bool
    let showCloseButton: Bool
    let onBack: (() -> Void)?
    let onClose: (() -> Void)?

    // Customization
    let centerTitle: Bool
    let showUnderline: Bool
    let titleSize: CGFloat
    let glowIntensity: Double // 0.0 - 1.0
    let backgroundStyle: BackgroundStyle
    let trailingButton: AnyView?

    enum BackgroundStyle { case glass, solid }

    init(
        title: String,
        subtitle: String? = nil,
        showBackButton: Bool = false,
        showCloseButton: Bool = true,
        onBack: (() -> Void)? = nil,
        onClose: (() -> Void)? = nil,
        centerTitle: Bool = true,
        showUnderline: Bool = true,
        titleSize: CGFloat = 24,
        glowIntensity: Double = 1.0,
        backgroundStyle: BackgroundStyle = .glass,
        trailingButton: AnyView? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.showBackButton = showBackButton
        self.showCloseButton = showCloseButton
        self.onBack = onBack
        self.onClose = onClose
        self.centerTitle = centerTitle
        self.showUnderline = showUnderline
        self.titleSize = titleSize
        self.glowIntensity = glowIntensity
        self.backgroundStyle = backgroundStyle
        self.trailingButton = trailingButton
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: theme.spacing.md) {
                // Left action
                if showBackButton {
                    Button(action: { onBack?() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(theme.primary)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                } else if showCloseButton {
                    Button(action: { (onClose ?? { dismiss() })() }) {
                        ZStack {
                            Circle()
                                .fill(theme.surface)
                                .frame(width: 44, height: 44)

                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(theme.textSecondary)
                        }
                    }
                } else {
                    Color.clear.frame(width: 44, height: 44)
                }

                Spacer(minLength: 0)

                // Title stack
                VStack(spacing: theme.spacing.xs / 2) {
                    Text(title)
                        .font(.system(size: titleSize, weight: .heavy))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.white, Color.white.opacity(0.95)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .shadow(color: Color.white.opacity(0.45 * glowIntensity), radius: 0)
                        .shadow(color: Color.white.opacity(0.30 * glowIntensity), radius: 4)
                        .shadow(color: theme.primary.opacity(0.40 * glowIntensity), radius: 10, y: 2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    if let subtitle = subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(theme.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
                .frame(maxWidth: .infinity, alignment: centerTitle ? .center : .leading)

                Spacer(minLength: 0)

                // Trailing action if provided, else balance spacer
                if let trailing = trailingButton {
                    trailing.frame(height: 44)
                } else {
                    theme.background.opacity(0).frame(width: 44, height: 44)
                }
            }
            .frame(height: 56)
            .padding(.leading, theme.spacing.md)
            .padding(.trailing, trailingButton == nil ? theme.spacing.md : 8)
            .background(background)

            if showUnderline {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                theme.primary.opacity(0.0),
                                theme.primary.opacity(0.30),
                                theme.primary.opacity(0.0)
                            ],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
            }
        }
    }

    @ViewBuilder
    private var background: some View {
        switch backgroundStyle {
        case .glass:
            ZStack {
                Rectangle().fill(.ultraThinMaterial)
                LinearGradient(
                    colors: [theme.surface.opacity(0.9), theme.background.opacity(0.7)],
                    startPoint: .top, endPoint: .bottom
                )
            }
            .ignoresSafeArea(edges: .top)
        case .solid:
            theme.background
        }
    }
}

