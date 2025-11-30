import SwiftUI
import AVFoundation

// MARK: - Skill Check Video Capture View
/// Single screen for video capture + context questions
/// Flow: Upload video → Answer context questions → Continue
struct SkillCheckVideoCaptureView: View {
    @Environment(\.theme) var theme

    let onVideoCaptured: (URL, SkillCheckContext) -> Void

    @State private var videoURL: URL?
    @State private var videoDuration: Double = 0
    @State private var userRequest: String = ""
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: theme.spacing.lg) {
                        // Header
                        challengeHeader

                        // User Request Text Field
                        userRequestField

                        // Media Upload Card
                        MediaUploadView(
                            configuration: MediaUploadView.Configuration(
                                title: videoURL == nil ? "Your Video" : "Video Ready",
                                description: "",
                                instructions: videoURL == nil ? "Record or upload a clip\nAI insights in seconds" : "",
                                mediaType: .video,
                                buttonTitle: "Add Video",
                                showSourceSelector: true,
                                showTrimmerImmediately: false,
                                preCameraGuideBuilder: { onComplete in
                                    AnyView(
                                        PhoneSetupTutorialView(flowContext: .skillCheck) { _ in
                                            onComplete()
                                        }
                                    )
                                },
                                primaryColor: theme.primary,
                                backgroundColor: theme.background,
                                surfaceColor: theme.surface,
                                textColor: theme.text,
                                textSecondaryColor: theme.textSecondary,
                                successColor: theme.success,
                                cornerRadius: theme.cornerRadius
                            ),
                            selectedVideoURL: $videoURL,
                            featureType: .skillCheck
                        ) { url in
                            videoURL = url
                            loadVideoDuration(from: url)
                        }

                        // Video duration info (only show when video is selected)
                        if videoURL != nil && videoDuration > 0 {
                            videoDurationCard
                        }
                    }
                    .padding(.horizontal, theme.spacing.lg)
                    .padding(.top, theme.spacing.md)
                    .padding(.bottom, 120)
                }
                .onTapGesture {
                    isTextFieldFocused = false
                }

                // Bottom Continue button
                bottomButton
            }
        }
        .onAppear {
            // Track flow started (new step 1)
            SkillCheckAnalytics.trackStarted(source: "skill_check_capture")
        }
    }

    // MARK: - Challenge Header
    private var challengeHeader: some View {
        VStack(spacing: 4) {
            Text("What do you want feedback on?")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(theme.text)
                .multilineTextAlignment(.center)

            Text("Any skill, any level - we'll analyze it")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - User Request Field
    private var userRequestField: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Text field with placeholder
            TextField("", text: $userRequest, prompt: Text("Describe what you want feedback on...\n\ne.g. \"Is my wrist shot release quick enough?\" or \"How's my skating form?\"")
                .foregroundColor(theme.textSecondary.opacity(0.5)), axis: .vertical)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(theme.text)
                .lineLimit(3...5)
                .padding(16)
                .frame(minHeight: 100)
                .background(
                    RoundedRectangle(cornerRadius: theme.cornerRadius)
                        .fill(theme.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: theme.cornerRadius)
                                .stroke(isTextFieldFocused ? theme.primary : theme.textSecondary.opacity(0.3), lineWidth: isTextFieldFocused ? 2 : 1)
                        )
                )
                .focused($isTextFieldFocused)
                .submitLabel(.done)
                .onSubmit {
                    isTextFieldFocused = false
                }
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") {
                            isTextFieldFocused = false
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(theme.primary)
                    }
                }

            // Quick suggestions header + chips
            VStack(alignment: .leading, spacing: 8) {
                Text("Or pick a skill:")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(theme.textSecondary)

                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        suggestionChip("Wrist shot")
                        suggestionChip("Slap shot")
                        suggestionChip("Snapshot")
                    }
                    HStack(spacing: 8) {
                        suggestionChip("Skating")
                        suggestionChip("Stickhandling")
                        suggestionChip("Passing")
                    }
                    HStack(spacing: 8) {
                        suggestionChip("Backhand")
                        suggestionChip("Deking")
                        suggestionChip("Defense")
                    }
                    HStack(spacing: 8) {
                        suggestionChip("Goalie")
                        suggestionChip("One-timer")
                        suggestionChip("Faceoffs")
                    }
                }
            }
        }
    }

    private func suggestionChip(_ text: String) -> some View {
        Button(action: {
            userRequest = text
            HapticManager.shared.playImpact(style: .light)
        }) {
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(userRequest == text ? theme.background : theme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(userRequest == text ? theme.primary : theme.surface)
                )
                .overlay(
                    Capsule()
                        .stroke(userRequest == text ? theme.primary : theme.textSecondary.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }


    // MARK: - Video Duration Card
    private var videoDurationCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(videoDuration > 10 ? .orange : theme.primary)

            VStack(alignment: .leading, spacing: 2) {
                Text("Video Length: \(formattedDuration)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                if videoDuration > 10 {
                    Text("Trim to under 10 seconds for best results")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.orange)
                } else {
                    Text("Perfect length for analysis")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(theme.primary)
                }
            }

            Spacer()

            Image(systemName: videoDuration > 10 ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(videoDuration > 10 ? .orange : theme.primary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .fill(theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: theme.cornerRadius)
                        .stroke(videoDuration > 10 ? Color.orange.opacity(0.3) : theme.primary.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private var formattedDuration: String {
        let minutes = Int(videoDuration) / 60
        let seconds = Int(videoDuration) % 60
        if minutes > 0 {
            return "\(minutes):\(String(format: "%02d", seconds))"
        } else {
            return "\(seconds) sec"
        }
    }

    // MARK: - Bottom Button
    private var bottomButton: some View {
        AppButton(
            title: "Analyze My Skill",
            action: {
                if let url = videoURL {
                    isTextFieldFocused = false
                    HapticManager.shared.playImpact(style: .medium)
                    let context = SkillCheckContext(userRequest: userRequest)
                    onVideoCaptured(url, context)
                }
            },
            style: .primary,
            size: .large,
            icon: "sparkles",
            isDisabled: videoURL == nil
        )
        .padding(.horizontal, theme.spacing.lg)
        .padding(.bottom, theme.spacing.lg)
        .background(
            theme.background
                .opacity(0.95)
                .ignoresSafeArea()
        )
    }

    // MARK: - Helper Methods
    private func loadVideoDuration(from url: URL) {
        Task {
            let asset = AVURLAsset(url: url)
            do {
                let duration = try await asset.load(.duration)
                await MainActor.run {
                    videoDuration = duration.seconds
                }
            } catch {
                print("Failed to load video duration: \(error)")
            }
        }
    }
}

// MARK: - Preview
#Preview {
    SkillCheckVideoCaptureView { url, context in
        print("Video captured: \(url)")
        print("Context: \(context.userRequest)")
    }
    .preferredColorScheme(.dark)
}
