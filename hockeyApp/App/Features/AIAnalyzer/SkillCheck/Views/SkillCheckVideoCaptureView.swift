import SwiftUI
import AVFoundation

// MARK: - Skill Check Video Capture View
/// Single screen for video capture + context questions
/// Flow: Pick skill (or type custom) → Upload video → Continue
struct SkillCheckVideoCaptureView: View {
    @Environment(\.theme) var theme

    let onVideoCaptured: (URL, SkillCheckContext) -> Void

    @State private var videoURL: URL?
    @State private var videoDuration: Double = 0
    @State private var selectedSkill: String? = nil
    @State private var customRequest: String = ""
    @State private var showCustomField: Bool = false
    @State private var focusArea: String = "" // Optional: what to pay attention to
    @FocusState private var isTextFieldFocused: Bool
    @FocusState private var isFocusFieldFocused: Bool

    // Skill categories
    private let skills = [
        ["Wrist shot", "Slap shot", "Snapshot"],
        ["Skating", "Stickhandling", "Passing"],
        ["Backhand", "Deking", "Defense"],
        ["Goalie", "One-timer", "Faceoffs"]
    ]

    /// The final user request to send to AI (combines skill + optional focus)
    private var userRequest: String {
        var request: String

        if showCustomField && !customRequest.isEmpty {
            request = customRequest
        } else {
            request = selectedSkill ?? ""
        }

        // Append focus area if provided
        if !focusArea.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            request += ". Focus on: \(focusArea)"
        }

        return request
    }

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: theme.spacing.lg) {
                        // AI Feedback Explanation Card
                        aiExplanationCard

                        // Step 1: Skill Selection
                        stepOneSkillSection

                        // Step 2: Video Upload
                        stepTwoVideoSection
                    }
                    .padding(.horizontal, theme.spacing.lg)
                    .padding(.top, theme.spacing.md)
                    .padding(.bottom, 120)
                }
                .onTapGesture {
                    isTextFieldFocused = false
                    isFocusFieldFocused = false
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

    // MARK: - AI Explanation Card
    private var aiExplanationCard: some View {
        HStack(spacing: 14) {
            // AI Icon
            ZStack {
                Circle()
                    .fill(theme.primary.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: "sparkles")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(theme.primary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("AI Skill Analysis")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(theme.text)

                Text("Get personalized feedback on your technique. We'll analyze your form and show you exactly what to improve.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(theme.primary.opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - Step 1: Skill Selection
    private var stepOneSkillSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Step header
            HStack(spacing: 10) {
                stepBadge(number: 1, isComplete: selectedSkill != nil || (showCustomField && !customRequest.isEmpty))

                Text("What skill are you working on?")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(theme.text)
            }

            // Skill chips grid
            VStack(spacing: 10) {
                ForEach(skills, id: \.self) { row in
                    HStack(spacing: 10) {
                        ForEach(row, id: \.self) { skill in
                            skillChip(skill)
                        }
                    }
                }

                // "Something else" chip - opens custom text field
                somethingElseChip
            }

            // Custom text field (only shows when "Something else" is tapped)
            if showCustomField {
                customTextField
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Optional focus area (only shows after skill is selected)
            if selectedSkill != nil && !showCustomField {
                optionalFocusField
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showCustomField)
        .animation(.easeInOut(duration: 0.25), value: selectedSkill)
    }

    // MARK: - Step Badge
    private func stepBadge(number: Int, isComplete: Bool) -> some View {
        ZStack {
            Circle()
                .fill(isComplete ? theme.primary : theme.surface)
                .frame(width: 28, height: 28)

            if isComplete {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(theme.background)
            } else {
                Text("\(number)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(theme.textSecondary)
            }
        }
        .overlay(
            Circle()
                .stroke(isComplete ? theme.primary : theme.textSecondary.opacity(0.3), lineWidth: 2)
        )
    }

    // MARK: - Optional Focus Field
    private var optionalFocusField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Anything specific? (optional)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(theme.textSecondary)

            TextField("", text: $focusArea, prompt: Text("e.g. release speed, accuracy, power...")
                .foregroundColor(theme.textSecondary.opacity(0.5)))
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(theme.text)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isFocusFieldFocused ? theme.primary.opacity(0.5) : theme.textSecondary.opacity(0.2), lineWidth: 1.5)
                        )
                )
                .focused($isFocusFieldFocused)
                .submitLabel(.done)
                .onSubmit {
                    isFocusFieldFocused = false
                }
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") {
                            isFocusFieldFocused = false
                            isTextFieldFocused = false
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(theme.primary)
                    }
                }
        }
        .padding(.top, 4)
    }

    // MARK: - Step 2: Video Section
    private var stepTwoVideoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Step header
            HStack(spacing: 10) {
                stepBadge(number: 2, isComplete: videoURL != nil)

                Text("Add your video")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(theme.text)
            }

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
    }

    // MARK: - Skill Chips (kept for reference)
    private var skillChipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Skill chips grid
            VStack(spacing: 10) {
                ForEach(skills, id: \.self) { row in
                    HStack(spacing: 10) {
                        ForEach(row, id: \.self) { skill in
                            skillChip(skill)
                        }
                    }
                }

                // "Something else" chip - opens custom text field
                somethingElseChip
            }

            // Custom text field (only shows when "Something else" is tapped)
            if showCustomField {
                customTextField
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showCustomField)
    }

    private func skillChip(_ text: String) -> some View {
        let isSelected = selectedSkill == text && !showCustomField

        return Button(action: {
            // Deselect if already selected
            if selectedSkill == text && !showCustomField {
                selectedSkill = nil
            } else {
                selectedSkill = text
                showCustomField = false
                customRequest = ""
            }
            HapticManager.shared.playImpact(style: .light)
        }) {
            Text(text)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? theme.background : theme.text)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? theme.primary : theme.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? theme.primary : theme.textSecondary.opacity(0.2), lineWidth: 1.5)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var somethingElseChip: some View {
        Button(action: {
            withAnimation {
                showCustomField.toggle()
                if showCustomField {
                    selectedSkill = nil
                    // Focus the text field after a brief delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isTextFieldFocused = true
                    }
                } else {
                    customRequest = ""
                    isTextFieldFocused = false
                }
            }
            HapticManager.shared.playImpact(style: .light)
        }) {
            HStack(spacing: 6) {
                Image(systemName: showCustomField ? "xmark" : "plus")
                    .font(.system(size: 12, weight: .bold))
                Text(showCustomField ? "Cancel" : "Something else")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(showCustomField ? theme.text : theme.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(showCustomField ? theme.surface : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        showCustomField ? theme.primary : theme.textSecondary.opacity(0.3),
                        style: StrokeStyle(lineWidth: 1.5, dash: showCustomField ? [] : [6, 4])
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var customTextField: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("", text: $customRequest, prompt: Text("Describe what you want feedback on...")
                .foregroundColor(theme.textSecondary.opacity(0.5)), axis: .vertical)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(theme.text)
                .lineLimit(2...4)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(theme.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(theme.primary, lineWidth: 2)
                        )
                )
                .focused($isTextFieldFocused)
                .submitLabel(.done)
                .onSubmit {
                    isTextFieldFocused = false
                }

            Text("e.g. \"Is my release quick enough?\" or \"How's my edge work?\"")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(theme.textSecondary.opacity(0.7))
                .padding(.horizontal, 4)
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
    /// Button is enabled when: video selected AND (skill chip selected OR custom text entered)
    private var canAnalyze: Bool {
        guard videoURL != nil else { return false }

        if showCustomField {
            return !customRequest.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        } else {
            return selectedSkill != nil
        }
    }

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
            isDisabled: !canAnalyze
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
