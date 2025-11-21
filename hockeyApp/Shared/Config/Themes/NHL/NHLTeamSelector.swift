import SwiftUI

// MARK: - NHL Team Selector Sheet
struct NHLTeamSelectorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ObservedObject private var themeManager = ThemeManager.shared
    
    @State private var selectedDivision: NHLTeam.Division? = nil
    @State private var searchText = ""
    @State private var selectedTeam: NHLTeam? = nil
    @State private var viewMode: ViewMode = .selection
    
    enum ViewMode {
        case selection
        case preview
    }
    
    // Adaptive columns based on device size
    private var columns: [GridItem] {
        let isCompact = verticalSizeClass == .compact || horizontalSizeClass == .compact
        let columnCount = isCompact ? 3 : 4
        return Array(repeating: GridItem(.flexible()), count: columnCount)
    }
    
    var filteredTeams: [NHLTeam] {
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
        ZStack {
            switch viewMode {
            case .selection:
                teamSelectionView
            case .preview:
                if let team = selectedTeam {
                    teamPreviewView(team: team)
                }
            }
        }
        .background(theme.background)
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationBackgroundInteraction(.enabled(upThrough: .large))
    }
    
    // MARK: - Team Selection View
    private var teamSelectionView: some View {
        VStack(spacing: 0) {
            // Drag Indicator
            Capsule()
                .fill(Color.gray.opacity(0.5))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 4)
            
            // Header with proper spacing
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
            
            // Teams Grid with proper ScrollView
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(filteredTeams, id: \.id) { team in
                        TeamCard(
                            team: team,
                            isSelected: selectedTeam?.id == team.id,
                            onTap: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    selectedTeam = team
                                    viewMode = .preview
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
            
            // Bottom Actions with safe area
            VStack(spacing: 0) {
                Divider()
                bottomActions
                    .background(theme.background)
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 8) {
            Text("Choose Your Team")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(theme.text)
            
            Text("Personalize your app with team colors")
                .font(theme.fonts.callout)
                .foregroundColor(theme.textSecondary)
            
            // Keep STY Theme button
            Button(action: {
                // Keep the current STY theme
                UserDefaults.standard.removeObject(forKey: "selectedNHLTeam")
                themeManager.setTheme(themeId: "sty")
                dismiss()
            }) {
                HStack {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Keep STY Athletic Theme")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(theme.primary)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(theme.primary.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(theme.primary, lineWidth: 1.5)
                        )
                )
            }
            .padding(.top, 8)
        }
        .padding(.vertical, 12)
    }
    
    // MARK: - Division Filter
    private var divisionFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FilterChip(
                    title: "All Teams",
                    isSelected: selectedDivision == nil,
                    action: { selectedDivision = nil }
                )
                
                ForEach(NHLTeam.Division.allCases, id: \.self) { division in
                    FilterChip(
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
                // Allow dismissing without selection
                dismiss() 
            }) {
                Text("Maybe Later")
                    .font(theme.fonts.button)
                    .foregroundColor(theme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(theme.surface)
                    .cornerRadius(theme.cornerRadius)
            }
            
            Button(action: {
                if let team = selectedTeam {
                    applyTeamTheme(team)
                }
            }) {
                Text("Apply Theme")
                    .font(theme.fonts.button)
                    .foregroundColor(theme.textOnPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        selectedTeam != nil ? 
                        theme.primaryGradient : 
                        LinearGradient(colors: [theme.surface], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(theme.cornerRadius)
            }
            .disabled(selectedTeam == nil)
        }
        .padding()
        .background(theme.background)
    }
    
    // MARK: - Apply Theme
    private func applyTeamTheme(_ team: NHLTeam) {
        themeManager.setNHLTeam(team)
        
        // Save selection to UserDefaults
        UserDefaults.standard.set(team.id, forKey: "selectedNHLTeam")
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        dismiss()
    }
    
    // MARK: - Team Preview View
    private func teamPreviewView(team: NHLTeam) -> some View {
        let previewTheme = NHLTeamTheme(team: team)
        let isCompact = verticalSizeClass == .compact
        
        return VStack(spacing: 0) {
            // Custom header with back button
            HStack {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        viewMode = .selection
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(previewTheme.primary)
                }
                
                Spacer()
                
                // Drag indicator in center
                Capsule()
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 36, height: 5)
                
                Spacer()
                
                // Invisible spacer for balance
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .opacity(0)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 8)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: isCompact ? 16 : 24) {
                    // Team Header with proper padding
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(team.primaryColor)
                                .frame(width: isCompact ? 80 : 100, height: isCompact ? 80 : 100)
                            
                            if let accent = team.accentColor {
                                Circle()
                                    .stroke(accent, lineWidth: 4)
                                    .frame(width: isCompact ? 80 : 100, height: isCompact ? 80 : 100)
                            }
                            
                            Image(systemName: team.logoSymbol)
                                .font(.system(size: isCompact ? 40 : 48, weight: .bold))
                                .foregroundColor(
                                    ColorAdaptation.ensureContrast(
                                        foreground: Color.white,
                                        background: team.primaryColor,
                                        minRatio: 3.0
                                    )
                                )
                        }
                        .shadow(color: team.primaryColor.opacity(0.3), radius: 20)
                        
                        Text("\(team.city) \(team.name)")
                            .font(.system(size: isCompact ? 24 : 28, weight: .bold))
                            .foregroundColor(previewTheme.text)
                        
                        Text("\(team.conference.rawValue) Conference • \(team.division.rawValue) Division")
                            .font(previewTheme.fonts.caption)
                            .foregroundColor(previewTheme.textSecondary)
                    }
                    .padding(.top, 8)
                    
                    // Color Preview
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Theme Colors")
                            .font(previewTheme.fonts.headline)
                            .foregroundColor(previewTheme.text)
                        
                        HStack(spacing: 12) {
                            ColorSwatch(color: team.primaryColor, label: "Primary")
                            ColorSwatch(color: team.secondaryColor, label: "Secondary")
                            if let accent = team.accentColor {
                                ColorSwatch(color: accent, label: "Accent")
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Sample UI Elements
                    VStack(spacing: 16) {
                        // Sample Card
                        HStack {
                            Image(systemName: "hockey.puck")
                                .font(.title2)
                                .foregroundColor(previewTheme.primary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Sample Card")
                                    .font(previewTheme.fonts.headline)
                                    .foregroundColor(previewTheme.text)
                                Text("This is how your cards will look")
                                    .font(previewTheme.fonts.caption)
                                    .foregroundColor(previewTheme.textSecondary)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(previewTheme.cardBackground)
                        .cornerRadius(previewTheme.cornerRadius)
                        
                        // Sample Button
                        Button(action: {}) {
                            Text("Sample Button")
                                .font(previewTheme.fonts.button)
                                .foregroundColor(previewTheme.textOnPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(previewTheme.primaryGradient)
                                .cornerRadius(previewTheme.cornerRadius)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 16) {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        viewMode = .selection
                    }
                }) {
                    Text("Cancel")
                        .font(previewTheme.fonts.button)
                        .foregroundColor(previewTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(previewTheme.surface)
                        .cornerRadius(previewTheme.cornerRadius)
                }
                
                Button(action: {
                    applyTeamTheme(team)
                }) {
                    Text("Use This Theme")
                        .font(previewTheme.fonts.button)
                        .foregroundColor(previewTheme.textOnPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(previewTheme.primaryGradient)
                        .cornerRadius(previewTheme.cornerRadius)
                }
            }
            .padding()
        }
        .background(previewTheme.backgroundGradient)
    }
}

// MARK: - Team Card Component
struct TeamCard: View {
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
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Filter Chip Component
struct FilterChip: View {
    @Environment(\.theme) private var theme
    let title: String
    let icon: String?
    let isSelected: Bool
    let action: () -> Void

    init(title: String, icon: String? = nil, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Text(icon)
                        .font(.system(size: 14))
                }
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
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

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Color Swatch Component
struct ColorSwatch: View {
    let color: Color
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(height: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.gray)
        }
    }
}
