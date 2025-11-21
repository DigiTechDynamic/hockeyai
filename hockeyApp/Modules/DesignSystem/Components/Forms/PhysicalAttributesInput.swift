import SwiftUI

// MARK: - Physical Attributes Input Component
/// Unified component for inputting height, weight, and age
/// Works across: Profile Settings, Onboarding, and any other context
/// Uses the PhysicalAttributes model for type safety and automatic conversions

struct PhysicalAttributesInput: View {
    @Environment(\.theme) private var theme
    @Binding var attributes: PhysicalAttributes

    /// Which fields to show
    let fields: Set<Field>

    /// Presentation style (affects layout and interaction)
    let style: Style

    /// Whether to show unit toggle inline
    let showUnitToggle: Bool

    enum Field: Hashable {
        case height
        case weight
        case age
    }

    enum Style {
        case compact        // Single-line rows (Profile settings)
        case stepper        // Stepper controls (Profile sheets)
        case picker         // Wheel pickers (Onboarding)
        case inline         // Inline editing
    }

    init(
        attributes: Binding<PhysicalAttributes>,
        fields: Set<Field> = [.height, .weight, .age],
        style: Style = .compact,
        showUnitToggle: Bool = true
    ) {
        self._attributes = attributes
        self.fields = fields
        self.style = style
        self.showUnitToggle = showUnitToggle
    }

    var body: some View {
        switch style {
        case .compact:
            compactView
        case .stepper:
            stepperView
        case .picker:
            pickerView
        case .inline:
            inlineView
        }
    }

    // MARK: - Compact Style (Profile Settings)
    @ViewBuilder
    private var compactView: some View {
        VStack(spacing: 12) {
            if showUnitToggle && needsUnitToggle {
                unitToggleView
            }

            if fields.contains(.height) {
                compactRow(
                    icon: "ruler",
                    title: "Height",
                    value: attributes.heightDisplay,
                    action: { /* Show sheet */ }
                )
            }

            if fields.contains(.weight) {
                compactRow(
                    icon: "scalemass",
                    title: "Weight",
                    value: attributes.weightDisplay,
                    action: { /* Show sheet */ }
                )
            }

            if fields.contains(.age) {
                compactRow(
                    icon: "calendar",
                    title: "Age",
                    value: attributes.ageDisplayWithUnit,
                    action: { /* Show sheet */ }
                )
            }
        }
    }

    private func compactRow(icon: String, title: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(theme.fonts.body)
                    .foregroundColor(theme.textSecondary)
                    .frame(width: 20)

                Text(title)
                    .font(theme.fonts.body)
                    .foregroundColor(theme.textSecondary)

                Spacer()

                Text(value)
                    .font(theme.fonts.body)
                    .foregroundColor(.white)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Stepper Style (Profile Sheets)
    @ViewBuilder
    private var stepperView: some View {
        VStack(spacing: 24) {
            if fields.contains(.height) {
                heightStepperEditor
            }

            if fields.contains(.weight) {
                weightStepperEditor
            }

            if fields.contains(.age) {
                ageStepperEditor
            }
        }
    }

    private var heightStepperEditor: some View {
        VStack(spacing: 24) {
            Text(attributes.heightDisplayCompact)
                .font(.system(size: 64, weight: .bold))
                .foregroundStyle(LinearGradient(
                    colors: [theme.primary, theme.accent],
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .frame(maxWidth: .infinity)

            // Unit toggle
            if showUnitToggle {
                heightUnitToggle
            }

            if attributes.useMetric {
                // CM stepper
                HStack(spacing: 16) {
                    stepperButton(icon: "minus") {
                        attributes.setHeight(cm: attributes.heightCm - 1)
                    }

                    Text("CM")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(theme.textSecondary.opacity(0.7))
                        .frame(maxWidth: .infinity)

                    stepperButton(icon: "plus") {
                        attributes.setHeight(cm: attributes.heightCm + 1)
                    }
                }
                .padding(.horizontal, 24)
            } else {
                // Feet/Inches steppers
                VStack(spacing: 18) {
                    HStack(spacing: 16) {
                        stepperButton(icon: "minus") {
                            attributes.setHeight(feet: attributes.heightFeet - 1, inches: attributes.heightRemainingInches)
                        }

                        Text("FEET")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(theme.textSecondary.opacity(0.7))
                            .frame(maxWidth: .infinity)

                        stepperButton(icon: "plus") {
                            attributes.setHeight(feet: attributes.heightFeet + 1, inches: attributes.heightRemainingInches)
                        }
                    }

                    HStack(spacing: 16) {
                        stepperButton(icon: "minus") {
                            attributes.setHeight(feet: attributes.heightFeet, inches: attributes.heightRemainingInches - 1)
                        }

                        Text("INCHES")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(theme.textSecondary.opacity(0.7))
                            .frame(maxWidth: .infinity)

                        stepperButton(icon: "plus") {
                            attributes.setHeight(feet: attributes.heightFeet, inches: attributes.heightRemainingInches + 1)
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }

    private var weightStepperEditor: some View {
        VStack(spacing: 24) {
            Text(attributes.weightDisplayCompact)
                .font(.system(size: 64, weight: .bold))
                .foregroundStyle(LinearGradient(
                    colors: [theme.primary, theme.accent],
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .frame(maxWidth: .infinity)

            // Unit toggle
            if showUnitToggle {
                weightUnitToggle
            }

            HStack(spacing: 16) {
                stepperButton(icon: "minus") {
                    if attributes.useMetric {
                        attributes.setWeight(kg: attributes.weightKg - 1)
                    } else {
                        attributes.setWeight(pounds: attributes.weightPounds - 1)
                    }
                }

                Text(attributes.useMetric ? "KG" : "LBS")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(theme.textSecondary.opacity(0.7))
                    .frame(maxWidth: .infinity)

                stepperButton(icon: "plus") {
                    if attributes.useMetric {
                        attributes.setWeight(kg: attributes.weightKg + 1)
                    } else {
                        attributes.setWeight(pounds: attributes.weightPounds + 1)
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }

    private var ageStepperEditor: some View {
        VStack(spacing: 24) {
            Text(attributes.ageDisplay)
                .font(.system(size: 64, weight: .bold))
                .foregroundStyle(LinearGradient(
                    colors: [theme.primary, theme.accent],
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .frame(maxWidth: .infinity)

            HStack(spacing: 16) {
                stepperButton(icon: "minus") {
                    attributes.setAge(attributes.age - 1)
                }

                Text("YEARS")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(theme.textSecondary.opacity(0.7))
                    .frame(maxWidth: .infinity)

                stepperButton(icon: "plus") {
                    attributes.setAge(attributes.age + 1)
                }
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Picker Style (Onboarding)
    @ViewBuilder
    private var pickerView: some View {
        VStack(spacing: 20) {
            if fields.contains(.height) {
                heightPickerEditor
            }

            if fields.contains(.weight) {
                weightPickerEditor
            }

            if fields.contains(.age) {
                agePickerEditor
            }
        }
    }

    private var heightPickerEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "ruler")
                    .foregroundColor(theme.primary)
                Text("Height")
                    .font(.headline)
                    .foregroundColor(theme.primary)
            }

            if attributes.useMetric {
                // CM Picker
                VStack(spacing: 8) {
                    Text("Centimeters")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)

                    Picker("CM", selection: Binding(
                        get: { attributes.heightCm },
                        set: { attributes.setHeight(cm: $0) }
                    )) {
                        ForEach(120...250, id: \.self) { cm in
                            Text("\(cm)").tag(cm)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)
                }
            } else {
                // Feet/Inches Pickers
                HStack(spacing: 16) {
                    VStack {
                        Text("Feet")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)

                        Picker("Feet", selection: Binding(
                            get: { attributes.heightFeet },
                            set: { attributes.setHeight(feet: $0, inches: attributes.heightRemainingInches) }
                        )) {
                            ForEach(3...7, id: \.self) { ft in
                                Text("\(ft)'").tag(ft)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 80, height: 120)
                    }

                    VStack {
                        Text("Inches")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)

                        Picker("Inches", selection: Binding(
                            get: { attributes.heightRemainingInches },
                            set: { attributes.setHeight(feet: attributes.heightFeet, inches: $0) }
                        )) {
                            ForEach(0...11, id: \.self) { inch in
                                Text("\(inch)\"").tag(inch)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 80, height: 120)
                    }
                }
            }
        }
        .padding()
        .background(theme.cardBackground)
        .cornerRadius(16)
    }

    private var weightPickerEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "scalemass")
                    .foregroundColor(theme.primary)
                Text("Weight")
                    .font(.headline)
                    .foregroundColor(theme.primary)
            }

            VStack(spacing: 8) {
                Text(attributes.useMetric ? "Kilograms" : "Pounds")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)

                if attributes.useMetric {
                    Picker("Weight", selection: Binding(
                        get: { Int(attributes.weightKg.rounded()) },
                        set: { attributes.setWeight(kg: Double($0)) }
                    )) {
                        ForEach(30...200, id: \.self) { kg in
                            Text("\(kg)").tag(kg)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)
                } else {
                    Picker("Weight", selection: Binding(
                        get: { attributes.weightLbs },
                        set: { attributes.setWeight(pounds: Double($0)) }
                    )) {
                        ForEach(66...441, id: \.self) { lbs in
                            Text("\(lbs)").tag(lbs)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)
                }
            }
        }
        .padding()
        .background(theme.cardBackground)
        .cornerRadius(16)
    }

    private var agePickerEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(theme.primary)
                Text("Age")
                    .font(.headline)
                    .foregroundColor(theme.primary)
            }

            VStack(spacing: 8) {
                Text("Years")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)

                Picker("Age", selection: Binding(
                    get: { attributes.age },
                    set: { attributes.setAge($0) }
                )) {
                    ForEach(5...100, id: \.self) { year in
                        Text("\(year)").tag(year)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 120)
            }
        }
        .padding()
        .background(theme.cardBackground)
        .cornerRadius(16)
    }

    // MARK: - Inline Style
    @ViewBuilder
    private var inlineView: some View {
        // Similar to compact but with direct text field editing
        Text("Inline style - TBD")
    }

    // MARK: - Supporting Views

    private var needsUnitToggle: Bool {
        fields.contains(.height) || fields.contains(.weight)
    }

    private var unitToggleView: some View {
        HStack {
            Text("Unit System")
                .font(theme.fonts.body)
                .foregroundColor(.white)

            Spacer()

            Picker("Units", selection: $attributes.useMetric) {
                Text("Imperial").tag(false)
                Text("Metric").tag(true)
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(width: 180)
        }
    }

    private var heightUnitToggle: some View {
        HStack(spacing: 4) {
            unitSegment("ft", selected: !attributes.useMetric) {
                attributes.setUseMetric(false)
                HapticManager.shared.playSelection()
            }
            unitSegment("cm", selected: attributes.useMetric) {
                attributes.setUseMetric(true)
                HapticManager.shared.playSelection()
            }
        }
        .padding(4)
        .background(RoundedRectangle(cornerRadius: 10).fill(theme.surface.opacity(0.3)))
    }

    private var weightUnitToggle: some View {
        HStack(spacing: 4) {
            unitSegment("lbs", selected: !attributes.useMetric) {
                attributes.setUseMetric(false)
                HapticManager.shared.playSelection()
            }
            unitSegment("kg", selected: attributes.useMetric) {
                attributes.setUseMetric(true)
                HapticManager.shared.playSelection()
            }
        }
        .padding(4)
        .background(RoundedRectangle(cornerRadius: 10).fill(theme.surface.opacity(0.3)))
    }

    private func unitSegment(_ text: String, selected: Bool, action: @escaping () -> Void) -> some View {
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

    private func stepperButton(icon: String, action: @escaping () -> Void) -> some View {
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
    }
}

// MARK: - Preview
#if DEBUG
struct PhysicalAttributesInput_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            // Compact style
            PhysicalAttributesInput(
                attributes: .constant(.preview),
                style: .compact
            )
            .previewDisplayName("Compact")

            // Stepper style
            PhysicalAttributesInput(
                attributes: .constant(.preview),
                fields: [.height],
                style: .stepper
            )
            .previewDisplayName("Stepper")

            // Picker style
            PhysicalAttributesInput(
                attributes: .constant(.preview),
                fields: [.height],
                style: .picker
            )
            .previewDisplayName("Picker")
        }
        .padding()
        .background(Color.black)
    }
}
#endif
