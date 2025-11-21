import SwiftUI

// MARK: - App Form Component
public struct AppForm<Content: View>: View {
    @Environment(\.theme) private var theme
    
    public let style: AppFormStyle
    public let content: Content
    
    public init(
        style: AppFormStyle = .standard,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.content = content()
    }
    
    public var body: some View {
        VStack(spacing: style.sectionSpacing(theme)) {
            content
        }
        .padding(style.contentPadding(theme))
        .background(style.background(theme))
        .cornerRadius(style.cornerRadius(theme))
    }
}

// MARK: - App Form Style
public enum AppFormStyle {
    case standard
    case compact
    case modal
    case settings
    
    func sectionSpacing(_ theme: AppTheme) -> CGFloat {
        switch self {
        case .standard: return theme.spacing.lg
        case .compact: return theme.spacing.md
        case .modal: return theme.spacing.xl
        case .settings: return theme.spacing.xl
        }
    }
    
    func contentPadding(_ theme: AppTheme) -> EdgeInsets {
        switch self {
        case .standard: return EdgeInsets(top: theme.spacing.lg, leading: theme.spacing.lg, bottom: theme.spacing.lg, trailing: theme.spacing.lg)
        case .compact: return EdgeInsets(top: theme.spacing.md, leading: theme.spacing.md, bottom: theme.spacing.md, trailing: theme.spacing.md)
        case .modal: return EdgeInsets(top: theme.spacing.xl, leading: theme.spacing.lg, bottom: theme.spacing.xl, trailing: theme.spacing.lg)
        case .settings: return EdgeInsets(top: theme.spacing.lg, leading: 0, bottom: theme.spacing.lg, trailing: 0)
        }
    }
    
    func background(_ theme: AppTheme) -> Color {
        switch self {
        case .standard, .compact: return theme.cardBackground
        case .modal: return theme.background
        case .settings: return theme.background.opacity(0)
        }
    }
    
    func cornerRadius(_ theme: AppTheme) -> CGFloat {
        switch self {
        case .standard, .compact: return AppSettings.Constants.Layout.cornerRadiusMedium
        case .modal, .settings: return 0
        }
    }
}

// MARK: - App Form Section
public struct AppFormSection<Content: View>: View {
    @Environment(\.theme) private var theme
    
    public let title: String?
    public let subtitle: String?
    public let content: Content
    
    public init(
        title: String? = nil,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            if title != nil || subtitle != nil {
                VStack(alignment: .leading, spacing: theme.spacing.xs / 2) {
                    if let title = title {
                        Text(title)
                            .font(theme.fonts.headline)
                            .foregroundColor(theme.text)
                    }
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(theme.fonts.caption)
                            .foregroundColor(theme.textSecondary)
                    }
                }
            }
            
            VStack(spacing: theme.spacing.md) {
                content
            }
        }
    }
}

// MARK: - App Form Field
public struct AppFormField<Content: View>: View {
    @Environment(\.theme) private var theme
    
    public let label: String?
    public let hint: String?
    public let errorMessage: String?
    public let isRequired: Bool
    public let content: Content
    
    public init(
        label: String? = nil,
        hint: String? = nil,
        errorMessage: String? = nil,
        isRequired: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.label = label
        self.hint = hint
        self.errorMessage = errorMessage
        self.isRequired = isRequired
        self.content = content()
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            if let label = label {
                HStack(spacing: theme.spacing.xs / 2) {
                    Text(label)
                        .font(theme.fonts.callout)
                        .foregroundColor(theme.text)
                    
                    if isRequired {
                        Text("*")
                            .font(theme.fonts.callout)
                            .foregroundColor(theme.error)
                    }
                    
                    Spacer()
                }
            }
            
            content
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(theme.fonts.caption)
                    .foregroundColor(theme.error)
            } else if let hint = hint {
                Text(hint)
                    .font(theme.fonts.caption)
                    .foregroundColor(theme.textSecondary)
            }
        }
    }
}

// MARK: - App Text Input
public struct AppTextInput: View {
    @Environment(\.theme) private var theme
    
    @Binding public var text: String
    public let placeholder: String
    public let style: AppTextInputStyle
    public let keyboardType: UIKeyboardType
    public let isSecure: Bool
    public let isDisabled: Bool
    public let maxLength: Int?
    public let validation: ((String) -> String?)?
    
    @State private var isEditing = false
    @State private var errorMessage: String?
    
    public init(
        text: Binding<String>,
        placeholder: String = "",
        style: AppTextInputStyle = .standard,
        keyboardType: UIKeyboardType = .default,
        isSecure: Bool = false,
        isDisabled: Bool = false,
        maxLength: Int? = nil,
        validation: ((String) -> String?)? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.style = style
        self.keyboardType = keyboardType
        self.isSecure = isSecure
        self.isDisabled = isDisabled
        self.maxLength = maxLength
        self.validation = validation
    }
    
    public var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty && !isEditing {
                Text(placeholder)
                    .font(style.textFont(theme))
                    .foregroundColor(theme.textSecondary)
                    .padding(style.contentPadding(theme))
            }
            
            Group {
                if isSecure {
                    SecureField("", text: $text)
                } else {
                    TextField("", text: $text)
                }
            }
            .font(style.textFont(theme))
            .foregroundColor(style.textColor(theme, isDisabled: isDisabled))
            .keyboardType(keyboardType)
            .disabled(isDisabled)
            .padding(style.contentPadding(theme))
            .background(style.background(theme, isDisabled: isDisabled, hasError: errorMessage != nil))
            .cornerRadius(style.cornerRadius(theme))
            .overlay(
                RoundedRectangle(cornerRadius: style.cornerRadius(theme))
                    .stroke(style.borderColor(theme, isEditing: isEditing, hasError: errorMessage != nil), lineWidth: style.borderWidth)
            )
            .onTapGesture {
                isEditing = true
            }
            .onChange(of: text) { _, newValue in
                if let maxLength = maxLength, newValue.count > maxLength {
                    text = String(newValue.prefix(maxLength))
                }
                
                if let validation = validation {
                    errorMessage = validation(text)
                }
            }
        }
    }
}

// MARK: - App Text Input Style
public enum AppTextInputStyle {
    case standard
    case compact
    case rounded
    case minimal
    
    func textFont(_ theme: AppTheme) -> Font {
        switch self {
        case .standard, .rounded: return theme.fonts.body
        case .compact: return theme.fonts.callout
        case .minimal: return theme.fonts.body
        }
    }
    
    func textColor(_ theme: AppTheme, isDisabled: Bool) -> Color {
        isDisabled ? theme.textSecondary : theme.text
    }
    
    func background(_ theme: AppTheme, isDisabled: Bool, hasError: Bool) -> Color {
        if isDisabled {
            return theme.surface.opacity(0.5)
        } else if hasError {
            return theme.error.opacity(0.1)
        } else {
            switch self {
            case .standard, .compact, .rounded: return theme.inputBackground
            case .minimal: return theme.background.opacity(0)
            }
        }
    }
    
    func borderColor(_ theme: AppTheme, isEditing: Bool, hasError: Bool) -> Color {
        if hasError {
            return theme.error
        } else if isEditing {
            return theme.primary
        } else {
            switch self {
            case .standard, .compact, .rounded: return theme.divider
            case .minimal: return theme.divider.opacity(0.5)
            }
        }
    }
    
    var borderWidth: CGFloat {
        switch self {
        case .standard, .compact, .rounded: return 1
        case .minimal: return 1
        }
    }
    
    func cornerRadius(_ theme: AppTheme) -> CGFloat {
        switch self {
        case .standard, .compact: return AppSettings.Constants.Layout.cornerRadiusSmall
        case .rounded: return AppSettings.Constants.Layout.cornerRadiusMedium
        case .minimal: return 0
        }
    }
    
    func contentPadding(_ theme: AppTheme) -> EdgeInsets {
        switch self {
        case .standard: return EdgeInsets(top: theme.spacing.md, leading: theme.spacing.md, bottom: theme.spacing.md, trailing: theme.spacing.md)
        case .compact: return EdgeInsets(top: theme.spacing.sm, leading: theme.spacing.sm, bottom: theme.spacing.sm, trailing: theme.spacing.sm)
        case .rounded: return EdgeInsets(top: theme.spacing.md, leading: theme.spacing.lg, bottom: theme.spacing.md, trailing: theme.spacing.lg)
        case .minimal: return EdgeInsets(top: theme.spacing.sm, leading: 0, bottom: theme.spacing.sm, trailing: 0)
        }
    }
}

// MARK: - Form Validation Helpers
public struct AppFormValidation {
    public static func required(_ message: String = "This field is required") -> (String) -> String? {
        return { text in
            text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? message : nil
        }
    }
    
    public static func email(_ message: String = "Please enter a valid email address") -> (String) -> String? {
        return { text in
            let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
            return emailPredicate.evaluate(with: text) ? nil : message
        }
    }
    
    public static func minLength(_ length: Int, message: String? = nil) -> (String) -> String? {
        return { text in
            text.count >= length ? nil : (message ?? "Must be at least \(length) characters")
        }
    }
    
    public static func maxLength(_ length: Int, message: String? = nil) -> (String) -> String? {
        return { text in
            text.count <= length ? nil : (message ?? "Must be no more than \(length) characters")
        }
    }
}

// MARK: - Convenience Extensions
public extension AppForm {
    static func standard<T: View>(@ViewBuilder content: @escaping () -> T) -> AppForm<T> {
        AppForm<T>(style: .standard, content: content)
    }
    
    static func compact<T: View>(@ViewBuilder content: @escaping () -> T) -> AppForm<T> {
        AppForm<T>(style: .compact, content: content)
    }
    
    static func modal<T: View>(@ViewBuilder content: @escaping () -> T) -> AppForm<T> {
        AppForm<T>(style: .modal, content: content)
    }
    
    static func settings<T: View>(@ViewBuilder content: @escaping () -> T) -> AppForm<T> {
        AppForm<T>(style: .settings, content: content)
    }
}