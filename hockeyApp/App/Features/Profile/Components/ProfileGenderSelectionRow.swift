import SwiftUI

// MARK: - Profile Gender Selection Row
/// Gender selection component for profile forms
struct ProfileGenderSelectionRow: View {
    @Environment(\.theme) var theme
    @Binding var selectedGender: Gender?

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            Label("Gender", systemImage: "person.2")
                .font(theme.fonts.caption)
                .foregroundColor(theme.textSecondary)

            HStack(spacing: theme.spacing.sm) {
                ForEach(Gender.allCases, id: \.self) { gender in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedGender = gender
                            HapticManager.shared.playSelection()
                        }
                    }) {
                        Text(gender.rawValue)
                            .font(theme.fonts.body)
                            .foregroundColor(selectedGender == .some(gender) ? theme.textOnPrimary : theme.text)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: AppSettings.Constants.Layout.cornerRadiusMedium)
                                    .fill(
                                        selectedGender == .some(gender) ?
                                            theme.primary :
                                            Color.black.opacity(0.4)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppSettings.Constants.Layout.cornerRadiusMedium)
                                            .stroke(theme.divider.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                Spacer()
            }
        }
    }
}
