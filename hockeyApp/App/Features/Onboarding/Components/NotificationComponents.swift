import SwiftUI

// MARK: - Notification Preview Card
/// Shows a realistic notification preview for onboarding
struct NotificationPreviewCard: View {
    @Environment(\.theme) var theme
    let title: String
    let message: String
    let time: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Realistic app icon
            Image("HockeyAISymbol")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Snap Hockey")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(theme.textSecondary)
                    Spacer()
                    Text(time)
                        .font(.system(size: 11))
                        .foregroundColor(theme.textSecondary)
                }

                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(message)
                    .font(.system(size: 14))
                    .foregroundColor(theme.textSecondary)
                    .lineLimit(2)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .fill(theme.surface)
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Benefit Row
/// Shows a benefit/feature row with icon and text
struct BenefitRow: View {
    @Environment(\.theme) var theme
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(theme.primary)
                .frame(width: 24)

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(theme.textSecondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
    }
}
