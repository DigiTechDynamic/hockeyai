import SwiftUI

// MARK: - Shared Paywall Components

/// Reusable benefit row for paywalls
struct PaywallBenefitRow: View {
    let icon: String
    let text: String
    var color: Color = Color(hex: "#39FF14")

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 24, height: 24)

            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color.white.opacity(0.95))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

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

            Text("SnapHockey")
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
