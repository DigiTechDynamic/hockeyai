import SwiftUI

// MARK: - Analysis Complete View
struct AnalysisCompleteView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.theme) var theme
    let analysisType: String
    let analysisId: String

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.black
                    .ignoresSafeArea()

                VStack(spacing: 32) {
                    Spacer()

                    // Success Icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [theme.primary, theme.accent],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)

                        Image(systemName: iconForType)
                            .font(.system(size: 50, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .shadow(color: theme.primary.opacity(0.5), radius: 20, x: 0, y: 10)

                    // Title
                    Text(titleForType)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)

                    // Subtitle
                    Text("Your analysis is complete!")
                        .font(.system(size: 18))
                        .foregroundColor(.gray)

                    // Analysis Details Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Analysis Type:")
                                .foregroundColor(.gray)
                            Spacer()
                            Text(analysisType)
                                .foregroundColor(.white)
                                .fontWeight(.medium)
                        }

                        HStack {
                            Text("Analysis ID:")
                                .foregroundColor(.gray)
                            Spacer()
                            Text(analysisId)
                                .foregroundColor(.white)
                                .fontWeight(.medium)
                                .lineLimit(1)
                        }

                        HStack {
                            Text("Status:")
                                .foregroundColor(.gray)
                            Spacer()
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                                Text("Complete")
                                    .foregroundColor(.green)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                    .padding(20)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(16)
                    .padding(.horizontal, 32)

                    // Test Notice
                    VStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.orange)
                        Text("Test Notification")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text("In production, this would show your actual results")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding()

                    Spacer()

                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            dismiss()
                        }) {
                            Text("View Results")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(theme.primary)
                                .cornerRadius(27)
                        }

                        Button(action: {
                            dismiss()
                        }) {
                            Text("Close")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(27)
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarHidden(true)
        }
        // Deep link state now managed by NotificationKit
    }

    private var iconForType: String {
        switch analysisType {
        case "shot-analysis":
            return "scope"
        case "ai-coach":
            return "person.fill.badge.plus"
        case "stick-rating":
            return "star.fill"
        default:
            return "checkmark.circle.fill"
        }
    }

    private var titleForType: String {
        switch analysisType {
        case "shot-analysis":
            return "Shot Analysis Done!"
        case "ai-coach":
            return "Coach Analysis Ready!"
        case "stick-rating":
            return "Stick Rating Complete!"
        default:
            return "Analysis Complete!"
        }
    }
}

#Preview {
    AnalysisCompleteView(
        analysisType: "shot-analysis",
        analysisId: "test-123"
    )
    .preferredColorScheme(.dark)
}
