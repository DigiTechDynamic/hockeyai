import SwiftUI

struct ProfileInputField: View {
    @Environment(\.theme) var theme
    let icon: String
    let label: String
    @Binding var text: String
    var unit: String? = nil
    var keyboardType: UIKeyboardType = .default
    var isNumeric: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            // Label
            HStack(spacing: theme.spacing.sm) {
                Image(systemName: icon)
                    .font(theme.fonts.body)
                    .foregroundColor(theme.textSecondary)
                Text(label)
                    .font(theme.fonts.caption)
                    .foregroundColor(theme.textSecondary)
            }
            
            // Input field
            HStack {
                TextField("", text: $text)
                    .font(theme.fonts.title)
                    .foregroundColor(theme.text)
                    .keyboardType(keyboardType)
                    .onChange(of: text) { newValue in
                        if isNumeric {
                            let filtered = newValue.filter { $0.isNumber || $0 == "." }
                            if filtered != newValue {
                                text = filtered
                            }
                        }
                    }
                
                if let unit = unit {
                    Text(unit)
                        .font(theme.fonts.body)
                        .foregroundColor(theme.textSecondary)
                }
            }
            .padding(.horizontal, theme.spacing.md)
            .padding(.vertical, theme.spacing.md)
            .background(theme.surface.opacity(0.6))
            .cornerRadius(12)
        }
    }
}

struct ProfilePickerField<T: Hashable>: View {
    @Environment(\.theme) var theme
    let icon: String
    let label: String
    @Binding var selection: T
    let options: [T]
    let displayName: (T) -> String
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            // Label
            HStack(spacing: theme.spacing.sm) {
                Image(systemName: icon)
                    .font(theme.fonts.body)
                    .foregroundColor(theme.textSecondary)
                Text(label)
                    .font(theme.fonts.caption)
                    .foregroundColor(theme.textSecondary)
            }
            
            // Picker
            Menu {
                ForEach(options, id: \.self) { option in
                    Button(action: { selection = option }) {
                        HStack {
                            Text(displayName(option))
                            if selection == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(displayName(selection))
                        .font(theme.fonts.bodyBold)
                        .foregroundColor(theme.text)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(theme.fonts.caption)
                        .foregroundColor(theme.textSecondary)
                }
                .padding(.horizontal, theme.spacing.md)
                .padding(.vertical, theme.spacing.md)
                .background(theme.surface.opacity(0.6))
                .cornerRadius(12)
            }
        }
    }
}

struct ProfileSegmentedField: View {
    @Environment(\.theme) var theme
    let icon: String
    let label: String
    @Binding var selection: String
    let options: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            // Label
            HStack(spacing: theme.spacing.sm) {
                Image(systemName: icon)
                    .font(theme.fonts.body)
                    .foregroundColor(theme.textSecondary)
                Text(label)
                    .font(theme.fonts.caption)
                    .foregroundColor(theme.textSecondary)
            }
            
            // Segmented control
            HStack(spacing: 0) {
                ForEach(options, id: \.self) { option in
                    Button(action: { selection = option }) {
                        Text(option)
                            .font(theme.fonts.button)
                            .foregroundColor(selection == option ? .white : theme.text)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, theme.spacing.sm)
                            .background(
                                selection == option ? theme.primary : Color.clear
                            )
                    }
                }
            }
            .background(theme.surface.opacity(0.6))
            .cornerRadius(10)
        }
    }
}

struct ProfileUnitToggle: View {
    @Environment(\.theme) var theme
    let label: String
    @Binding var useMetric: Bool
    let metricLabel: String
    let imperialLabel: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(theme.fonts.body)
                .foregroundColor(theme.text)
            
            Spacer()
            
            HStack(spacing: 0) {
                Button(action: { useMetric = false }) {
                    Text(imperialLabel)
                        .font(theme.fonts.caption)
                        .foregroundColor(!useMetric ? .white : theme.textSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(!useMetric ? theme.primary : Color.clear)
                }
                
                Button(action: { useMetric = true }) {
                    Text(metricLabel)
                        .font(theme.fonts.caption)
                        .foregroundColor(useMetric ? .white : theme.textSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(useMetric ? theme.primary : Color.clear)
                }
            }
            .background(theme.surface)
            .cornerRadius(8)
        }
    }
}