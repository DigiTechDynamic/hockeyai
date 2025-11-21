import SwiftUI

// MARK: - Unified Profile Input System
// Design inspired by: Apple Health, Strava, Nike Training Club, Peloton

// MARK: - Design Tokens
struct ProfileDesignTokens {
    static let inputHeight: CGFloat = 60
    static let cornerRadius: CGFloat = 16
    static let spacing: CGFloat = 16
    static let iconSize: CGFloat = 24
    static let sectionSpacing: CGFloat = 32
}

// MARK: - Height Input Component
struct ProfileHeightInput: View {
    @Environment(\.theme) var theme
    @Binding var heightInInches: Int
    @Binding var isMetric: Bool
    @State private var showingPicker = false
    
    private var displayValue: String {
        if isMetric {
            let cm = Int(Double(heightInInches) * 2.54)
            return "\(cm) cm"
        } else {
            let feet = heightInInches / 12
            let inches = heightInInches % 12
            return "\(feet)' \(inches)\""
        }
    }
    
    var body: some View {
        Button(action: {
            showingPicker = true
            HapticManager.shared.playImpact(style: .light)
        }) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: "ruler")
                    .font(.system(size: ProfileDesignTokens.iconSize))
                    .foregroundColor(theme.primary)
                    .frame(width: 32, height: 32)
                
                // Label
                VStack(alignment: .leading, spacing: 4) {
                    Text("Height")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                    Text(displayValue)
                        .font(.headline)
                        .foregroundColor(theme.text)
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.textSecondary)
            }
            .padding(.horizontal, 16)
            .frame(height: ProfileDesignTokens.inputHeight)
            .background(theme.surface)
            .cornerRadius(ProfileDesignTokens.cornerRadius)
        }
        .sheet(isPresented: $showingPicker) {
            HeightPickerView(
                heightInInches: $heightInInches,
                isMetric: $isMetric,
                isPresented: $showingPicker
            )
        }
    }
}

// MARK: - Weight Input Component
struct ProfileWeightInput: View {
    @Environment(\.theme) var theme
    @Binding var weightInPounds: Int
    @Binding var isMetric: Bool
    @State private var showingPicker = false
    
    private var displayValue: String {
        if isMetric {
            let kg = Int(Double(weightInPounds) * 0.453592)
            return "\(kg) kg"
        } else {
            return "\(weightInPounds) lbs"
        }
    }
    
    var body: some View {
        Button(action: {
            showingPicker = true
            HapticManager.shared.playImpact(style: .light)
        }) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: "scalemass")
                    .font(.system(size: ProfileDesignTokens.iconSize))
                    .foregroundColor(theme.primary)
                    .frame(width: 32, height: 32)
                
                // Label
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weight")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                    Text(displayValue)
                        .font(.headline)
                        .foregroundColor(theme.text)
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.textSecondary)
            }
            .padding(.horizontal, 16)
            .frame(height: ProfileDesignTokens.inputHeight)
            .background(theme.surface)
            .cornerRadius(ProfileDesignTokens.cornerRadius)
        }
        .sheet(isPresented: $showingPicker) {
            WeightPickerView(
                weightInPounds: $weightInPounds,
                isMetric: $isMetric,
                isPresented: $showingPicker
            )
        }
    }
}

// MARK: - Age Input Component
struct ProfileAgeInput: View {
    @Environment(\.theme) var theme
    @Binding var age: Int
    @State private var showingPicker = false
    
    var body: some View {
        Button(action: {
            showingPicker = true
            HapticManager.shared.playImpact(style: .light)
        }) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: "calendar")
                    .font(.system(size: ProfileDesignTokens.iconSize))
                    .foregroundColor(theme.primary)
                    .frame(width: 32, height: 32)
                
                // Label
                VStack(alignment: .leading, spacing: 4) {
                    Text("Age")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                    Text("\(age) years")
                        .font(.headline)
                        .foregroundColor(theme.text)
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.textSecondary)
            }
            .padding(.horizontal, 16)
            .frame(height: ProfileDesignTokens.inputHeight)
            .background(theme.surface)
            .cornerRadius(ProfileDesignTokens.cornerRadius)
        }
        .sheet(isPresented: $showingPicker) {
            AgePickerView(age: $age, isPresented: $showingPicker)
        }
    }
}

// MARK: - Gender Selection Component
struct ProfileGenderSelection: View {
    @Environment(\.theme) var theme
    @Binding var gender: String
    
    let options = ["Male", "Female", "Other"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "person.2")
                    .font(.system(size: ProfileDesignTokens.iconSize))
                    .foregroundColor(theme.primary)
                
                Text("Gender")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
            }
            
            HStack(spacing: 12) {
                ForEach(options, id: \.self) { option in
                    GenderButton(
                        title: option,
                        isSelected: gender == option,
                        action: {
                            gender = option
                            HapticManager.shared.playImpact(style: .light)
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Position Selection Component
struct ProfilePositionSelection: View {
    @Environment(\.theme) var theme
    @Binding var position: String
    
    let positions = [
        ("C", "Center", "sportscourt"),
        ("LW", "Left Wing", "sportscourt"),
        ("RW", "Right Wing", "sportscourt"),
        ("LD", "Left Defense", "shield.lefthalf.filled"),
        ("RD", "Right Defense", "shield.righthalf.filled"),
        ("G", "Goalie", "hockey.puck")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "sportscourt")
                    .font(.system(size: ProfileDesignTokens.iconSize))
                    .foregroundColor(theme.primary)
                
                Text("Position")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(positions, id: \.0) { pos in
                    PositionButton(
                        abbreviation: pos.0,
                        title: pos.1,
                        icon: pos.2,
                        isSelected: position == pos.0,
                        action: {
                            position = pos.0
                            HapticManager.shared.playImpact(style: .light)
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Shooting Hand Component
struct ProfileShootingHand: View {
    @Environment(\.theme) var theme
    @Binding var shootingHand: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "hockey.puck")
                    .font(.system(size: ProfileDesignTokens.iconSize))
                    .foregroundColor(theme.primary)
                
                Text("Shoots")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
            }
            
            HStack(spacing: 12) {
                ShootingHandButton(
                    title: "Left",
                    isSelected: shootingHand == "Left",
                    isLeft: true,
                    action: {
                        shootingHand = "Left"
                        HapticManager.shared.playImpact(style: .light)
                    }
                )
                
                ShootingHandButton(
                    title: "Right",
                    isSelected: shootingHand == "Right",
                    isLeft: false,
                    action: {
                        shootingHand = "Right"
                        HapticManager.shared.playImpact(style: .light)
                    }
                )
            }
        }
    }
}

// MARK: - Metric Toggle Component
struct ProfileMetricToggle: View {
    @Environment(\.theme) var theme
    @Binding var isMetric: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "globe")
                .font(.system(size: ProfileDesignTokens.iconSize))
                .foregroundColor(theme.primary)
            
            Text("Use Metric Units")
                .font(.body)
                .foregroundColor(theme.text)
            
            Spacer()
            
            Toggle("", isOn: $isMetric)
                .labelsHidden()
                .tint(theme.primary)
        }
        .padding(.horizontal, 16)
        .frame(height: ProfileDesignTokens.inputHeight)
        .background(theme.surface)
        .cornerRadius(ProfileDesignTokens.cornerRadius)
    }
}

// MARK: - Supporting Components

// Gender Button
struct GenderButton: View {
    @Environment(\.theme) var theme
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.callout.weight(isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? theme.textOnPrimary : theme.text)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(isSelected ? theme.primary : theme.surface)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.clear : theme.divider, lineWidth: 1)
                )
        }
    }
}

// Position Button
struct PositionButton: View {
    @Environment(\.theme) var theme
    let abbreviation: String
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? theme.primary : theme.textSecondary)
                
                Text(abbreviation)
                    .font(.headline)
                    .foregroundColor(isSelected ? theme.text : theme.textSecondary)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(theme.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 90)
            .background(isSelected ? theme.primary.opacity(0.1) : theme.surface)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? theme.primary : theme.divider, lineWidth: isSelected ? 2 : 1)
            )
        }
    }
}

// Shooting Hand Button
struct ShootingHandButton: View {
    @Environment(\.theme) var theme
    let title: String
    let isSelected: Bool
    let isLeft: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Stick visual
                StickVisual(isLeft: isLeft, isSelected: isSelected)
                    .frame(width: 40, height: 40)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(isSelected ? theme.text : theme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(isSelected ? theme.primary.opacity(0.1) : theme.surface)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? theme.primary : theme.divider, lineWidth: isSelected ? 2 : 1)
            )
        }
    }
}

// Stick Visual Component
struct StickVisual: View {
    @Environment(\.theme) var theme
    let isLeft: Bool
    let isSelected: Bool
    
    var body: some View {
        ZStack {
            // Stick shaft
            Rectangle()
                .fill(isSelected ? theme.primary : theme.textSecondary)
                .frame(width: 4, height: 30)
                .rotationEffect(.degrees(isLeft ? -15 : 15))
            
            // Blade
            RoundedRectangle(cornerRadius: 2)
                .fill(isSelected ? theme.primary : theme.textSecondary)
                .frame(width: 12, height: 6)
                .offset(x: isLeft ? -6 : 6, y: 12)
                .rotationEffect(.degrees(isLeft ? -30 : 30))
        }
    }
}

// MARK: - Picker Views

// Height Picker View
struct HeightPickerView: View {
    @Environment(\.theme) var theme
    @Binding var heightInInches: Int
    @Binding var isMetric: Bool
    @Binding var isPresented: Bool
    
    @State private var feet: Int
    @State private var inches: Int
    @State private var centimeters: Int
    
    init(heightInInches: Binding<Int>, isMetric: Binding<Bool>, isPresented: Binding<Bool>) {
        self._heightInInches = heightInInches
        self._isMetric = isMetric
        self._isPresented = isPresented
        
        let height = heightInInches.wrappedValue
        self._feet = State(initialValue: height / 12)
        self._inches = State(initialValue: height % 12)
        self._centimeters = State(initialValue: Int(Double(height) * 2.54))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Unit Toggle
                Picker("Units", selection: $isMetric) {
                    Text("Imperial").tag(false)
                    Text("Metric").tag(true)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                Spacer()
                
                if isMetric {
                    // Metric Picker
                    VStack(spacing: 16) {
                        Text("\(centimeters) cm")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(theme.primary)
                        
                        Picker("Centimeters", selection: $centimeters) {
                            ForEach(120...250, id: \.self) { cm in
                                Text("\(cm) cm").tag(cm)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(height: 150)
                        .onChange(of: centimeters) { newValue in
                            heightInInches = Int(Double(newValue) / 2.54)
                        }
                    }
                } else {
                    // Imperial Picker
                    HStack(spacing: 32) {
                        VStack {
                            Text("Feet")
                                .font(.caption)
                                .foregroundColor(theme.textSecondary)
                            
                            Picker("Feet", selection: $feet) {
                                ForEach(3...7, id: \.self) { ft in
                                    Text("\(ft)'").tag(ft)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: 100, height: 150)
                            .onChange(of: feet) { _ in
                                heightInInches = feet * 12 + inches
                            }
                        }
                        
                        VStack {
                            Text("Inches")
                                .font(.caption)
                                .foregroundColor(theme.textSecondary)
                            
                            Picker("Inches", selection: $inches) {
                                ForEach(0...11, id: \.self) { inch in
                                    Text("\(inch)\"").tag(inch)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: 100, height: 150)
                            .onChange(of: inches) { _ in
                                heightInInches = feet * 12 + inches
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Height")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// Weight Picker View
struct WeightPickerView: View {
    @Environment(\.theme) var theme
    @Binding var weightInPounds: Int
    @Binding var isMetric: Bool
    @Binding var isPresented: Bool
    
    @State private var kilograms: Int
    
    init(weightInPounds: Binding<Int>, isMetric: Binding<Bool>, isPresented: Binding<Bool>) {
        self._weightInPounds = weightInPounds
        self._isMetric = isMetric
        self._isPresented = isPresented
        self._kilograms = State(initialValue: Int(Double(weightInPounds.wrappedValue) * 0.453592))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Unit Toggle
                Picker("Units", selection: $isMetric) {
                    Text("Imperial").tag(false)
                    Text("Metric").tag(true)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                Spacer()
                
                if isMetric {
                    // Metric Picker
                    VStack(spacing: 16) {
                        Text("\(kilograms) kg")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(theme.primary)
                        
                        Picker("Kilograms", selection: $kilograms) {
                            ForEach(30...200, id: \.self) { kg in
                                Text("\(kg) kg").tag(kg)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(height: 150)
                        .onChange(of: kilograms) { newValue in
                            weightInPounds = Int(Double(newValue) / 0.453592)
                        }
                    }
                } else {
                    // Imperial Picker
                    VStack(spacing: 16) {
                        Text("\(weightInPounds) lbs")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(theme.primary)
                        
                        Picker("Pounds", selection: $weightInPounds) {
                            ForEach(60...400, id: \.self) { lbs in
                                Text("\(lbs) lbs").tag(lbs)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(height: 150)
                        .onChange(of: weightInPounds) { _ in
                            kilograms = Int(Double(weightInPounds) * 0.453592)
                        }
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// Age Picker View
struct AgePickerView: View {
    @Environment(\.theme) var theme
    @Binding var age: Int
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                VStack(spacing: 16) {
                    Text("\(age) years")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(theme.primary)
                    
                    Picker("Age", selection: $age) {
                        ForEach(5...100, id: \.self) { year in
                            Text("\(year)").tag(year)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(height: 150)
                }
                
                Spacer()
            }
            .navigationTitle("Age")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Complete Profile View
struct UnifiedProfileView: View {
    @Environment(\.theme) var theme
    @StateObject private var profileData = ProfileData()
    
    let isOnboarding: Bool
    let onComplete: (() -> Void)?
    
    init(isOnboarding: Bool = false, onComplete: (() -> Void)? = nil) {
        self.isOnboarding = isOnboarding
        self.onComplete = onComplete
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: ProfileDesignTokens.sectionSpacing) {
                // Physical Attributes Section
                VStack(alignment: .leading, spacing: 16) {
                    if !isOnboarding {
                        SectionHeader(title: "Physical Attributes", icon: "figure.stand")
                    }
                    
                    VStack(spacing: 12) {
                        ProfileHeightInput(
                            heightInInches: $profileData.heightInInches,
                            isMetric: $profileData.isMetric
                        )
                        
                        ProfileWeightInput(
                            weightInPounds: $profileData.weightInPounds,
                            isMetric: $profileData.isMetric
                        )
                        
                        ProfileAgeInput(age: $profileData.age)
                        
                        ProfileGenderSelection(gender: $profileData.gender)
                    }
                }
                
                // Hockey Profile Section
                VStack(alignment: .leading, spacing: 16) {
                    if !isOnboarding {
                        SectionHeader(title: "Hockey Profile", icon: "sportscourt")
                    }
                    
                    VStack(spacing: 20) {
                        ProfilePositionSelection(position: $profileData.position)
                        
                        ProfileShootingHand(shootingHand: $profileData.shootingHand)
                    }
                }
                
                // Settings Section
                VStack(spacing: 12) {
                    ProfileMetricToggle(isMetric: $profileData.isMetric)
                }
                
                // Action Button
                if isOnboarding {
                    Button(action: {
                        onComplete?()
                        HapticManager.shared.playNotification(type: .success)
                    }) {
                        HStack {
                            Text("Continue")
                                .font(.headline)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(theme.textOnPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(theme.primary)
                        .cornerRadius(ProfileDesignTokens.cornerRadius)
                    }
                    .padding(.top, 16)
                }
            }
            .padding()
        }
        .background(theme.background)
    }
}

// Section Header Component
struct SectionHeader: View {
    @Environment(\.theme) var theme
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(theme.primary)
            
            Text(title)
                .font(.headline)
                .foregroundColor(theme.text)
            
            Spacer()
        }
    }
}

// MARK: - Profile Data Model
class ProfileData: ObservableObject {
    @Published var heightInInches: Int = 70 // 5'10"
    @Published var weightInPounds: Int = 180
    @Published var age: Int = 25
    @Published var gender: String = "Male"
    @Published var position: String = "C"
    @Published var shootingHand: String = "Right"
    @Published var isMetric: Bool = false
    
    func toUnifiedProfile() -> UnifiedPlayerProfile {
        UnifiedPlayerProfile(
            heightInInches: heightInInches,
            weightInPounds: weightInPounds,
            age: age,
            gender: gender,
            position: position,
            handedness: shootingHand
        )
    }
}
