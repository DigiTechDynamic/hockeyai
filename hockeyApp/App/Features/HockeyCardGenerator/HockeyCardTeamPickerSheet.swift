import SwiftUI

// MARK: - Hockey Card Team Picker Sheet
/// Simplified team picker sheet for Hockey Card creation
/// Based on NHLTeamSelectorSheet but streamlined for quick team selection
struct HockeyCardTeamPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @Binding var selectedTeam: NHLTeam?

    @State private var selectedDivision: NHLTeam.Division? = nil
    @State private var searchText = ""
    @State private var tempSelectedTeam: NHLTeam? = nil

    // Adaptive columns based on device size
    private var columns: [GridItem] {
        let isCompact = verticalSizeClass == .compact || horizontalSizeClass == .compact
        let columnCount = isCompact ? 3 : 4
        return Array(repeating: GridItem(.flexible()), count: columnCount)
    }

    private var filteredTeams: [NHLTeam] {
        let teams = selectedDivision != nil ?
            NHLTeams.teamsByDivision(selectedDivision!) :
            NHLTeams.allTeams

        if searchText.isEmpty {
            return teams
        }

        return teams.filter { team in
            team.name.localizedCaseInsensitiveContains(searchText) ||
            team.city.localizedCaseInsensitiveContains(searchText) ||
            team.abbreviation.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Drag Indicator
            Capsule()
                .fill(Color.gray.opacity(0.5))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 4)

            // Header
            headerView
                .padding(.horizontal)

            // Division Filter
            divisionFilter
                .padding(.horizontal)
                .padding(.vertical, 8)

            // Search Bar
            searchBar
                .padding(.horizontal)
                .padding(.bottom, 8)

            // Teams Grid
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(filteredTeams, id: \.id) { team in
                        CardTeamCell(
                            team: team,
                            isSelected: tempSelectedTeam?.id == team.id,
                            onTap: {
                                HapticManager.shared.playSelection()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    tempSelectedTeam = team
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .frame(maxHeight: .infinity)

            Spacer(minLength: 0)

            // Bottom Actions
            VStack(spacing: 0) {
                Divider()
                bottomActions
                    .background(theme.background)
            }
        }
        .background(theme.background)
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .onAppear {
            // Pre-select current team if one exists
            tempSelectedTeam = selectedTeam
        }
    }

    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 8) {
            Text("Choose Your Team")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(theme.text)

            Text("Select the team for your hockey card jersey")
                .font(theme.fonts.callout)
                .foregroundColor(theme.textSecondary)
        }
        .padding(.vertical, 12)
    }

    // MARK: - Division Filter
    private var divisionFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                CardFilterChip(
                    title: "All Teams",
                    isSelected: selectedDivision == nil,
                    action: { selectedDivision = nil }
                )

                ForEach(NHLTeam.Division.allCases, id: \.self) { division in
                    CardFilterChip(
                        title: division.rawValue,
                        isSelected: selectedDivision == division,
                        action: { selectedDivision = division }
                    )
                }
            }
        }
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(theme.textSecondary)

            TextField("Search teams...", text: $searchText)
                .foregroundColor(theme.text)
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
        .padding(12)
        .background(theme.surface)
        .cornerRadius(theme.cornerRadius)
    }

    // MARK: - Bottom Actions
    private var bottomActions: some View {
        HStack(spacing: 16) {
            Button(action: {
                dismiss()
            }) {
                Text("Cancel")
                    .font(theme.fonts.button)
                    .foregroundColor(theme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(theme.surface)
                    .cornerRadius(theme.cornerRadius)
            }

            Button(action: {
                if let team = tempSelectedTeam {
                    selectedTeam = team
                    HapticManager.shared.playImpact(style: .medium)
                    dismiss()
                }
            }) {
                HStack(spacing: 8) {
                    if let team = tempSelectedTeam {
                        // Show selected team indicator
                        ZStack {
                            Circle()
                                .fill(team.primaryColor)
                                .frame(width: 24, height: 24)

                            Image(systemName: team.logoSymbol)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }

                    Text(tempSelectedTeam != nil ? "Select \(tempSelectedTeam!.abbreviation)" : "Select Team")
                        .font(theme.fonts.button)
                }
                .foregroundColor(theme.textOnPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    tempSelectedTeam != nil ?
                    theme.primaryGradient :
                    LinearGradient(colors: [theme.surface], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(theme.cornerRadius)
            }
            .disabled(tempSelectedTeam == nil)
        }
        .padding()
        .background(theme.background)
    }
}

// MARK: - Card Team Cell
/// Simplified team cell for card creation (no preview mode)
private struct CardTeamCell: View {
    @Environment(\.theme) private var theme
    let team: NHLTeam
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                // Team Color Circle
                ZStack {
                    Circle()
                        .fill(team.primaryColor)
                        .frame(width: 50, height: 50)

                    if let accent = team.accentColor {
                        Circle()
                            .stroke(accent, lineWidth: 3)
                            .frame(width: 50, height: 50)
                    }

                    Image(systemName: team.logoSymbol)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(
                            ColorAdaptation.ensureContrast(
                                foreground: Color.white,
                                background: team.primaryColor,
                                minRatio: 3.0
                            )
                        )

                    // Selection checkmark
                    if isSelected {
                        Circle()
                            .fill(Color.black.opacity(0.3))
                            .frame(width: 50, height: 50)

                        Image(systemName: "checkmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .shadow(color: isSelected ? team.primaryColor.opacity(0.6) : .clear, radius: 8)
                .scaleEffect(isSelected ? 1.1 : 1.0)

                // Team Name
                Text(team.abbreviation)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(isSelected ? team.primaryColor : theme.text)
                    .lineLimit(1)
            }
            .frame(width: 80, height: 90)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.surface.opacity(isSelected ? 0.8 : 0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? team.primaryColor : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
        }
        .buttonStyle(CardScaleButtonStyle())
    }
}

// MARK: - Card Filter Chip
/// Local filter chip to avoid conflicts with other definitions
private struct CardFilterChip: View {
    @Environment(\.theme) private var theme
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.shared.playSelection()
            action()
        }) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? theme.textOnPrimary : theme.text)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? theme.primary : theme.surface)
                )
        }
    }
}

// MARK: - Card Scale Button Style
private struct CardScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
