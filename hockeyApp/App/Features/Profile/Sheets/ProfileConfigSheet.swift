import SwiftUI

// MARK: - Unified Profile Config Sheet
// Mirrors the structure and styling patterns used by ExerciseConfigSheet
// so every profile editor uses one consistent UI implementation.
struct ProfileConfigSheet: View {
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss

    enum Kind: Equatable {
        case height
        case weight
        case age
        case gender
        case position
        case handedness
        case playStyle
        case jerseyNumber
    }

    @ObservedObject var viewModel: ProfileViewModel
    let kind: Kind

    // Fast-selection sheets
    @State private var showHeightPicker = false
    @State private var showWeightPicker = false
    @State private var showAgePicker = false

    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            header

            // Configuration area
            content
                .frame(maxWidth: .infinity, alignment: .top)
                .padding(.bottom, 0)

            Spacer(minLength: 0)

            bottomActions
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(theme.background.ignoresSafeArea())
        // Quick-select sheets for faster entry
        .sheet(isPresented: $showHeightPicker) {
            // Bridge feet/inches to total inches binding
            let totalInches = Binding<Int>(
                get: { viewModel.heightFeet * 12 + viewModel.heightInches },
                set: { newValue in
                    viewModel.heightFeet = max(0, newValue) / 12
                    viewModel.heightInches = max(0, newValue) % 12
                }
            )
            HeightPickerView(
                heightInInches: totalInches,
                isMetric: $viewModel.useMetric,
                isPresented: $showHeightPicker
            )
        }
        .sheet(isPresented: $showWeightPicker) {
            // Bridge string weight to pounds binding, respecting unit toggle
            let poundsBinding = Binding<Int>(
                get: {
                    let raw = Int(viewModel.weight) ?? 0
                    return viewModel.useMetric ? Int(Double(raw) * 2.20462) : raw
                },
                set: { newPounds in
                    if viewModel.useMetric {
                        let kg = Int(Double(newPounds) * 0.453592)
                        viewModel.weight = "\(kg)"
                    } else {
                        viewModel.weight = "\(newPounds)"
                    }
                }
            )
            WeightPickerView(
                weightInPounds: poundsBinding,
                isMetric: $viewModel.useMetric,
                isPresented: $showWeightPicker
            )
        }
        .sheet(isPresented: $showAgePicker) {
            let ageBinding = Binding<Int>(
                get: { Int(viewModel.age) ?? 0 },
                set: { viewModel.age = String($0) }
            )
            AgePickerView(age: ageBinding, isPresented: $showAgePicker)
        }
    }

    // MARK: - Header
    private var header: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text(title.uppercased())
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 24)
            .padding(.horizontal, 24)
            .padding(.bottom, 12)

            // Divider identical to ExerciseConfig header
            Rectangle()
                .fill(theme.textSecondary.opacity(0.2))
                .frame(height: 1)
                .padding(.horizontal, 24)
        }
    }

    // MARK: - Content
    @ViewBuilder
    private var content: some View {
        Group {
            switch kind {
            case .height: heightEditor
            case .weight: weightEditor
            case .age: ageEditor
            case .gender: genderEditor
            case .position: positionEditor
            case .handedness: handednessEditor
            case .playStyle: playStyleEditor
            case .jerseyNumber: jerseyNumberEditor
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    // MARK: - Bottom actions (Save only for profile)
    private var bottomActions: some View {
        VStack(spacing: 12) {
            Button(action: {
                // Haptics only (no Apple system sound)
                HapticManager.shared.playNotification(type: .success)
                viewModel.saveProfile()
                dismiss()
            }) {
                Text("Save")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(theme.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(theme.primary.opacity(0.12))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(theme.primary.opacity(0.5), lineWidth: 2)
                    )
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 34)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.95), Color.black],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: - Unit Toggle Segment
    private func segment(_ text: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(selected ? .white : theme.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(selected ? theme.primary.opacity(0.3) : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(selected ? theme.primary : theme.textSecondary.opacity(0.3), lineWidth: 1)
                )
        }
    }

    // MARK: - Editors

    private var heightEditor: some View {
        VStack(spacing: 24) {
            Text(heightDisplay)
                .font(.system(size: 64, weight: .bold))
                .foregroundStyle(LinearGradient(colors: [theme.primary, theme.accent], startPoint: .top, endPoint: .bottom))
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    // Open fast wheel picker
                    showHeightPicker = true
                }

            // Unit toggle for height
            HStack(spacing: 4) {
                segment("ft", selected: !viewModel.useMetric) {
                    viewModel.updateUseMetric(false)
                    HapticManager.shared.playSelection()
                }
                segment("cm", selected: viewModel.useMetric) {
                    viewModel.updateUseMetric(true)
                    HapticManager.shared.playSelection()
                }
            }
            .padding(4)
            .background(RoundedRectangle(cornerRadius: 10).fill(theme.surface.opacity(0.3)))

            if viewModel.useMetric {
                // Wheel for centimeters
                let cmBinding = Binding<Int>(
                    get: {
                        Int(Double(viewModel.heightFeet * 12 + viewModel.heightInches) * 2.54)
                    },
                    set: { newCm in
                        let newInches = Int(Double(max(120, min(250, newCm))) / 2.54)
                        viewModel.heightFeet = newInches / 12
                        viewModel.heightInches = newInches % 12
                        HapticManager.shared.playSelection()
                    }
                )
                VStack(spacing: 8) {
                    Picker("Centimeters", selection: cmBinding) {
                        ForEach(120...250, id: \.self) { cm in
                            Text("\(cm) cm").tag(cm)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 160)
                    .background(theme.surface.opacity(0.4))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 24)
            } else {
                // Dual wheel for feet and inches
                let feetBinding = Binding<Int>(
                    get: { viewModel.heightFeet },
                    set: { newFeet in
                        viewModel.heightFeet = max(3, min(7, newFeet))
                        HapticManager.shared.playSelection()
                    }
                )
                let inchesBinding = Binding<Int>(
                    get: { viewModel.heightInches },
                    set: { newInches in
                        viewModel.heightInches = max(0, min(11, newInches))
                        HapticManager.shared.playSelection()
                    }
                )
                HStack(spacing: 24) {
                    VStack(spacing: 6) {
                        Text("Feet").font(.caption).foregroundColor(theme.textSecondary)
                        Picker("Feet", selection: feetBinding) {
                            ForEach(3...7, id: \.self) { ft in Text("\(ft)'").tag(ft) }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 110, height: 160)
                        .background(theme.surface.opacity(0.4))
                        .cornerRadius(12)
                    }
                    VStack(spacing: 6) {
                        Text("Inches").font(.caption).foregroundColor(theme.textSecondary)
                        Picker("Inches", selection: inchesBinding) {
                            ForEach(0...11, id: \.self) { inch in Text("\(inch)\"").tag(inch) }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 110, height: 160)
                        .background(theme.surface.opacity(0.4))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }

    private var weightEditor: some View {
        let weightValue = Int(viewModel.weight) ?? 0

        return VStack(spacing: 24) {
            Text("\(weightValue)")
                .font(.system(size: 64, weight: .bold))
                .foregroundStyle(LinearGradient(colors: [theme.primary, theme.accent], startPoint: .top, endPoint: .bottom))
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture { showWeightPicker = true }

            // Unit toggle for weight
            HStack(spacing: 4) {
                segment("lbs", selected: !viewModel.useMetric) {
                    viewModel.updateUseMetric(false)
                    HapticManager.shared.playSelection()
                }
                segment("kg", selected: viewModel.useMetric) {
                    viewModel.updateUseMetric(true)
                    HapticManager.shared.playSelection()
                }
            }
            .padding(4)
            .background(RoundedRectangle(cornerRadius: 10).fill(theme.surface.opacity(0.3)))

            // Inline wheel pickers for fast selection
            if viewModel.useMetric {
                let kgBinding = Binding<Int>(
                    get: { Int(Double(Int(viewModel.weight) ?? 0)) },
                    set: { newKg in
                        viewModel.weight = "\(newKg)" // store display in metric; ViewModel converts on save
                        if newKg % 5 == 0 { HapticManager.shared.playSelectionFeedback() } else { HapticManager.shared.playSelection() }
                    }
                )
                Picker("Kilograms", selection: kgBinding) {
                    ForEach(30...200, id: \.self) { kg in
                        Text("\(kg) kg").tag(kg)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 160)
                .background(theme.surface.opacity(0.4))
                .cornerRadius(12)
                .padding(.horizontal, 24)
            } else {
                let lbsBinding = Binding<Int>(
                    get: { Int(viewModel.weight) ?? 0 },
                    set: { newLbs in
                        viewModel.weight = "\(newLbs)"
                        if newLbs % 5 == 0 { HapticManager.shared.playSelectionFeedback() } else { HapticManager.shared.playSelection() }
                    }
                )
                Picker("Pounds", selection: lbsBinding) {
                    ForEach(60...400, id: \.self) { lbs in
                        Text("\(lbs) lbs").tag(lbs)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 160)
                .background(theme.surface.opacity(0.4))
                .cornerRadius(12)
                .padding(.horizontal, 24)
            }
        }
    }

    private var ageEditor: some View {
        let ageValue = Int(viewModel.age) ?? 0

        return VStack(spacing: 24) {
            Text("\(ageValue)")
                .font(.system(size: 64, weight: .bold))
                .foregroundStyle(LinearGradient(colors: [theme.primary, theme.accent], startPoint: .top, endPoint: .bottom))
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture { showAgePicker = true }

            let ageBinding = Binding<Int>(
                get: { Int(viewModel.age) ?? 0 },
                set: { newAge in
                    viewModel.age = "\(newAge)"
                    HapticManager.shared.playSelection()
                }
            )
            Picker("Age", selection: ageBinding) {
                ForEach(5...100, id: \.self) { year in
                    Text("\(year)").tag(year)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 160)
            .background(theme.surface.opacity(0.4))
            .cornerRadius(12)
            .padding(.horizontal, 24)
        }
    }

    private var genderEditor: some View {
        VStack(spacing: 12) {
            ForEach(Gender.allCases, id: \.self) { gender in
                Button(action: {
                    HapticManager.shared.playSelection()
                    viewModel.updateGender(gender)
                }) {
                    HStack {
                        Image(systemName: gender.icon)
                            .foregroundColor(viewModel.selectedGender == .some(gender) ? theme.background : theme.primary)
                        Text(gender.rawValue)
                            .foregroundColor(viewModel.selectedGender == .some(gender) ? theme.background : .white)
                        Spacer()
                        if viewModel.selectedGender == .some(gender) {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(theme.background)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(viewModel.selectedGender == .some(gender) ? theme.primary : theme.surface.opacity(0.3))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 24)
    }

    private var positionEditor: some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: columns, spacing: 14) {
            ForEach(Position.allCases, id: \.self) { position in
                Button(action: {
                    HapticManager.shared.playSelection()
                    viewModel.updatePosition(position)
                }) {
                    VStack(spacing: 6) {
                        Image(systemName: position.icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(viewModel.selectedPosition == .some(position) ? .black : theme.primary)
                        Text(position.abbreviation)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(viewModel.selectedPosition == .some(position) ? .black : .white)
                        Text(position.rawValue)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(viewModel.selectedPosition == .some(position) ? Color.black.opacity(0.75) : theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(viewModel.selectedPosition == .some(position) ? theme.primary : theme.cardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(viewModel.selectedPosition == .some(position) ? Color.clear : theme.primary.opacity(0.15), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 24)
    }

    private var handednessEditor: some View {
        VStack(spacing: 12) {
            ForEach(Handedness.allCases, id: \.self) { hand in
                Button(action: {
                    HapticManager.shared.playSelection()
                    viewModel.updateHandedness(hand)
                }) {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(viewModel.selectedHandedness == .some(hand) ? .black : theme.primary)
                                .frame(width: 6, height: 44)
                                .rotationEffect(.degrees(hand == .left ? -15 : 15))

                            RoundedRectangle(cornerRadius: 3)
                                .fill(viewModel.selectedHandedness == .some(hand) ? .black : theme.primary)
                                .frame(width: 24, height: 6)
                                .offset(x: hand == .left ? -10 : 10, y: 21)
                        }
                        .frame(width: 52, height: 52)

                        Text("\(hand.rawValue) Shot")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(viewModel.selectedHandedness == .some(hand) ? .black : .white)
                        Spacer()
                        if viewModel.selectedHandedness == .some(hand) {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.black)
                        }
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(viewModel.selectedHandedness == .some(hand) ? theme.primary : theme.cardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(viewModel.selectedHandedness == .some(hand) ? Color.clear : theme.primary.opacity(0.15), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 24)
    }

    private var playStyleEditor: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(PlayStyle.stylesForPosition(viewModel.selectedPosition), id: \.self) { style in
                    Button(action: {
                        HapticManager.shared.playSelection()
                        viewModel.updatePlayStyle(style)
                    }) {
                        HStack(alignment: .center, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(style.rawValue)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(viewModel.selectedPlayStyle == style ? .black : .white)
                                Text(style.description)
                                    .font(.system(size: 13))
                                    .foregroundColor(viewModel.selectedPlayStyle == style ? Color.black.opacity(0.75) : theme.textSecondary)
                            }
                            Spacer()
                            if viewModel.selectedPlayStyle == style {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.black)
                            }
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(viewModel.selectedPlayStyle == style ? theme.primary : theme.cardBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(viewModel.selectedPlayStyle == style ? Color.clear : theme.primary.opacity(0.15), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 8)
        }
    }

    private var jerseyNumberEditor: some View {
        VStack(spacing: 24) {
            let numberValue = Int(viewModel.jerseyNumber) ?? 0

            Text(numberValue > 0 ? "#\(numberValue)" : "--")
                .font(.system(size: 64, weight: .bold))
                .foregroundStyle(LinearGradient(colors: [theme.primary, theme.accent], startPoint: .top, endPoint: .bottom))
                .frame(maxWidth: .infinity)

            let numberBinding = Binding<Int>(
                get: { Int(viewModel.jerseyNumber) ?? 0 },
                set: { newNumber in
                    viewModel.jerseyNumber = "\(newNumber)"
                    HapticManager.shared.playSelection()
                }
            )
            Picker("Number", selection: numberBinding) {
                ForEach(0...99, id: \.self) { number in
                    Text("\(number)").tag(number)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 160)
            .background(theme.surface.opacity(0.4))
            .cornerRadius(12)
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Helpers
    private var title: String {
        switch kind {
        case .height: return "Height"
        case .weight: return "Weight"
        case .age: return "Age"
        case .gender: return "Gender"
        case .position: return "Position"
        case .handedness: return "Shooting Hand"
        case .playStyle: return "Play Style"
        case .jerseyNumber: return "Jersey Number"
        }
    }

    private var heightDisplay: String {
        if viewModel.useMetric {
            let cm = Int(Double(viewModel.heightFeet * 12 + viewModel.heightInches) * 2.54)
            return "\(cm)"
        } else {
            return "\(viewModel.heightFeet)' \(viewModel.heightInches)\""
        }
    }

    // MARK: - Buttons (copied style from ExerciseConfigSheet)
    // Accelerated press-and-hold stepper button
    private func stepperButton(icon: String, action: @escaping () -> Void) -> some View {
        AutoRepeatButton(icon: icon, action: action)
    }
}

// MARK: - AutoRepeatButton (press-and-hold with acceleration)
private struct AutoRepeatButton: View {
    @Environment(\.theme) private var theme
    let icon: String
    let action: () -> Void

    @State private var timer: Timer?
    @State private var holdStart: Date?

    private func startRepeating() {
        holdStart = Date()
        // Fire first repeat shortly after hold begins
        scheduleTimer(interval: 0.18)
    }

    private func scheduleTimer(interval: TimeInterval) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            // Determine how long the user has been holding to accelerate
            let elapsed = -(holdStart?.timeIntervalSinceNow ?? 0)
            // Calls per tick increases over time for fast changes
            let repeats: Int
            switch elapsed {
            case 0..<0.8: repeats = 1
            case 0.8..<1.5: repeats = 2
            case 1.5..<2.5: repeats = 5
            default: repeats = 10
            }
            for _ in 0..<repeats { action() }

            // Tighten interval once as user keeps holding
            if elapsed > 1.5, (timer?.timeInterval ?? 0.2) > 0.08 {
                scheduleTimer(interval: 0.08)
            } else if elapsed > 2.5, (timer?.timeInterval ?? 0.2) > 0.05 {
                scheduleTimer(interval: 0.05)
            }
        }
        RunLoop.current.add(timer!, forMode: .common)
    }

    private func stopRepeating() {
        timer?.invalidate()
        timer = nil
        holdStart = nil
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(theme.primary)
                .frame(width: 60, height: 60)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.surface.opacity(0.3))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(theme.primary.opacity(0.25), lineWidth: 1)
                )
        }
        .onLongPressGesture(minimumDuration: 0.25, pressing: { pressing in
            if pressing { startRepeating() } else { stopRepeating() }
        }, perform: {})
        .onDisappear { stopRepeating() }
    }
}
