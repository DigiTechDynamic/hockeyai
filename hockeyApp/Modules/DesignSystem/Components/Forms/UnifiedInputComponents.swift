import SwiftUI

// MARK: - Design System: Unified Input Components
// Inspired by: Strava (data input), Nike Training Club (visual hierarchy), Peloton (engagement)

// MARK: - Core Design Tokens
struct InputDesignTokens {
    // Spacing
    static let itemSpacing: CGFloat = 12
    static let sectionSpacing: CGFloat = 24
    static let cardPadding: CGFloat = 16
    
    // Corner Radius
    static let inputRadius: CGFloat = 12
    static let cardRadius: CGFloat = 16
    static let buttonRadius: CGFloat = 10
    
    // Heights
    static let inputHeight: CGFloat = 56
    static let compactInputHeight: CGFloat = 44
    static let segmentHeight: CGFloat = 40
    
    // Animation
    static let springAnimation = Animation.spring(response: 0.35, dampingFraction: 0.8)
    static let quickAnimation = Animation.easeInOut(duration: 0.2)
}

// MARK: - Unified Height Input Component
struct UnifiedHeightInput: View {
    @Environment(\.theme) var theme
    @Binding var heightInInches: Int
    @Binding var isMetric: Bool
    
    // Visual states
    @State private var isExpanded = false
    @State private var showingPopup = false
    @FocusState private var isFocused: Bool
    
    private var feet: Int {
        heightInInches / 12
    }
    
    private var inches: Int {
        heightInInches % 12
    }
    
    private var centimeters: Int {
        Int(Double(heightInInches) * 2.54)
    }
    
    var body: some View {
        VStack(spacing: InputDesignTokens.itemSpacing) {
            // Compact display with expand button
            Button(action: { 
                withAnimation(InputDesignTokens.springAnimation) {
                    showingPopup = true
                }
                HapticManager.shared.playImpact(style: .light)
            }) {
                HStack {
                    Label("Height", systemImage: "ruler")
                        .font(.callout)
                        .foregroundColor(theme.textSecondary)
                    
                    Spacer()
                    
                    // Current value display
                    HStack(spacing: 4) {
                        if isMetric {
                            Text("\(centimeters)")
                                .font(.headline.monospacedDigit())
                            Text("cm")
                                .font(.caption)
                                .foregroundColor(theme.textSecondary)
                        } else {
                            Text("\(feet)'\(inches)\"")
                                .font(.headline.monospacedDigit())
                        }
                    }
                    .foregroundColor(theme.text)
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                        .rotationEffect(.degrees(showingPopup ? 90 : 0))
                }
                .padding(.horizontal, InputDesignTokens.cardPadding)
                .frame(height: InputDesignTokens.inputHeight)
                .background(theme.surface)
                .cornerRadius(InputDesignTokens.inputRadius)
                .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
            }
            .buttonStyle(UnifiedScaleButtonStyle())
        }
        .sheet(isPresented: $showingPopup) {
            HeightInputSheet(
                heightInInches: $heightInInches,
                isMetric: $isMetric,
                isPresented: $showingPopup
            )
        }
    }
}

// MARK: - Height Input Sheet (Modal)
struct HeightInputSheet: View {
    @Environment(\.theme) var theme
    @Binding var heightInInches: Int
    @Binding var isMetric: Bool
    @Binding var isPresented: Bool
    
    @State private var tempHeight: Int
    @State private var tempMetric: Bool
    @State private var feet: Int = 5
    @State private var inches: Int = 10
    
    init(heightInInches: Binding<Int>, isMetric: Binding<Bool>, isPresented: Binding<Bool>) {
        self._heightInInches = heightInInches
        self._isMetric = isMetric
        self._isPresented = isPresented
        let initialHeight = heightInInches.wrappedValue
        self._tempHeight = State(initialValue: initialHeight)
        self._tempMetric = State(initialValue: isMetric.wrappedValue)
        self._feet = State(initialValue: initialHeight / 12)
        self._inches = State(initialValue: initialHeight % 12)
    }
    
    private var centimeters: Int {
        Int(Double(tempHeight) * 2.54)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: InputDesignTokens.sectionSpacing) {
                // Visual height comparison (like Nike Training Club)
                HeightVisualization(heightInInches: tempHeight)
                    .frame(height: 120)
                    .padding(.top)
                
                // Unit toggle (like Strava)
                Picker("Units", selection: $tempMetric) {
                    Text("Imperial").tag(false)
                    Text("Metric").tag(true)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Input area
                if tempMetric {
                    // Metric input with slider (like Peloton)
                    VStack(spacing: 8) {
                        HStack {
                            Text("\(centimeters)")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundColor(theme.primary)
                            Text("cm")
                                .font(.title3)
                                .foregroundColor(theme.textSecondary)
                                .offset(y: 8)
                        }
                        
                        Slider(value: Binding(
                            get: { Double(centimeters) },
                            set: { newValue in
                                let newHeightInInches = Int(Double(newValue) / 2.54)
                                self.tempHeight = newHeightInInches
                                self.feet = newHeightInInches / 12
                                self.inches = newHeightInInches % 12
                            }
                        ), in: 120...220, step: 1)
                        .accentColor(theme.primary)
                        .padding(.horizontal)
                    }
                } else {
                    // Imperial input with dual pickers
                    HStack(spacing: InputDesignTokens.sectionSpacing) {
                        // Feet picker
                        VStack {
                            Text("Feet")
                                .font(.caption)
                                .foregroundColor(theme.textSecondary)
                            
                            Picker("Feet", selection: $feet.onChange { _ in
                                tempHeight = feet * 12 + inches
                            }) {
                                ForEach(3...7, id: \.self) { ft in
                                    Text("\(ft)'").tag(ft)
                                        .font(.title2.monospacedDigit())
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: 80, height: 120)
                            .clipped()
                        }
                        
                        // Inches picker
                        VStack {
                            Text("Inches")
                                .font(.caption)
                                .foregroundColor(theme.textSecondary)
                            
                            Picker("Inches", selection: $inches.onChange { _ in
                                tempHeight = feet * 12 + inches
                            }) {
                                ForEach(0...11, id: \.self) { inch in
                                    Text("\(inch)\"").tag(inch)
                                        .font(.title2.monospacedDigit())
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: 80, height: 120)
                            .clipped()
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
                    .foregroundColor(theme.textSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        heightInInches = tempHeight
                        isMetric = tempMetric
                        isPresented = false
                        HapticManager.shared.playNotification(type: .success)
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primary)
                }
            }
        }
    }
}

// MARK: - Height Visualization Component
struct HeightVisualization: View {
    @Environment(\.theme) var theme
    let heightInInches: Int
    
    private var heightPercentage: Double {
        // Map 4'0" (48") to 7'0" (84") to 0.3 to 1.0
        let minHeight = 48.0
        let maxHeight = 84.0
        let normalized = Double(heightInInches - Int(minHeight)) / (maxHeight - minHeight)
        return 0.3 + (normalized * 0.7)
    }
    
    var body: some View {
        HStack(spacing: 32) {
            // Player silhouette
            ZStack(alignment: .bottom) {
                // Reference lines
                VStack(spacing: 0) {
                    ForEach([7, 6, 5, 4], id: \.self) { feet in
                        HStack {
                            Text("\(feet)'")
                                .font(.caption2)
                                .foregroundColor(theme.textSecondary)
                            
                            Rectangle()
                                .fill(theme.divider.opacity(0.3))
                                .frame(height: 0.5)
                        }
                        .frame(height: 25)
                    }
                }
                
                // Player figure
                Image(systemName: "figure.stand")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 100 * heightPercentage)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [theme.primary, theme.primary.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .animation(InputDesignTokens.springAnimation, value: heightInInches)
            }
            .frame(width: 120, height: 100)
            
            // Comparison to average
            VStack(alignment: .leading, spacing: 8) {
                Text("Comparison")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
                
                if heightInInches < 67 {
                    Label("Below average", systemImage: "arrow.down.circle.fill")
                        .font(.callout)
                        .foregroundColor(theme.info)
                } else if heightInInches > 73 {
                    Label("Above average", systemImage: "arrow.up.circle.fill")
                        .font(.callout)
                        .foregroundColor(theme.success)
                } else {
                    Label("Average height", systemImage: "checkmark.circle.fill")
                        .font(.callout)
                        .foregroundColor(theme.success)
                }
                
                Text("NHL avg: 6'1\"")
                    .font(.caption2)
                    .foregroundColor(theme.textSecondary)
            }
        }
        .padding()
        .background(theme.surface)
        .cornerRadius(InputDesignTokens.cardRadius)
    }
}

// MARK: - Unified Weight Input Component
struct UnifiedWeightInput: View {
    @Environment(\.theme) var theme
    @Binding var weightInPounds: Int
    @Binding var isMetric: Bool
    
    @State private var showingPopup = false
    @FocusState private var isFocused: Bool
    
    private var kilograms: Int {
        Int(Double(weightInPounds) / 2.205)
    }
    
    var body: some View {
        Button(action: {
            withAnimation(InputDesignTokens.springAnimation) {
                showingPopup = true
            }
            HapticManager.shared.playImpact(style: .light)
        }) {
            HStack {
                Label("Weight", systemImage: "scalemass")
                    .font(.callout)
                    .foregroundColor(theme.textSecondary)
                
                Spacer()
                
                HStack(spacing: 4) {
                    if isMetric {
                        Text("\(kilograms)")
                            .font(.headline.monospacedDigit())
                        Text("kg")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                    } else {
                        Text("\(weightInPounds)")
                            .font(.headline.monospacedDigit())
                        Text("lbs")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                    }
                }
                .foregroundColor(theme.text)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
            }
            .padding(.horizontal, InputDesignTokens.cardPadding)
            .frame(height: InputDesignTokens.inputHeight)
            .background(theme.surface)
            .cornerRadius(InputDesignTokens.inputRadius)
            .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
        }
        .buttonStyle(UnifiedScaleButtonStyle())
        .sheet(isPresented: $showingPopup) {
            WeightInputSheet(
                weightInPounds: $weightInPounds,
                isMetric: $isMetric,
                isPresented: $showingPopup
            )
        }
    }
}

// MARK: - Weight Input Sheet
struct WeightInputSheet: View {
    @Environment(\.theme) var theme
    @Binding var weightInPounds: Int
    @Binding var isMetric: Bool
    @Binding var isPresented: Bool
    
    @State private var tempWeight: Int
    @State private var tempMetric: Bool
    
    init(weightInPounds: Binding<Int>, isMetric: Binding<Bool>, isPresented: Binding<Bool>) {
        self._weightInPounds = weightInPounds
        self._isMetric = isMetric
        self._isPresented = isPresented
        self._tempWeight = State(initialValue: weightInPounds.wrappedValue)
        self._tempMetric = State(initialValue: isMetric.wrappedValue)
    }
    
    private var displayWeight: Int {
        tempMetric ? Int(Double(tempWeight) / 2.205) : tempWeight
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: InputDesignTokens.sectionSpacing) {
                // BMI visualization (like MyFitnessPal)
                WeightVisualization(weightInPounds: tempWeight)
                    .frame(height: 120)
                    .padding(.top)
                
                // Unit toggle
                Picker("Units", selection: $tempMetric) {
                    Text("Imperial").tag(false)
                    Text("Metric").tag(true)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Weight input with slider
                VStack(spacing: 16) {
                    HStack(alignment: .lastTextBaseline) {
                        Text("\(displayWeight)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(theme.primary)
                        Text(tempMetric ? "kg" : "lbs")
                            .font(.title3)
                            .foregroundColor(theme.textSecondary)
                    }
                    
                    // Quick adjustment buttons (like Peloton)
                    HStack(spacing: 16) {
                        ForEach([-5, -1, 1, 5], id: \.self) { adjustment in
                            Button(action: {
                                let newWeight = tempWeight + (tempMetric ? Int(Double(adjustment) * 2.205) : adjustment)
                                tempWeight = max(50, min(400, newWeight))
                                HapticManager.shared.playImpact(style: .light)
                            }) {
                                Text("\(adjustment > 0 ? "+" : "")\(adjustment)")
                                    .font(.callout.monospacedDigit())
                                    .fontWeight(.medium)
                                    .frame(width: 60, height: 40)
                                    .background(theme.surface)
                                    .cornerRadius(InputDesignTokens.buttonRadius)
                                    .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
                            }
                            .buttonStyle(UnifiedScaleButtonStyle())
                        }
                    }
                    
                    // Slider
                    Slider(value: Binding(
                        get: { Double(tempWeight) },
                        set: { tempWeight = Int($0) }
                    ), in: 50...400, step: 1)
                    .accentColor(theme.primary)
                    .padding(.horizontal)
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
                    .foregroundColor(theme.textSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        weightInPounds = tempWeight
                        isMetric = tempMetric
                        isPresented = false
                        HapticManager.shared.playNotification(type: .success)
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primary)
                }
            }
        }
    }
}

// MARK: - Weight Visualization
struct WeightVisualization: View {
    @Environment(\.theme) var theme
    let weightInPounds: Int
    
    private var bmi: Double {
        // Assuming average height of 70 inches for visualization
        let heightInches = 70.0
        return (Double(weightInPounds) / (heightInches * heightInches)) * 703
    }
    
    private var bmiCategory: (text: String, color: Color) {
        switch bmi {
        case ..<18.5: return ("Underweight", theme.warning)
        case 18.5..<25: return ("Healthy", theme.success)
        case 25..<30: return ("Overweight", theme.warning)
        default: return ("Obese", theme.error)
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // BMI gauge (like Fitbit)
            ZStack {
                // Background arc
                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(theme.divider, lineWidth: 8)
                    .rotationEffect(.degrees(135))
                
                // BMI arc
                Circle()
                    .trim(from: 0, to: min(0.75, (bmi - 15) / 25 * 0.75))
                    .stroke(
                        AngularGradient(
                            colors: [theme.success, theme.warning, theme.error],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(135))
                
                // Center text
                VStack(spacing: 4) {
                    Text(String(format: "%.1f", bmi))
                        .font(.title2.bold().monospacedDigit())
                    Text("BMI")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }
            }
            .frame(width: 100, height: 100)
            
            // Category
            Text(bmiCategory.text)
                .font(.callout.bold())
                .foregroundColor(bmiCategory.color)
        }
        .padding()
        .background(theme.surface)
        .cornerRadius(InputDesignTokens.cardRadius)
    }
}

// MARK: - Unified Age Input
struct UnifiedAgeInput: View {
    @Environment(\.theme) var theme
    @Binding var age: Int
    
    @State private var showingPicker = false
    
    var body: some View {
        Button(action: {
            showingPicker = true
            HapticManager.shared.playImpact(style: .light)
        }) {
            HStack {
                Label("Age", systemImage: "calendar")
                    .font(.callout)
                    .foregroundColor(theme.textSecondary)
                
                Spacer()
                
                Text("\(age) years")
                    .font(.headline)
                    .foregroundColor(theme.text)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
            }
            .padding(.horizontal, InputDesignTokens.cardPadding)
            .frame(height: InputDesignTokens.inputHeight)
            .background(theme.surface)
            .cornerRadius(InputDesignTokens.inputRadius)
            .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
        }
        .buttonStyle(UnifiedScaleButtonStyle())
        .sheet(isPresented: $showingPicker) {
            AgePickerSheet(age: $age, isPresented: $showingPicker)
        }
    }
}

// MARK: - Age Picker Sheet
struct AgePickerSheet: View {
    @Environment(\.theme) var theme
    @Binding var age: Int
    @Binding var isPresented: Bool
    @State private var tempAge: Int
    
    init(age: Binding<Int>, isPresented: Binding<Bool>) {
        self._age = age
        self._isPresented = isPresented
        self._tempAge = State(initialValue: age.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Age category visualization
                AgeVisualization(age: tempAge)
                    .padding()
                
                Picker("Age", selection: $tempAge) {
                    ForEach(5...100, id: \.self) { age in
                        Text("\(age) years").tag(age)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(height: 200)
                
                Spacer()
            }
            .navigationTitle("Age")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(theme.textSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        age = tempAge
                        isPresented = false
                        HapticManager.shared.playNotification(type: .success)
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primary)
                }
            }
        }
    }
}

// MARK: - Age Visualization
struct AgeVisualization: View {
    @Environment(\.theme) var theme
    let age: Int
    
    private var category: (name: String, icon: String, color: Color) {
        switch age {
        case 5...12: return ("Youth", "figure.child", theme.info)
        case 13...17: return ("Junior", "figure.stand", theme.primary)
        case 18...25: return ("Young Adult", "figure.run", theme.success)
        case 26...35: return ("Prime", "star.fill", theme.warning)
        case 36...45: return ("Veteran", "shield.fill", theme.secondary)
        default: return ("Master", "crown.fill", theme.accent)
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: category.icon)
                .font(.largeTitle)
                .foregroundColor(category.color)
                .frame(width: 60, height: 60)
                .background(category.color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(category.name)
                    .font(.headline)
                    .foregroundColor(theme.text)
                
                Text("Hockey Category")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
            }
            
            Spacer()
        }
        .padding()
        .background(theme.surface)
        .cornerRadius(InputDesignTokens.cardRadius)
    }
}

// MARK: - Unified Gender Selection
struct UnifiedGenderSelection: View {
    @Environment(\.theme) var theme
    @Binding var gender: String
    
    let options = [
        ("Male", "figure.stand", Color.blue),
        ("Female", "figure.stand", Color.pink),
        ("Other", "person.fill", Color.purple)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Gender")
                .font(.callout)
                .foregroundColor(theme.textSecondary)
            
            HStack(spacing: 12) {
                ForEach(options, id: \.0) { option in
                    GenderOptionCard(
                        title: option.0,
                        icon: option.1,
                        color: option.2,
                        isSelected: gender == option.0,
                        action: {
                            withAnimation(InputDesignTokens.springAnimation) {
                                gender = option.0
                            }
                            HapticManager.shared.playImpact(style: .light)
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Gender Option Card
struct GenderOptionCard: View {
    @Environment(\.theme) var theme
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : color)
                    .frame(width: 50, height: 50)
                    .background(
                        ZStack {
                            if isSelected {
                                LinearGradient(
                                    colors: [color, color.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            } else {
                                color.opacity(0.1)
                            }
                        }
                    )
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(isSelected ? color : Color.clear, lineWidth: 2)
                    )
                
                Text(title)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? theme.primary : theme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(theme.surface)
            .cornerRadius(InputDesignTokens.inputRadius)
            .shadow(color: isSelected ? color.opacity(0.2) : Color.black.opacity(0.05), 
                   radius: isSelected ? 4 : 2, 
                   y: isSelected ? 2 : 1)
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(UnifiedScaleButtonStyle())
    }
}

// MARK: - Unified Position Selection
struct UnifiedPositionSelection: View {
    @Environment(\.theme) var theme
    @Binding var position: String
    
    let positions = [
        ("Center", "C", "figure.hockey"),
        ("Left Wing", "LW", "arrow.left"),
        ("Right Wing", "RW", "arrow.right"),
        ("Defense", "D", "shield.fill"),
        ("Goalie", "G", "sportscourt.fill")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Position")
                .font(.callout)
                .foregroundColor(theme.textSecondary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(positions, id: \.1) { pos in
                    UnifiedPositionCardComponent(
                        title: pos.0,
                        abbreviation: pos.1,
                        icon: pos.2,
                        isSelected: position == pos.1,
                        action: {
                            withAnimation(InputDesignTokens.springAnimation) {
                                position = pos.1
                            }
                            HapticManager.shared.playImpact(style: .medium)
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Position Card (Inspired by ESPN)
// Renamed to avoid conflict with UnifiedProfileInputs.swift
struct UnifiedPositionCardComponent: View {
    @Environment(\.theme) var theme
    let title: String
    let abbreviation: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                // Position icon with gradient
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [theme.primary, theme.primary.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                    } else {
                        Circle()
                            .stroke(theme.divider, lineWidth: 2)
                            .frame(width: 44, height: 44)
                    }
                    
                    Text(abbreviation)
                        .font(.headline.bold())
                        .foregroundColor(isSelected ? .white : theme.textSecondary)
                }
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(isSelected ? theme.primary : theme.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? theme.primary.opacity(0.08) : theme.surface)
            .cornerRadius(InputDesignTokens.inputRadius)
            .overlay(
                RoundedRectangle(cornerRadius: InputDesignTokens.inputRadius)
                    .stroke(isSelected ? theme.primary : Color.clear, lineWidth: 2)
            )
            .shadow(color: isSelected ? theme.primary.opacity(0.2) : Color.black.opacity(0.05),
                   radius: isSelected ? 4 : 2,
                   y: isSelected ? 2 : 1)
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(UnifiedScaleButtonStyle())
    }
}

// MARK: - Unified Handedness Selection
struct UnifiedHandednessSelection: View {
    @Environment(\.theme) var theme
    @Binding var handedness: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Shoots")
                .font(.callout)
                .foregroundColor(theme.textSecondary)
            
            HStack(spacing: 12) {
                HandednessCard(
                    title: "Left",
                    isSelected: handedness == "Left",
                    isLeft: true,
                    action: {
                        withAnimation(InputDesignTokens.springAnimation) {
                            handedness = "Left"
                        }
                        HapticManager.shared.playImpact(style: .medium)
                    }
                )
                
                HandednessCard(
                    title: "Right",
                    isSelected: handedness == "Right",
                    isLeft: false,
                    action: {
                        withAnimation(InputDesignTokens.springAnimation) {
                            handedness = "Right"
                        }
                        HapticManager.shared.playImpact(style: .medium)
                    }
                )
            }
        }
    }
}

// MARK: - Handedness Card (Visual like Nike)
struct HandednessCard: View {
    @Environment(\.theme) var theme
    let title: String
    let isSelected: Bool
    let isLeft: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Visual stick representation
                ZStack {
                    // Stick shaft
                    Rectangle()
                        .fill(isSelected ? theme.primary : theme.divider)
                        .frame(width: 4, height: 60)
                        .rotationEffect(.degrees(isLeft ? -15 : 15))
                    
                    // Stick blade
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isSelected ? theme.primary : theme.divider)
                        .frame(width: 20, height: 8)
                        .offset(x: isLeft ? -8 : 8, y: 28)
                        .rotationEffect(.degrees(isLeft ? -15 : 15))
                    
                    // Hands indicator
                    Circle()
                        .fill(isSelected ? theme.accent : theme.textSecondary)
                        .frame(width: 8, height: 8)
                        .offset(y: -20)
                }
                .frame(height: 70)
                
                Text(title)
                    .font(.callout)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? theme.primary : theme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? theme.primary.opacity(0.08) : theme.surface)
            .cornerRadius(InputDesignTokens.cardRadius)
            .overlay(
                RoundedRectangle(cornerRadius: InputDesignTokens.cardRadius)
                    .stroke(isSelected ? theme.primary : Color.clear, lineWidth: 2)
            )
            .shadow(color: isSelected ? theme.primary.opacity(0.2) : Color.black.opacity(0.05),
                   radius: isSelected ? 4 : 2,
                   y: isSelected ? 2 : 1)
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(UnifiedScaleButtonStyle())
    }
}

// MARK: - Unified Metric Toggle
struct UnifiedMetricToggle: View {
    @Environment(\.theme) var theme
    @Binding var isMetric: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Unit System")
                .font(.caption)
                .foregroundColor(theme.textSecondary)
            
            HStack(spacing: 0) {
                Button(action: {
                    withAnimation(InputDesignTokens.springAnimation) {
                        isMetric = false
                    }
                    HapticManager.shared.playImpact(style: .light)
                }) {
                    Text("Imperial")
                        .font(.callout.weight(isMetric ? .regular : .semibold))
                        .foregroundColor(isMetric ? theme.textSecondary : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(isMetric ? Color.clear : theme.primary)
                        .unifiedCornerRadius(InputDesignTokens.buttonRadius, corners: [.topLeft, .bottomLeft])
                }
                
                Button(action: {
                    withAnimation(InputDesignTokens.springAnimation) {
                        isMetric = true
                    }
                    HapticManager.shared.playImpact(style: .light)
                }) {
                    Text("Metric")
                        .font(.callout.weight(isMetric ? .semibold : .regular))
                        .foregroundColor(isMetric ? .white : theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(isMetric ? theme.primary : Color.clear)
                        .unifiedCornerRadius(InputDesignTokens.buttonRadius, corners: [.topRight, .bottomRight])
                }
            }
            .background(theme.surface)
            .cornerRadius(InputDesignTokens.buttonRadius)
            .overlay(
                RoundedRectangle(cornerRadius: InputDesignTokens.buttonRadius)
                    .stroke(theme.primary, lineWidth: 1)
            )
        }
    }
}

// MARK: - Supporting Components

// Scale button style for consistent interactions
struct UnifiedScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// Corner radius extension for selective corners
// Note: If RoundedCorner is already defined elsewhere in the project,
// remove this implementation and use the existing one
extension View {
    func unifiedCornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(UnifiedRoundedCorner(radius: radius, corners: corners))
    }
}

struct UnifiedRoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Binding Extension
extension Binding {
    func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { newValue in
                self.wrappedValue = newValue
                handler(newValue)
            }
        )
    }
}

// Note: HapticManager is imported from SharedServices module
// Use: HapticManager.shared.playImpact(style: .light)
// Use: HapticManager.shared.playNotification(type: .success)
// Use: HapticManager.shared.playSelection()