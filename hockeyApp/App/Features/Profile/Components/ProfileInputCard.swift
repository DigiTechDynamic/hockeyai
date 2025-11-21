import SwiftUI

// MARK: - Profile Input Card
/// Reusable wrapper for all profile input fields
/// Provides consistent styling, labels, and layout
struct ProfileInputCard<Content: View>: View {
    @Environment(\.theme) var theme
    let title: String
    let systemImage: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            Label(title, systemImage: systemImage)
                .font(theme.fonts.caption)
                .foregroundColor(theme.textSecondary)

            content()
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: AppSettings.Constants.Layout.cornerRadiusMedium)
                        .fill(Color.black.opacity(0.4))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppSettings.Constants.Layout.cornerRadiusMedium)
                                .stroke(theme.divider.opacity(0.3), lineWidth: 1)
                        )
                )
        }
    }
}

// MARK: - Profile Section Card
/// Reusable wrapper for profile sections
struct ProfileSectionCard<Content: View>: View {
    @Environment(\.theme) var theme
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: theme.spacing.lg) {
            content()
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(white: 0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Profile Section Title
/// Reusable section title with icon
struct ProfileSectionTitle: View {
    @Environment(\.theme) var theme
    let title: String
    let systemImage: String

    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .font(theme.fonts.body)
                .foregroundColor(theme.primary)
            Text(title)
                .font(theme.fonts.headline)
                .foregroundColor(.white)
            Spacer()
        }
    }
}
