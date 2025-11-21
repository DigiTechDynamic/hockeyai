import SwiftUI

// MARK: - App Alert Configuration
public struct AppAlert {
    public let title: String
    public let message: String?
    public let primaryButton: AppAlertButton
    public let secondaryButton: AppAlertButton?
    public let style: AppAlertStyle
    
    public init(
        title: String,
        message: String? = nil,
        primaryButton: AppAlertButton,
        secondaryButton: AppAlertButton? = nil,
        style: AppAlertStyle = .default
    ) {
        self.title = title
        self.message = message
        self.primaryButton = primaryButton
        self.secondaryButton = secondaryButton
        self.style = style
    }
}

// MARK: - App Alert Button
public struct AppAlertButton {
    public let title: String
    public let style: AppAlertButtonStyle
    public let action: () -> Void
    
    public init(title: String, style: AppAlertButtonStyle = .default, action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.action = action
    }
    
    // Convenience factory methods
    public static func cancel(action: @escaping () -> Void = {}) -> AppAlertButton {
        AppAlertButton(title: "Cancel", style: .cancel, action: action)
    }
    
    public static func delete(action: @escaping () -> Void) -> AppAlertButton {
        AppAlertButton(title: "Delete", style: .destructive, action: action)
    }
    
    public static func confirm(title: String = "OK", action: @escaping () -> Void) -> AppAlertButton {
        AppAlertButton(title: title, style: .default, action: action)
    }
    
    public static func save(action: @escaping () -> Void) -> AppAlertButton {
        AppAlertButton(title: "Save", style: .default, action: action)
    }
}

// MARK: - App Alert Styles
public enum AppAlertStyle {
    case `default`
    case warning
    case error
    case success
}

public enum AppAlertButtonStyle {
    case `default`
    case cancel
    case destructive
}

// MARK: - View Extension for App Alerts
public extension View {
    /// Present a standardized app alert
    func appAlert(
        _ alert: AppAlert,
        isPresented: Binding<Bool>
    ) -> some View {
        self.alert(alert.title, isPresented: isPresented) {
            Button(alert.primaryButton.title, role: alert.primaryButton.style.buttonRole) {
                alert.primaryButton.action()
            }
            
            if let secondaryButton = alert.secondaryButton {
                Button(secondaryButton.title, role: secondaryButton.style.buttonRole) {
                    secondaryButton.action()
                }
            }
        } message: {
            if let message = alert.message {
                Text(message)
            }
        }
    }
    
    /// Present a simple confirmation alert
    func appConfirmAlert(
        title: String,
        message: String,
        confirmTitle: String = "OK",
        isPresented: Binding<Bool>,
        onConfirm: @escaping () -> Void
    ) -> some View {
        self.appAlert(
            AppAlert(
                title: title,
                message: message,
                primaryButton: .confirm(title: confirmTitle, action: onConfirm),
                secondaryButton: .cancel()
            ),
            isPresented: isPresented
        )
    }
    
    /// Present a delete confirmation alert
    func appDeleteAlert(
        title: String = "Delete Item",
        message: String,
        isPresented: Binding<Bool>,
        onDelete: @escaping () -> Void
    ) -> some View {
        self.appAlert(
            AppAlert(
                title: title,
                message: message,
                primaryButton: .delete(action: onDelete),
                secondaryButton: .cancel(),
                style: .error
            ),
            isPresented: isPresented
        )
    }
    
    /// Present a save confirmation alert
    func appSaveAlert(
        title: String = "Save Changes",
        message: String,
        isPresented: Binding<Bool>,
        onSave: @escaping () -> Void,
        onDiscard: @escaping () -> Void = {}
    ) -> some View {
        self.appAlert(
            AppAlert(
                title: title,
                message: message,
                primaryButton: .save(action: onSave),
                secondaryButton: AppAlertButton(title: "Don't Save", style: .destructive, action: onDiscard)
            ),
            isPresented: isPresented
        )
    }
}

// MARK: - Button Role Mapping
private extension AppAlertButtonStyle {
    var buttonRole: ButtonRole? {
        switch self {
        case .default:
            return nil
        case .cancel:
            return .cancel
        case .destructive:
            return .destructive
        }
    }
}