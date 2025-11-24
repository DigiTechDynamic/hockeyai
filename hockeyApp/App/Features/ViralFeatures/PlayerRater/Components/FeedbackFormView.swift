import SwiftUI

// MARK: - Feedback Form View
/// Collects feedback from users who aren't ready to rate yet
/// This helps improve the app AND protects App Store rating
struct FeedbackFormView: View {
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss

    @State private var feedbackText = ""
    @State private var selectedCategory: FeedbackCategory? = nil
    @State private var isSubmitting = false
    @State private var showThankYou = false

    let onSubmit: (FeedbackSubmission) -> Void

    var body: some View {
        NavigationView {
            ZStack {
                // Main form
                ScrollView {
                    VStack(spacing: theme.spacing.xl) {
                        // Header
                        VStack(spacing: theme.spacing.md) {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .font(.system(size: 44))
                                .foregroundColor(theme.primary)

                            Text("Help Us Improve")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(theme.text)

                            Text("Your feedback is valuable. We read every response and use it to make SnapHockey better.")
                                .font(theme.fonts.caption)
                                .foregroundColor(theme.textSecondary)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.bottom, theme.spacing.md)

                        // Category selection
                        VStack(alignment: .leading, spacing: theme.spacing.sm) {
                            Text("What can we improve?")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(theme.text)

                            VStack(spacing: theme.spacing.sm) {
                                ForEach(FeedbackCategory.allCases, id: \.self) { category in
                                    CategoryButton(
                                        category: category,
                                        isSelected: selectedCategory == category,
                                        onTap: {
                                            HapticManager.shared.playSelection()
                                            selectedCategory = category
                                        }
                                    )
                                }
                            }
                        }

                        // Text area
                        VStack(alignment: .leading, spacing: theme.spacing.sm) {
                            Text("Tell us more (optional)")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(theme.text)

                            ZStack(alignment: .topLeading) {
                                if feedbackText.isEmpty {
                                    Text("What could make STY Hockey better for you?")
                                        .font(.system(size: 15))
                                        .foregroundColor(theme.textSecondary.opacity(0.5))
                                        .padding(.top, 8)
                                        .padding(.leading, 16)
                                }

                                TextEditor(text: $feedbackText)
                                    .frame(height: 120)
                                    .padding(12)
                                    .scrollContentBackground(.hidden)
                                    .background(Color.clear)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.white.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(theme.divider.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }

                        // Submit button
                        Button(action: submitFeedback) {
                            HStack(spacing: 8) {
                                if isSubmitting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                } else {
                                    Image(systemName: "paperplane.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Send Feedback")
                                        .font(.system(size: 17, weight: .bold))
                                }
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(canSubmit ? theme.primary : theme.divider.opacity(0.3))
                            )
                            .shadow(color: canSubmit ? theme.primary.opacity(0.3) : .clear, radius: 8, y: 4)
                        }
                        .disabled(!canSubmit || isSubmitting)
                        .padding(.top, theme.spacing.md)
                        .padding(.bottom, theme.spacing.xl)
                    }
                    .padding(.horizontal, theme.spacing.lg)
                }
                .opacity(showThankYou ? 0 : 1)

                // Thank you overlay
                if showThankYou {
                    ThankYouOverlay()
                }
            }
            .navigationTitle("Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") {
                        HapticManager.shared.playImpact(style: .light)
                        dismiss()
                    }
                    .foregroundColor(theme.textSecondary)
                }
            }
        }
    }

    private var canSubmit: Bool {
        selectedCategory != nil
    }

    private func submitFeedback() {
        guard canSubmit else { return }

        isSubmitting = true
        HapticManager.shared.playNotification(type: .success)

        // Create submission
        let submission = FeedbackSubmission(
            category: selectedCategory!,
            text: feedbackText.isEmpty ? nil : feedbackText,
            timestamp: Date()
        )

        // Save and notify parent
        onSubmit(submission)

        // Show thank you
        withAnimation(.easeOut(duration: 0.3)) {
            showThankYou = true
        }

        // Dismiss after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            dismiss()
        }
    }
}

// MARK: - Category Button
private struct CategoryButton: View {
    @Environment(\.theme) var theme
    let category: FeedbackCategory
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Text(category.emoji)
                    .font(.system(size: 24))

                VStack(alignment: .leading, spacing: 2) {
                    Text(category.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(theme.text)

                    Text(category.subtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(theme.textSecondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(isSelected ? theme.primary : theme.divider)
            }
            .padding(theme.spacing.md)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? theme.primary.opacity(0.1) : Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                isSelected ? theme.primary.opacity(0.5) : theme.divider.opacity(0.2),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Thank You Overlay
private struct ThankYouOverlay: View {
    @Environment(\.theme) var theme
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0

    var body: some View {
        VStack(spacing: theme.spacing.lg) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(theme.primary)

            VStack(spacing: theme.spacing.sm) {
                Text("Thank You!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(theme.text)

                Text("Your feedback helps make STY Hockey better for everyone 🏒")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .padding(theme.spacing.xl)
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
            HapticManager.shared.playNotification(type: .success)
        }
    }
}

// MARK: - Feedback Models
enum FeedbackCategory: String, CaseIterable {
    case aiAccuracy = "ai_accuracy"
    case performance = "performance"
    case features = "features"
    case design = "design"
    case other = "other"

    var title: String {
        switch self {
        case .aiAccuracy: return "AI Analysis"
        case .performance: return "Speed/Performance"
        case .features: return "Missing Features"
        case .design: return "Design/Interface"
        case .other: return "Something Else"
        }
    }

    var subtitle: String {
        switch self {
        case .aiAccuracy: return "Accuracy of ratings or feedback"
        case .performance: return "Loading times or crashes"
        case .features: return "Features you'd like to see"
        case .design: return "How the app looks or works"
        case .other: return "Any other suggestions"
        }
    }

    var emoji: String {
        switch self {
        case .aiAccuracy: return "🤖"
        case .performance: return "⚡"
        case .features: return "✨"
        case .design: return "🎨"
        case .other: return "💭"
        }
    }
}

struct FeedbackSubmission {
    let category: FeedbackCategory
    let text: String?
    let timestamp: Date

    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "category": category.rawValue,
            "timestamp": ISO8601DateFormatter().string(from: timestamp)
        ]
        if let text = text {
            dict["text"] = text
        }
        return dict
    }
}

// MARK: - Preview
struct FeedbackFormView_Previews: PreviewProvider {
    static var previews: some View {
        FeedbackFormView(onSubmit: { submission in
            print("Feedback: \(submission)")
        })
        .preferredColorScheme(.dark)
    }
}
