import SwiftUI

struct ErrorView: View {
    @Environment(\.theme) var theme
    let error: Error
    let retry: (() -> Void)?
    
    init(error: Error, retry: (() -> Void)? = nil) {
        self.error = error
        self.retry = retry
    }
    
    var body: some View {
        VStack(spacing: theme.spacing.xl) {
            // Error icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(theme.fonts.display)
                .foregroundColor(theme.error)
            
            // Error title
            Text("Something went wrong")
                .font(theme.fonts.headline)
                .foregroundColor(theme.text)
            
            // Error message
            Text(error.localizedDescription)
                .font(theme.fonts.body)
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, theme.spacing.lg)
            
            // Retry button
            if let retry = retry {
                AppButton(title: "Try Again", action: retry)
                    .buttonStyle(.primary)
                    .padding(.top, theme.spacing.md)
            }
        }
        .padding(theme.spacing.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.background)
    }
}

#if DEBUG
struct ErrorView_Previews: PreviewProvider {
    struct PreviewError: LocalizedError {
        var errorDescription: String? {
            "Unable to connect to the server. Please check your internet connection and try again."
        }
    }
    
    static var previews: some View {
        ErrorView(error: PreviewError()) {
            print("Retry tapped")
        }
    }
}
#endif