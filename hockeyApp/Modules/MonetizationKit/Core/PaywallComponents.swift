import SwiftUI

// Shared, theme-aligned components for all paywalls

struct PaywallHeaderBar: View {
    @Environment(\.theme) var theme
    let onClose: () -> Void
    let onRestore: () -> Void

    var body: some View {
        ZStack {
            HStack {
                AppCloseButton(action: onClose)

                Spacer()

                Button(action: onRestore) {
                    Text("Restore")
                        .font(theme.fonts.caption)
                        .foregroundColor(theme.textSecondary)
                        .frame(height: 36)
                }
                .buttonStyle(.plain)
            }

            Text("Snap Hockey")
                .font(.system(size: 20, weight: .black))
                .glowingHeaderText()
        }
    }
}

struct PaywallCTAButton: View {
    @Environment(\.theme) var theme
    let title: String
    let subtitle: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(theme.fonts.button)
                    .foregroundColor(theme.textOnPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(theme.fonts.caption)
                        .foregroundColor(theme.textOnPrimary.opacity(0.9))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(theme.primaryGradient)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}
