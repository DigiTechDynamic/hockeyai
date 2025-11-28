import SwiftUI

// MARK: - Player Profile Stage View
struct PlayerProfileStageView: View {
    @ObservedObject var flowState: AIFlowState
    @Environment(\.theme) var theme
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var profileSource: ProfileSource = .useExisting
    @State private var showContent = false
    // Fixed height so both cards match exactly
    private let profileOptionHeight: CGFloat = 56
    
    // Manual entry states
    @State private var heightFeet: Int = 0
    @State private var heightInches: Int = 0
    @State private var weight: String = ""
    @State private var age: String = ""
    @State private var selectedGender: Gender? = nil
    @State private var selectedPosition: Position? = nil
    @State private var selectedHandedness: Handedness? = nil
    @State private var selectedPlayStyle: PlayStyle? = nil
    @State private var useMetric = false
    
    // Computed profile
    private var currentProfile: PlayerProfile? {
        if profileSource == .useExisting {
            // Load profile from UserDefaults
            if let profileData = UserDefaults.standard.data(forKey: "playerProfile"),
               let profile = try? JSONDecoder().decode(PlayerProfile.self, from: profileData) {
                return profile
            }
            return nil
        } else {
            // Build profile from manual entry
            let heightInInches = Double(heightFeet * 12 + heightInches)

            // Normalize weight to pounds for storage
            var storedWeight: Double? = nil
            if let typed = Double(weight), typed > 0 {
                storedWeight = useMetric ? (typed * 2.20462) : typed
            }

            var profile = PlayerProfile()
            profile.height = heightInInches
            profile.weight = storedWeight
            if let ageInt = Int(age), ageInt > 0 { profile.age = ageInt }
            profile.gender = selectedGender
            profile.position = selectedPosition
            profile.handedness = selectedHandedness
            profile.playStyle = selectedPlayStyle

            return profile
        }
    }
    
    enum ProfileSource {
        case useExisting
        case enterManually
    }

    // (removed dynamic height equalization; using fixed height for reliability)

    // Helper method to check if profile has all required fields for analysis
    private func hasExistingProfile() -> Bool {
        if let profileData = UserDefaults.standard.data(forKey: "playerProfile"),
           let profile = try? JSONDecoder().decode(PlayerProfile.self, from: profileData) {
            // Check if profile has ALL required fields (height, weight, age)
            let hasHeight = profile.height != nil && profile.height! > 0
            let hasWeight = profile.weight != nil && profile.weight! > 0
            let hasAge = profile.age != nil && profile.age! > 0
            return hasHeight && hasWeight && hasAge
        }
        return false
    }

    // Helper method to validate manual entry fields
    private func isManualEntryValid() -> Bool {
        // Height must be set (not 0'0")
        let hasValidHeight = heightFeet > 0 || heightInches > 0

        // Weight must be entered and valid
        let hasValidWeight = !weight.isEmpty && Double(weight) != nil && Double(weight)! > 0

        // Age must be entered and valid
        let hasValidAge = !age.isEmpty && Int(age) != nil && Int(age)! > 0

        return hasValidHeight && hasValidWeight && hasValidAge
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: theme.spacing.lg) {
                    // Removed duplicate header - title is already in navigation
                    
                    // Profile Source Selection
                    profileSourceSection
                        .padding(.horizontal, theme.spacing.lg)
                        .padding(.top, theme.spacing.lg)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: showContent)
                    
                    // Profile Display/Entry
                    if profileSource == .useExisting {
                        existingProfileSection
                            .padding(.horizontal, theme.spacing.lg)
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 20)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.15), value: showContent)
                    } else {
                        manualEntrySection
                            .padding(.horizontal, theme.spacing.lg)
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 20)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.15), value: showContent)
                    }
                }
                .padding(.bottom, 100)
            }
            
            // Bottom action button
            bottomActionButton
        }
        .onAppear {
            // Always default to "Use Existing" if a profile exists
            if hasExistingProfile() {
                profileSource = .useExisting
                // Load the saved profile data into the manual entry fields
                if let profileData = UserDefaults.standard.data(forKey: "playerProfile"),
                   let profile = try? JSONDecoder().decode(PlayerProfile.self, from: profileData) {
                    // Update manual entry states with saved profile data
                    if let height = profile.height {
                        heightFeet = Int(height) / 12
                        heightInches = Int(height) % 12
                    }
                    if let weight = profile.weight {
                        self.weight = "\(Int(weight))"
                    }
                    if let age = profile.age { self.age = String(age) }
                    if let gender = profile.gender { self.selectedGender = gender }
                    if let position = profile.position {
                        selectedPosition = position
                    }
                    if let handedness = profile.handedness {
                        selectedHandedness = handedness
                    }
                    if let playStyle = profile.playStyle {
                        selectedPlayStyle = playStyle
                    }
                }
            } else {
                // Only use manual entry if no profile exists
                profileSource = .enterManually
            }
            
            withAnimation {
                showContent = true
            }
        }
    }
    
    // MARK: - Profile Source Section
    private var profileSourceSection: some View {
        AppCard(style: .elevated) {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                Text("Profile Source")
                    .font(theme.fonts.headline)
                    .foregroundColor(theme.text)
                
                HStack(spacing: theme.spacing.md) {
                    // Use Existing Button
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            profileSource = .useExisting
                        }
                    }) {
                        HStack {
                            Image(systemName: "person.crop.circle.fill.badge.checkmark")
                                .font(.title3)
                            Text("Use Existing")
                                .font(theme.fonts.body.weight(.medium))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: profileOptionHeight)
                        .padding(theme.spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: theme.cornerRadius)
                                .fill(profileSource == .useExisting ? theme.primary : theme.surface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: theme.cornerRadius)
                                .stroke(profileSource == .useExisting ? theme.primary : Color.clear, lineWidth: 2)
                        )
                    }
                    .foregroundColor(profileSource == .useExisting ? theme.background : theme.textSecondary)
                    .disabled(!hasExistingProfile())
                    
                    // Enter Manually Button
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            profileSource = .enterManually
                        }
                    }) {
                        HStack {
                            Image(systemName: "pencil.circle")
                                .font(.title3)
                            Text("Enter Manually")
                                .font(theme.fonts.body.weight(.medium))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: profileOptionHeight)
                        .padding(theme.spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: theme.cornerRadius)
                                .fill(profileSource == .enterManually ? theme.primary : theme.surface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: theme.cornerRadius)
                                .stroke(profileSource == .enterManually ? theme.primary : Color.clear, lineWidth: 2)
                        )
                    }
                    .foregroundColor(profileSource == .enterManually ? theme.background : theme.textSecondary)
                }
            }
        }
    }
    
    // MARK: - Existing Profile Section
    private var existingProfileSection: some View {
        AppCard(style: .elevated) {
            VStack(alignment: .leading, spacing: theme.spacing.lg) {
                HStack {
                    Image(systemName: "person.fill")
                        .font(.title3)
                        .foregroundColor(theme.primary)
                    Text("Current Profile")
                        .font(theme.fonts.headline)
                        .foregroundColor(theme.text)
                    Spacer()
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }
                
                if let profileData = UserDefaults.standard.data(forKey: "playerProfile"),
                   let profile = try? JSONDecoder().decode(PlayerProfile.self, from: profileData) {
                    VStack(spacing: theme.spacing.md) {
                        // Height
                        profileRow(label: "Height", value: profile.heightInFeetAndInches)
                        
                        // Weight
                        if let weight = profile.weight {
                            profileRow(label: "Weight", value: "\(Int(weight)) lbs")
                        }

                        // Age
                        if let age = profile.age {
                            profileRow(label: "Age", value: "\(age)")
                        }

                        // Gender
                        if let gender = profile.gender {
                            profileRow(label: "Gender", value: gender.rawValue)
                        }
                        
                        // Position
                        if let position = profile.position {
                            profileRow(label: "Position", value: position.rawValue)
                        }
                        
                        // Play Style
                        if let playStyle = profile.playStyle {
                            profileRow(label: "Play Style", value: playStyle.rawValue)
                        }
                        
                        // Shoots
                        if let handedness = profile.handedness {
                            profileRow(label: "Shoots", value: handedness.rawValue)
                        }
                    }
                } else {
                    Text("No profile found")
                        .font(theme.fonts.body)
                        .foregroundColor(theme.textSecondary)
                }
            }
        }
    }
    
    // MARK: - Manual Entry Section
    private var manualEntrySection: some View {
        VStack(spacing: theme.spacing.lg) {
            // Physical Attributes Card with Unit System Toggle inside
            AppCard(style: .elevated) {
                VStack(alignment: .leading, spacing: theme.spacing.lg) {
                    // Header with icon and title
                    HStack {
                        Image(systemName: "person.crop.circle")
                            .font(.title3)
                            .foregroundColor(theme.primary)
                        Text("Physical Attributes")
                            .font(theme.fonts.headline)
                            .foregroundColor(theme.text)
                        Spacer()
                    }
                    
                    // Unit System Toggle - now inside the card
                    HStack {
                        Text("Unit System")
                            .font(theme.fonts.body)
                            .foregroundColor(theme.textSecondary)
                        
                        Spacer()
                        
                        // Segmented Control matching Profile page style
                        HStack(spacing: 0) {
                            Button(action: { 
                                withAnimation(.spring(response: 0.3)) {
                                    useMetric = false
                                }
                            }) {
                                Text("Imperial")
                                    .font(theme.fonts.caption)
                                    .foregroundColor(!useMetric ? Color.black : theme.textSecondary)
                                    .frame(width: 80, height: 32)
                                    .background(!useMetric ? theme.primary : Color.white.opacity(0.1))
                            }
                            
                            Button(action: { 
                                withAnimation(.spring(response: 0.3)) {
                                    useMetric = true
                                }
                            }) {
                                Text("Metric")
                                    .font(theme.fonts.caption)
                                    .foregroundColor(useMetric ? Color.black : theme.textSecondary)
                                    .frame(width: 80, height: 32)
                                    .background(useMetric ? theme.primary : Color.white.opacity(0.1))
                            }
                        }
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    }
                    
                    // Height Input
                    VStack(alignment: .leading, spacing: theme.spacing.sm) {
                        HStack {
                            Image(systemName: "ruler")
                                .foregroundColor(theme.textSecondary)
                                .frame(width: 20)
                            Text("Height")
                                .font(theme.fonts.body.weight(.medium))
                                .foregroundColor(theme.text)
                        }
                        
                        if !useMetric {
                            // Imperial: Feet and Inches
                            HStack(spacing: theme.spacing.md) {
                                // Feet picker
                                HStack(spacing: theme.spacing.xs) {
                                    Button(action: { if heightFeet > 4 { heightFeet -= 1 } }) {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(theme.textSecondary)
                                    }
                                    
                                    VStack(spacing: 2) {
                                        Text("\(heightFeet)")
                                            .font(theme.fonts.title.bold())
                                            .foregroundColor(theme.text)
                                        Text("feet")
                                            .font(theme.fonts.caption)
                                            .foregroundColor(theme.textSecondary)
                                    }
                                    .frame(width: 50)
                                    
                                    Button(action: { if heightFeet < 7 { heightFeet += 1 } }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(theme.primary)
                                    }
                                }
                                
                                // Inches picker
                                HStack(spacing: theme.spacing.xs) {
                                    Button(action: { if heightInches > 0 { heightInches -= 1 } }) {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(theme.textSecondary)
                                    }
                                    
                                    VStack(spacing: 2) {
                                        Text("\(heightInches)")
                                            .font(theme.fonts.title.bold())
                                            .foregroundColor(theme.text)
                                        Text("inches")
                                            .font(theme.fonts.caption)
                                            .foregroundColor(theme.textSecondary)
                                    }
                                    .frame(width: 50)
                                    
                                    Button(action: { if heightInches < 11 { heightInches += 1 } }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(theme.primary)
                                    }
                                }
                            }
                        } else {
                            // Metric: Centimeters
                            HStack {
                                TextField("180", text: .constant("\(Int(Double(heightFeet * 12 + heightInches) * 2.54))"))
                                    .keyboardType(.numberPad)
                                    .font(theme.fonts.headline.bold())
                                    .foregroundColor(theme.text)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 80)
                                    .padding(.vertical, theme.spacing.sm)
                                    .background(theme.surface)
                                    .cornerRadius(theme.cornerRadius)
                                
                                Text("cm")
                                    .font(theme.fonts.body)
                                    .foregroundColor(theme.textSecondary)
                            }
                        }
                    }
                    
                    
                    Divider()
                        .background(theme.divider)
                    
                    // Weight Input
                    VStack(alignment: .leading, spacing: theme.spacing.sm) {
                        HStack {
                            Image(systemName: "scalemass")
                                .foregroundColor(theme.textSecondary)
                                .frame(width: 20)
                            Text("Weight")
                                .font(theme.fonts.body.weight(.medium))
                                .foregroundColor(theme.text)
                        }
                        
                        HStack {
                            TextField(useMetric ? "82" : "180", text: $weight)
                                .keyboardType(.numberPad)
                                .font(theme.fonts.headline.bold())
                                .foregroundColor(theme.text)
                                .multilineTextAlignment(.center)
                                .frame(width: 80)
                                .padding(.vertical, theme.spacing.sm)
                                .background(theme.surface)
                                .cornerRadius(theme.cornerRadius)
                            
                            Text(useMetric ? "kg" : "lbs")
                                .font(theme.fonts.body)
                                .foregroundColor(theme.textSecondary)
                        }
                    }

                    Divider()
                        .background(theme.divider)

                    // Age Input
                    VStack(alignment: .leading, spacing: theme.spacing.sm) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(theme.textSecondary)
                                .frame(width: 20)
                            Text("Age")
                                .font(theme.fonts.body.weight(.medium))
                                .foregroundColor(theme.text)
                        }

                        HStack(spacing: theme.spacing.sm) {
                            TextField("0", text: $age)
                                .keyboardType(.numberPad)
                                .font(theme.fonts.headline.bold())
                                .foregroundColor(theme.text)
                                .multilineTextAlignment(.center)
                                .frame(width: 80)
                                .padding(.vertical, theme.spacing.sm)
                                .background(theme.surface)
                                .cornerRadius(theme.cornerRadius)
                            Text("years")
                                .font(theme.fonts.body)
                                .foregroundColor(theme.textSecondary)
                            Spacer()
                        }
                    }

                    // Gender Selection (reuse pill-style row for consistent UI)
                    ProfileGenderSelectionRow(selectedGender: $selectedGender)
                }
            }
            
            // Hockey Profile
            AppCard(style: .elevated) {
                VStack(alignment: .leading, spacing: theme.spacing.md) {
                    HStack {
                        Image(systemName: "sportscourt.fill")
                            .font(.title3)
                            .foregroundColor(theme.primary)
                        Text("Hockey Profile")
                            .font(theme.fonts.headline)
                            .foregroundColor(theme.text)
                        Spacer()
                    }
                    
                    // Position
                    VStack(alignment: .leading, spacing: theme.spacing.sm) {
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(theme.textSecondary)
                                .frame(width: 20)
                            Text("Position")
                                .font(theme.fonts.body.weight(.medium))
                                .foregroundColor(theme.text)
                        }
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: theme.spacing.sm) {
                            ForEach(Position.allCases, id: \.self) { position in
                                positionButton(position)
                            }
                        }
                    }
                    
                    // Play Style
                    VStack(alignment: .leading, spacing: theme.spacing.sm) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(theme.textSecondary)
                                .frame(width: 20)
                            Text("Play Style")
                                .font(theme.fonts.body.weight(.medium))
                                .foregroundColor(theme.text)
                        }
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: theme.spacing.sm) {
                            ForEach(PlayStyle.stylesForPosition(selectedPosition), id: \.self) { style in
                                playStyleButton(style)
                            }
                        }
                    }
                    
                    // Handedness
                    VStack(alignment: .leading, spacing: theme.spacing.sm) {
                        HStack {
                            Image(systemName: "hockey.puck")
                                .foregroundColor(theme.textSecondary)
                                .frame(width: 20)
                            Text("Shoots")
                                .font(theme.fonts.body.weight(.medium))
                                .foregroundColor(theme.text)
                        }
                        
                        HStack(spacing: theme.spacing.sm) {
                            ForEach(Handedness.allCases, id: \.self) { hand in
                                handednessButton(hand)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Views
    private func profileRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(theme.fonts.body)
                .foregroundColor(theme.textSecondary)
            Spacer()
            Text(value)
                .font(theme.fonts.body.weight(.semibold))
                .foregroundColor(theme.text)
        }
    }
    
    private func positionButton(_ position: Position) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3)) {
                selectedPosition = position
            }
        }) {
            Text(position.rawValue)
                .font(theme.fonts.body.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, theme.spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: theme.cornerRadius)
                        .fill(selectedPosition == .some(position) ? theme.primary : theme.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: theme.cornerRadius)
                        .stroke(selectedPosition == .some(position) ? theme.primary : theme.divider, lineWidth: 1)
                )
                .foregroundColor(selectedPosition == .some(position) ? theme.background : theme.text)
        }
    }
    
    private func playStyleButton(_ style: PlayStyle) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3)) {
                selectedPlayStyle = style
            }
        }) {
            Text(style.rawValue)
                .font(theme.fonts.body.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, theme.spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: theme.cornerRadius)
                        .fill(selectedPlayStyle == style ? theme.primary : theme.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: theme.cornerRadius)
                        .stroke(selectedPlayStyle == style ? theme.primary : theme.divider, lineWidth: 1)
                )
                .foregroundColor(selectedPlayStyle == style ? theme.background : theme.text)
        }
    }
    
    private func handednessButton(_ hand: Handedness) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3)) {
                selectedHandedness = hand
            }
        }) {
            HStack {
                Image(systemName: hand.icon)
                Text(hand.rawValue)
                    .font(theme.fonts.body.weight(.medium))
            }
            .frame(maxWidth: .infinity)
            .padding(theme.spacing.md)
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .fill(selectedHandedness == .some(hand) ? theme.primary : theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .stroke(selectedHandedness == .some(hand) ? theme.primary : theme.divider, lineWidth: 1)
            )
            .foregroundColor(selectedHandedness == .some(hand) ? theme.background : theme.text)
        }
    }
    
    // MARK: - Bottom Action Button
    private var bottomActionButton: some View {
        AppButton(
            title: "Confirm & Continue",
            action: {
                if let profile = currentProfile {
                    print("✅ [PlayerProfileStageView] Proceeding with profile")
                    // Persist the profile so the main Profile screen reflects changes
                    if let encoded = try? JSONEncoder().encode(profile) {
                        UserDefaults.standard.set(encoded, forKey: "playerProfile")
                    }
                    // Persist unit preference for consistency with Profile screen
                    UserDefaults.standard.set(useMetric, forKey: "useMetricHeightUnits")
                    // Notify listeners (e.g., ProfileViewModel) that the profile changed
                    NotificationCenter.default.post(name: Notification.Name("PlayerProfileUpdated"), object: nil)
                    flowState.setData(profile, for: "player-profile")
                    flowState.proceed()
                }
            },
            style: .primary,
            size: .large,
            icon: "checkmark.circle.fill",
            isDisabled: {
                if profileSource == .useExisting {
                    return currentProfile == nil
                } else {
                    return !isManualEntryValid()
                }
            }()
        )
        .padding()
        .background(
            theme.background
                .opacity(0.95)
                .ignoresSafeArea()
        )
    }
}
