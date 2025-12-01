import SwiftUI

// MARK: - Body Setup Screen (Height, Weight, Gender)
struct BodySetupScreen: View {
    @Environment(\.theme) var theme
    @ObservedObject var viewModel: OnboardingViewModel
    @ObservedObject var coordinator: OnboardingFlowCoordinator

    @State private var appeared = false
    @StateObject private var keyboard = KeyboardObserver()
    @State private var selectedGender: Gender?
    @State private var useMetric: Bool = false

    // Imperial height
    @State private var heightFeet: Int = 5
    @State private var heightInches: Int = 6

    // Metric height
    @State private var heightCm: Int = 170

    @State private var weight: String = ""
    @FocusState private var weightFocused: Bool

    private let feetOptions = Array(3...7)
    private let inchesOptions = Array(0...11)
    private let cmOptions = Array(100...220)

    private var canContinue: Bool {
        guard selectedGender != nil else { return false }
        guard let weightInt = Int(weight) else { return false }
        let minWeight = useMetric ? 18 : 40
        let maxWeight = useMetric ? 180 : 400
        guard weightInt >= minWeight && weightInt <= maxWeight else { return false }
        return true
    }

    private var totalHeightInches: Int {
        if useMetric {
            return Int(Double(heightCm) / 2.54)
        } else {
            return (heightFeet * 12) + heightInches
        }
    }

    private var heightDisplay: String {
        if useMetric {
            return "\(heightCm) cm"
        } else {
            return "\(heightFeet)'\(heightInches)\""
        }
    }

    private var weightValidation: Bool {
        guard let weightInt = Int(weight) else { return false }
        let minWeight = useMetric ? 18 : 40
        let maxWeight = useMetric ? 180 : 400
        return weightInt >= minWeight && weightInt <= maxWeight
    }

    var body: some View {
        ZStack {
            BackgroundAnimationView(type: .energyWaves, isActive: true, intensity: 0.25)
                .ignoresSafeArea()

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Spacer(minLength: 40)

                        // Header
                        VStack(spacing: theme.spacing.sm) {
                            Text("Your body stats")
                                .font(.system(size: 32, weight: .black))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 20)
                                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: appeared)

                            Text("Used for equipment recommendations")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(theme.textSecondary)
                                .multilineTextAlignment(.center)
                                .opacity(appeared ? 1 : 0)
                                .animation(.easeOut(duration: 0.4).delay(0.1), value: appeared)
                        }
                        .padding(.horizontal, theme.spacing.lg)
                        .padding(.bottom, theme.spacing.xl)

                    // Form fields
                    VStack(spacing: theme.spacing.lg) {
                        // Gender selection
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Gender")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(theme.text)
                                Text("*")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(theme.primary)
                            }

                            HStack(spacing: 12) {
                                ForEach(Gender.allCases, id: \.self) { gender in
                                    Button {
                                        HapticManager.shared.playImpact(style: .light)
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedGender = gender
                                        }
                                    } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: gender == .male ? "figure.stand" : "figure.stand.dress")
                                                .font(.system(size: 20))

                                            Text(gender.rawValue)
                                                .font(.system(size: 16, weight: .semibold))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(selectedGender == gender ? theme.primary.opacity(0.15) : theme.surface)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(selectedGender == gender ? theme.primary : theme.divider, lineWidth: selectedGender == gender ? 2 : 1)
                                                )
                                        )
                                        .foregroundColor(selectedGender == gender ? theme.primary : theme.text)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.15), value: appeared)

                        // Height selection
                        VStack(alignment: .leading, spacing: 12) {
                            // Label with inline unit toggle
                            HStack {
                                Text("Height")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(theme.text)
                                Text("*")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(theme.primary)

                                Spacer()

                                // Inline unit toggle
                                unitToggle(leftLabel: "ft", rightLabel: "cm", isRight: useMetric) {
                                    toggleUnits()
                                }
                            }

                            if useMetric {
                                // Metric: Single cm picker
                                Picker("Height", selection: $heightCm) {
                                    ForEach(cmOptions, id: \.self) { cm in
                                        Text("\(cm) cm")
                                            .tag(cm)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(height: 120)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(theme.surface)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(theme.divider, lineWidth: 1)
                                        )
                                )
                                .clipped()
                            } else {
                                // Imperial: Feet and Inches pickers
                                HStack(spacing: 16) {
                                    VStack(spacing: 4) {
                                        Text("Feet")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(theme.textSecondary)

                                        Picker("Feet", selection: $heightFeet) {
                                            ForEach(feetOptions, id: \.self) { feet in
                                                Text("\(feet)'")
                                                    .tag(feet)
                                            }
                                        }
                                        .pickerStyle(.wheel)
                                        .frame(height: 120)
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(theme.surface)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(theme.divider, lineWidth: 1)
                                                )
                                        )
                                        .clipped()
                                    }

                                    VStack(spacing: 4) {
                                        Text("Inches")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(theme.textSecondary)

                                        Picker("Inches", selection: $heightInches) {
                                            ForEach(inchesOptions, id: \.self) { inches in
                                                Text("\(inches)\"")
                                                    .tag(inches)
                                            }
                                        }
                                        .pickerStyle(.wheel)
                                        .frame(height: 120)
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(theme.surface)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(theme.divider, lineWidth: 1)
                                                )
                                        )
                                        .clipped()
                                    }
                                }
                            }

                            // Height display
                            HStack {
                                Spacer()
                                Text(heightDisplay)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(theme.primary)
                                if !useMetric {
                                    Text("(\(totalHeightInches) inches)")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(theme.textSecondary)
                                }
                                Spacer()
                            }
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.25), value: appeared)

                        // Weight field
                        VStack(alignment: .leading, spacing: 8) {
                            // Label with inline unit toggle
                            HStack {
                                Text("Weight")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(theme.text)
                                Text("*")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(theme.primary)

                                Spacer()

                                // Inline unit toggle
                                unitToggle(leftLabel: "lbs", rightLabel: "kg", isRight: useMetric) {
                                    toggleUnits()
                                }
                            }

                            HStack(spacing: 12) {
                                Image(systemName: "scalemass.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(theme.primary)
                                    .frame(width: 24)

                                TextField("", text: $weight)
                                    .placeholder(when: weight.isEmpty) {
                                        Text(useMetric ? "Enter weight" : "Enter weight")
                                            .foregroundColor(theme.textSecondary.opacity(0.6))
                                    }
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(theme.text)
                                    .keyboardType(.numberPad)
                                    .focused($weightFocused)
                                    .onChange(of: weight) { newValue in
                                        if newValue.count > 3 {
                                            weight = String(newValue.prefix(3))
                                        }
                                        weight = newValue.filter { $0.isNumber }
                                    }

                                Text(useMetric ? "kg" : "lbs")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(theme.primary)

                                if weightValidation {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(theme.primary)
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(theme.surface)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(weightFocused ? theme.primary : theme.divider, lineWidth: weightFocused ? 2 : 1)
                                    )
                            )
                        }
                        .id("weightField")
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.35), value: appeared)
                    }
                    .padding(.horizontal, theme.spacing.lg)

                    Spacer(minLength: 20)
                }
                .scrollDismissesKeyboard(.interactively)
                .keyboardAdaptive()
                .padding(.bottom,  keyboard.keyboardHeight > 0 ? 12 : 100) // Space for fixed button when keyboard hidden
                .onChange(of: weightFocused) { focused in
                    if focused {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo("weightField", anchor: .center)
                        }
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            // Fixed bottom CTA - matches welcome screen positioning
            VStack(spacing: theme.spacing.sm) {
                AppButton(title: "Continue", action: {
                    HapticManager.shared.playImpact(style: .medium)
                    saveBodyData()
                    weightFocused = false
                    coordinator.navigateForward()
                })
                .buttonStyle(.primary)
                .withIcon("arrow.right")
                .buttonSize(.large)
                .disabled(!canContinue)
                .padding(.horizontal, theme.spacing.lg)

                // Maintain footer height consistency when keyboard hidden
                Text(" ")
                    .font(theme.fonts.body)
                    .foregroundColor(.clear)
                    .frame(height: keyboard.keyboardHeight > 0 ? 0 : 44)
            }
            .padding(.bottom, keyboard.keyboardHeight > 0 ? 0 : theme.spacing.lg)
            .background(
                LinearGradient(
                    colors: [.clear, theme.background.opacity(0.9), theme.background],
                    startPoint: .top,
                    endPoint: .center
                )
            )
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.4), value: appeared)
        }
        .onAppear {
            appeared = true
            HapticManager.shared.playNotification(type: .success)
        }
        .onTapGesture {
            weightFocused = false
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    weightFocused = false
                }
                .fontWeight(.semibold)
            }
        }
    }
    // Close body before helper functions
    }
    
    // MARK: - Inline Unit Toggle

    @ViewBuilder
    private func unitToggle(leftLabel: String, rightLabel: String, isRight: Bool, action: @escaping () -> Void) -> some View {
        HStack(spacing: 0) {
            Button {
                if isRight { action() }
            } label: {
                Text(leftLabel)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(!isRight ? .white : theme.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(!isRight ? theme.primary : Color.clear)
                    )
            }
            .buttonStyle(.plain)

            Button {
                if !isRight { action() }
            } label: {
                Text(rightLabel)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isRight ? .white : theme.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isRight ? theme.primary : Color.clear)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(2)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.surface)
        )
    }

    // MARK: - Unit Toggle Action

    private func toggleUnits() {
        HapticManager.shared.playImpact(style: .light)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if useMetric {
                convertToImperial()
            } else {
                convertToMetric()
            }
            useMetric.toggle()
        }
    }

    // MARK: - Conversion Functions

    private func convertToMetric() {
        let totalInches = (heightFeet * 12) + heightInches
        heightCm = Int(Double(totalInches) * 2.54)

        if let weightLbs = Int(weight), weightLbs > 0 {
            let weightKg = Int(Double(weightLbs) / 2.20462)
            weight = String(weightKg)
        }
    }

    private func convertToImperial() {
        let totalInches = Int(Double(heightCm) / 2.54)
        heightFeet = totalInches / 12
        heightInches = totalInches % 12

        if let weightKg = Int(weight), weightKg > 0 {
            let weightLbs = Int(Double(weightKg) * 2.20462)
            weight = String(weightLbs)
        }
    }

    private func saveBodyData() {
        var profile = viewModel.playerProfile ?? PlayerProfile()
        profile.gender = selectedGender
        profile.height = Double(totalHeightInches)

        if let weightValue = Int(weight) {
            if useMetric {
                profile.weight = Double(weightValue) * 2.20462
            } else {
                profile.weight = Double(weightValue)
            }
        }

        viewModel.playerProfile = profile
        UserDefaults.standard.set(useMetric, forKey: "useMetricHeightUnits")
    }
}
