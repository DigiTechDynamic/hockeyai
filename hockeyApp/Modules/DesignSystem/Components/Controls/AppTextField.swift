import SwiftUI

enum AppTextFieldStyle {
    case filled
    case outlined
    case underlined
}

struct AppTextField: View {
    @Environment(\.theme) var theme
    @FocusState private var isFocused: Bool
    
    let placeholder: String
    @Binding var text: String
    var style: AppTextFieldStyle = .filled
    var icon: String? = nil
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences
    var errorMessage: String? = nil
    var helperText: String? = nil
    
    @State private var showPassword = false
    
    var showError: Bool {
        errorMessage != nil && !errorMessage!.isEmpty
    }
    
    var borderColor: Color {
        if showError {
            return theme.error
        } else if isFocused {
            return theme.primary
        } else {
            return theme.divider
        }
    }
    
    var fieldBackground: Color {
        switch style {
        case .filled:
            return theme.inputBackground
        case .outlined, .underlined:
            return Color.clear
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            HStack(spacing: theme.spacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(isFocused ? theme.primary : theme.textSecondary)
                        .font(.system(size: 18))
                        .frame(width: 24)
                }
                
                ZStack(alignment: .leading) {
                    if text.isEmpty {
                        Text(placeholder)
                            .foregroundColor(theme.textSecondary.opacity(0.7))
                            .font(theme.fonts.body)
                    }
                    
                    Group {
                        if isSecure && !showPassword {
                            SecureField("", text: $text)
                        } else {
                            TextField("", text: $text)
                                .keyboardType(keyboardType)
                                .textInputAutocapitalization(autocapitalization)
                        }
                    }
                    .foregroundColor(theme.text)
                    .font(theme.fonts.body)
                    .focused($isFocused)
                }
                
                if isSecure {
                    Button(action: { showPassword.toggle() }) {
                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(theme.textSecondary)
                            .font(.system(size: 16))
                    }
                }
            }
            .padding(.horizontal, theme.spacing.md)
            .padding(.vertical, theme.spacing.sm + 4)
            .background(fieldBackground)
            .overlay(
                Group {
                    switch style {
                    case .filled:
                        RoundedRectangle(cornerRadius: AppSettings.Constants.Layout.cornerRadiusMedium)
                            .stroke(borderColor, lineWidth: showError || isFocused ? 2 : 1)
                    case .outlined:
                        RoundedRectangle(cornerRadius: AppSettings.Constants.Layout.cornerRadiusMedium)
                            .stroke(borderColor, lineWidth: showError || isFocused ? 2 : 1)
                    case .underlined:
                        VStack {
                            Spacer()
                            Rectangle()
                                .fill(borderColor)
                                .frame(height: showError || isFocused ? 2 : 1)
                        }
                    }
                }
            )
            .cornerRadius(style == .underlined ? 0 : AppSettings.Constants.Layout.cornerRadiusMedium)
            .animation(theme.animations.quick, value: isFocused)
            .animation(theme.animations.quick, value: showError)
            
            if let errorMessage = errorMessage, showError {
                Text(errorMessage)
                    .font(theme.fonts.caption)
                    .foregroundColor(theme.error)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            } else if let helperText = helperText {
                Text(helperText)
                    .font(theme.fonts.caption)
                    .foregroundColor(theme.textSecondary)
                    .transition(.opacity)
            }
        }
    }
}

// Convenience modifiers
extension AppTextField {
    func textFieldStyle(_ style: AppTextFieldStyle) -> AppTextField {
        var field = self
        field.style = style
        return field
    }
    
    func withIcon(_ icon: String) -> AppTextField {
        var field = self
        field.icon = icon
        return field
    }
    
    func secure(_ isSecure: Bool = true) -> AppTextField {
        var field = self
        field.isSecure = isSecure
        return field
    }
    
    func keyboard(_ type: UIKeyboardType) -> AppTextField {
        var field = self
        field.keyboardType = type
        return field
    }
    
    func capitalization(_ type: TextInputAutocapitalization) -> AppTextField {
        var field = self
        field.autocapitalization = type
        return field
    }
    
    func error(_ message: String?) -> AppTextField {
        var field = self
        field.errorMessage = message
        return field
    }
    
    func helper(_ text: String?) -> AppTextField {
        var field = self
        field.helperText = text
        return field
    }
}