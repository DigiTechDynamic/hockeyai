import SwiftUI

// MARK: - Unified Profile Input Components
// Exact UI matching the onboarding screens

// MARK: - Design Tokens
struct ProfileInputTokens {
    static let cardBackground = Color(.sRGB, white: 0.12, opacity: 1)
    static let selectedBackground = Color(red: 0, green: 1, blue: 0)
    static let textPrimary = Color.white
    static let textSecondary = Color(.sRGB, white: 0.6, opacity: 1)
    static let cornerRadius: CGFloat = 24
    static let itemSpacing: CGFloat = 12
    static let sectionSpacing: CGFloat = 24
    static let pickerHeight: CGFloat = 200
}

// MARK: - Height Input with Scroll Wheels
struct UnifiedHeightPicker: View {
    @Binding var heightInInches: Int
    @Binding var isMetric: Bool
    @Environment(\.theme) var theme
    
    private var feet: Int {
        heightInInches / 12
    }
    
    private var inches: Int {
        heightInInches % 12
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "ruler")
                    .foregroundColor(ProfileInputTokens.selectedBackground)
                    .font(.system(size: 20))
                Text("Height")
                    .font(.title3.bold())
                    .foregroundColor(ProfileInputTokens.textPrimary)
            }
            
            if isMetric {
                // Metric display
                HStack {
                    ScrollWheelPicker(
                        value: Binding(
                            get: { Int(Double(heightInInches) * 2.54) },
                            set: { heightInInches = Int(Double($0) / 2.54) }
                        ),
                        range: 120...220,
                        label: "cm"
                    )
                }
            } else {
                // Imperial display
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Feet")
                            .font(.caption)
                            .foregroundColor(ProfileInputTokens.textSecondary)
                        
                        ScrollWheelPicker(
                            value: Binding(
                                get: { feet },
                                set: { newFeet in
                                    heightInInches = (newFeet * 12) + inches
                                }
                            ),
                            range: 3...7,
                            label: "'"
                        )
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Inches")
                            .font(.caption)
                            .foregroundColor(ProfileInputTokens.textSecondary)
                        
                        ScrollWheelPicker(
                            value: Binding(
                                get: { inches },
                                set: { newInches in
                                    heightInInches = (feet * 12) + newInches
                                }
                            ),
                            range: 0...11,
                            label: "\""
                        )
                    }
                }
            }
        }
        .padding(24)
        .background(ProfileInputTokens.cardBackground)
        .cornerRadius(ProfileInputTokens.cornerRadius)
    }
}

// MARK: - Weight Input with Scroll Wheel
struct UnifiedWeightPicker: View {
    @Binding var weightInPounds: Int
    @Binding var isMetric: Bool
    @Environment(\.theme) var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "scalemass")
                    .foregroundColor(ProfileInputTokens.selectedBackground)
                    .font(.system(size: 20))
                Text("Weight")
                    .font(.title3.bold())
                    .foregroundColor(ProfileInputTokens.textPrimary)
            }
            
            if isMetric {
                ScrollWheelPicker(
                    value: Binding(
                        get: { Int(Double(weightInPounds) / 2.205) },
                        set: { weightInPounds = Int(Double($0) * 2.205) }
                    ),
                    range: 30...200,
                    label: "kg"
                )
            } else {
                ScrollWheelPicker(
                    value: $weightInPounds,
                    range: 70...400,
                    label: "lbs"
                )
            }
        }
        .padding(24)
        .background(ProfileInputTokens.cardBackground)
        .cornerRadius(ProfileInputTokens.cornerRadius)
    }
}

// MARK: - Age Input with Scroll Wheel
struct UnifiedAgePicker: View {
    @Binding var age: Int
    @Environment(\.theme) var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .foregroundColor(ProfileInputTokens.selectedBackground)
                    .font(.system(size: 20))
                Text("Age")
                    .font(.title3.bold())
                    .foregroundColor(ProfileInputTokens.textPrimary)
            }
            
            ScrollWheelPicker(
                value: $age,
                range: 5...100,
                label: "years old"
            )
        }
        .padding(24)
        .background(ProfileInputTokens.cardBackground)
        .cornerRadius(ProfileInputTokens.cornerRadius)
    }
}

// MARK: - Gender Selection
struct UnifiedGenderPicker: View {
    @Binding var gender: String
    @Environment(\.theme) var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "person.2")
                    .foregroundColor(ProfileInputTokens.selectedBackground)
                    .font(.system(size: 20))
                Text("Gender")
                    .font(.title3.bold())
                    .foregroundColor(ProfileInputTokens.textPrimary)
            }
            
            VStack(spacing: 12) {
                GenderOption(
                    title: "Male",
                    icon: "person.fill",
                    isSelected: gender == "Male",
                    action: { gender = "Male" }
                )
                
                GenderOption(
                    title: "Female",
                    icon: "person.fill",
                    isSelected: gender == "Female",
                    action: { gender = "Female" }
                )
            }
        }
        .padding(24)
        .background(ProfileInputTokens.cardBackground)
        .cornerRadius(ProfileInputTokens.cornerRadius)
    }
}

// MARK: - Position Selection Grid
struct UnifiedPositionPicker: View {
    @Binding var position: String
    @Environment(\.theme) var theme
    
    let positions = [
        ("C", "Center", "sportscourt"),
        ("LW", "Left Wing", "sportscourt"),
        ("RW", "Right Wing", "sportscourt"),
        ("LD", "Left Defense", "shield.lefthalf.filled"),
        ("RD", "Right Defense", "shield.righthalf.filled"),
        ("G", "Goalie", "circle.hexagongrid")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "sportscourt")
                    .foregroundColor(ProfileInputTokens.selectedBackground)
                    .font(.system(size: 20))
                Text("Position")
                    .font(.title3.bold())
                    .foregroundColor(ProfileInputTokens.textPrimary)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(positions, id: \.0) { pos in
                    UnifiedPositionCard(
                        title: pos.0,
                        abbreviation: pos.1,
                        icon: pos.2,
                        isSelected: position == pos.0,
                        action: { position = pos.0 }
                    )
                }
            }
        }
        .padding(24)
        .background(ProfileInputTokens.cardBackground)
        .cornerRadius(ProfileInputTokens.cornerRadius)
    }
}

// MARK: - Shooting Hand Selection
struct UnifiedShootingHandPicker: View {
    @Binding var shootingHand: String
    @Environment(\.theme) var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "hockey.puck")
                    .foregroundColor(ProfileInputTokens.selectedBackground)
                    .font(.system(size: 20))
                Text("Shooting Hand")
                    .font(.title3.bold())
                    .foregroundColor(ProfileInputTokens.textPrimary)
            }
            
            HStack(spacing: 12) {
                ShootingHandCard(
                    hand: "Left",
                    isSelected: shootingHand == "Left",
                    action: { shootingHand = "Left" }
                )
                
                ShootingHandCard(
                    hand: "Right",
                    isSelected: shootingHand == "Right",
                    action: { shootingHand = "Right" }
                )
            }
        }
        .padding(24)
        .background(ProfileInputTokens.cardBackground)
        .cornerRadius(ProfileInputTokens.cornerRadius)
    }
}

// MARK: - Metric Toggle (Removed - using UnifiedInputComponents.swift version)

// MARK: - Supporting Components

struct ScrollWheelPicker: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let label: String
    
    var body: some View {
        HStack(spacing: 8) {
            Picker("", selection: $value) {
                ForEach(range, id: \.self) { number in
                    Text("\(number)")
                        .font(.system(size: 24, weight: .medium, design: .rounded))
                        .foregroundColor(ProfileInputTokens.textPrimary)
                        .tag(number)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 100, height: 120)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(ProfileInputTokens.selectedBackground, lineWidth: 2)
            )
            
            Text(label)
                .font(.body)
                .foregroundColor(ProfileInputTokens.textSecondary)
        }
    }
}

struct GenderOption: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.impact(.light)
            action()
        }) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? Color.black : ProfileInputTokens.textPrimary)
                
                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundColor(isSelected ? Color.black : ProfileInputTokens.textPrimary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.black)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? ProfileInputTokens.selectedBackground : Color(.sRGB, white: 0.15, opacity: 1))
            )
        }
    }
}

// Removed duplicate - using custom name to avoid conflict
private struct UnifiedPositionCard: View {
    let title: String        // Position abbreviation (e.g., "C")
    let abbreviation: String  // Full position name (e.g., "Center")
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.impact(.light)
            action()
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? Color.black : ProfileInputTokens.selectedBackground)
                
                Text(title)
                    .font(.headline.bold())
                    .foregroundColor(isSelected ? Color.black : ProfileInputTokens.textPrimary)
                
                Text(abbreviation)
                    .font(.caption2)
                    .foregroundColor(isSelected ? Color.black.opacity(0.8) : ProfileInputTokens.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? ProfileInputTokens.selectedBackground : Color(.sRGB, white: 0.15, opacity: 1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.clear : Color(.sRGB, white: 0.2, opacity: 1), lineWidth: 1)
                    )
            )
        }
    }
}

struct ShootingHandCard: View {
    let hand: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.impact(.light)
            action()
        }) {
            VStack(spacing: 12) {
                // Stick graphic
                ZStack {
                    Rectangle()
                        .fill(isSelected ? Color.black : ProfileInputTokens.textPrimary)
                        .frame(width: 3, height: 60)
                        .rotationEffect(.degrees(hand == "Left" ? -15 : 15))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isSelected ? Color.black : ProfileInputTokens.textPrimary)
                        .frame(width: 20, height: 8)
                        .offset(y: 30)
                        .rotationEffect(.degrees(hand == "Left" ? -15 : 15))
                }
                .frame(height: 80)
                
                Text("\(hand)")
                    .font(.headline)
                    .foregroundColor(isSelected ? Color.black : ProfileInputTokens.textPrimary)
                
                Text("Shot")
                    .font(.caption)
                    .foregroundColor(isSelected ? Color.black.opacity(0.8) : ProfileInputTokens.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? ProfileInputTokens.selectedBackground : Color(.sRGB, white: 0.15, opacity: 1))
            )
        }
    }
}

// MARK: - Section Header
struct ProfileSectionHeader: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text(title)
                .font(.largeTitle.bold())
                .foregroundColor(ProfileInputTokens.textPrimary)
            
            Text(subtitle)
                .font(.body)
                .foregroundColor(ProfileInputTokens.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

// MARK: - Progress Bar  
// Removed duplicate - using from UpdatedOnboardingFlow.swift
private struct UnifiedProgressBar: View {
    let progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color(.sRGB, white: 0.2, opacity: 1))
                    .frame(height: 4)
                
                Rectangle()
                    .fill(ProfileInputTokens.selectedBackground)
                    .frame(width: geometry.size.width * progress, height: 4)
            }
        }
        .frame(height: 4)
    }
}

// MARK: - Navigation Buttons
// Removed duplicate - using from UpdatedOnboardingFlow.swift  
private struct UnifiedNavigation: View {
    let showBack: Bool
    let showSkip: Bool
    let onBack: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        HStack {
            if showBack {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.body.weight(.medium))
                    .foregroundColor(ProfileInputTokens.selectedBackground)
                }
            }
            
            Spacer()
            
            if showSkip {
                Button(action: onSkip) {
                    Text("Skip")
                        .font(.body.weight(.medium))
                        .foregroundColor(ProfileInputTokens.textSecondary)
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Continue Button
struct ContinueActionButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.impact(.medium)
            action()
        }) {
            HStack {
                Image(systemName: "arrow.right")
                Text(title)
                    .font(.body.weight(.semibold))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(ProfileInputTokens.selectedBackground)
            .cornerRadius(ProfileInputTokens.cornerRadius)
        }
    }
}