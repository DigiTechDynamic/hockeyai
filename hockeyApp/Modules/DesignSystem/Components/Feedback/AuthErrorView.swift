import SwiftUI

public struct AuthErrorView: View {
    let error: AuthError
    let onDismiss: () -> Void
    
    @Environment(\.theme) private var theme
    @State private var isVisible = false
    
    public init(error: AuthError, onDismiss: @escaping () -> Void) {
        self.error = error
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            HStack {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(theme.error)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(error.localizedDescription)
                        .font(theme.fonts.body)
                        .fontWeight(.medium)
                        .foregroundColor(theme.text)
                    
                    if let recoverySuggestion = error.recoverySuggestion {
                        Text(recoverySuggestion)
                            .font(theme.fonts.caption)
                            .foregroundColor(theme.textSecondary)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        isVisible = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onDismiss()
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(theme.textSecondary)
                        .font(.system(size: 18, weight: .medium))
                }
            }
        }
        .padding(theme.spacing.md)
        .background(theme.error.opacity(0.1))
        .cornerRadius(AppSettings.Constants.Layout.cornerRadiusMedium)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.error.opacity(0.3), lineWidth: 1)
        )
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 1 : 0.9)
        .onAppear {
            withAnimation(.spring()) {
                isVisible = true
            }
        }
    }
}

// MARK: - Toast Modifier
public struct AuthErrorToast: ViewModifier {
    @Binding var error: AuthError?
    @Environment(\.theme) private var theme
    
    public func body(content: Content) -> some View {
        ZStack {
            content
            
            VStack {
                if let error = error {
                    AuthErrorView(error: error) {
                        self.error = nil
                    }
                    .padding(.horizontal)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                }
                
                Spacer()
            }
            .animation(theme.animations.medium, value: error)
        }
    }
}

public extension View {
    func authErrorToast(error: Binding<AuthError?>) -> some View {
        modifier(AuthErrorToast(error: error))
    }
}

// MARK: - Preview
struct AuthErrorView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            AuthErrorView(error: .invalidEmail) {}
            AuthErrorView(error: .networkError) {}
            AuthErrorView(error: .emailAlreadyInUse) {}
        }
        .padding()
        .environment(\.theme, BasicTheme())
    }
}