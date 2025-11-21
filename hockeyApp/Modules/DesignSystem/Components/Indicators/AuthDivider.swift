import SwiftUI

public struct AuthDivider: View {
    let text: String?
    
    @Environment(\.theme) private var theme
    
    public init(text: String? = nil) {
        self.text = text
    }
    
    public var body: some View {
        HStack(spacing: theme.spacing.sm) {
            Rectangle()
                .fill(theme.textSecondary.opacity(0.2))
                .frame(height: 1)
            
            if let text = text {
                Text(text)
                    .font(theme.fonts.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.textSecondary)
                    .padding(.horizontal, theme.spacing.sm)
            }
            
            Rectangle()
                .fill(theme.textSecondary.opacity(0.2))
                .frame(height: 1)
        }
    }
}

// MARK: - Preview
struct AuthDivider_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            AuthDivider()
            AuthDivider(text: "OR")
            AuthDivider(text: "Continue with")
        }
        .padding()
        .environment(\.theme, BasicTheme())
    }
}