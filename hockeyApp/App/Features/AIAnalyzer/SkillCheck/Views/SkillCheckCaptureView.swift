import SwiftUI
import AVKit

// MARK: - Skill Check Capture View
/// Simplified capture view for any hockey skill
struct SkillCheckCaptureView: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss

    // MARK: - Properties
    @Binding var capturedVideoURL: URL?
    let onVideoCaptured: (URL) -> Void

    // MARK: - State
    @State private var videoURL: URL?
    @State private var showContent = false
    @State private var showInstructions = false
    @State private var showUploadCard = false
    @State private var activeSheet: ActiveSheet?

    init(capturedVideoURL: Binding<URL?>, onVideoCaptured: @escaping (URL) -> Void) {
        self._capturedVideoURL = capturedVideoURL
        self.onVideoCaptured = onVideoCaptured
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: theme.spacing.lg) {
                    // Combined demo section (image + copy)
                    combinedDemoSection
                        .padding(
                            .horizontal, theme.spacing.lg
                        )
                        .padding(.top, theme.spacing.md)
                        .scaleEffect(showInstructions ? 1 : 0.9)
                        .opacity(showInstructions ? 1 : 0)
                        .offset(y: showInstructions ? 0 : 30)
                        .animation(
                            .spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)
                            .delay(0.1),
                            value: showInstructions
                        )

                    // Simplified video upload
                    simplifiedVideoUpload
                        .padding(.horizontal, theme.spacing.lg)
                        .scaleEffect(showUploadCard ? 1 : 0.9)
                        .opacity(showUploadCard ? 1 : 0)
                        .offset(y: showUploadCard ? 0 : 30)
                        .animation(
                            .spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)
                            .delay(0.25),
                            value: showUploadCard
                        )
                }
                .padding(.bottom, 100)
            }

            // Bottom action button (disabled until video is captured)
            bottomActionButton
        }
        .navigationTitle("Upload Hockey Video")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .sourceSelector:
                MediaPickerSourceSelector(
                    options: .videoOnly,
                    onSelect: { source in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            handleSourceSelection(source)
                        }
                    }
                )
                .presentationDetents([.height(calculateBottomSheetHeight())])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(24)
                .presentationBackgroundInteraction(.enabled(upThrough: .height(calculateBottomSheetHeight())))

            case .camera:
                PermissionAwareMediaPicker.videoCamera { url in
                    if let url = url {
                        videoURL = url
                        capturedVideoURL = url
                    }
                }

            case .photoLibrary:
                PermissionAwareMediaPicker.videoLibrary { url in
                    if let url = url {
                        videoURL = url
                        capturedVideoURL = url
                    }
                }
            }
        }
        .onAppear {
            // Trigger animations in sequence
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                showContent = true
                showInstructions = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showUploadCard = true
            }
        }
        .onDisappear {
            showContent = false
            showInstructions = false
            showUploadCard = false
        }
    }

    // MARK: - Combined Demo Section
    private var combinedDemoSection: some View {
        // Keep the image header and just adjust copy
        AIExampleMediaView.image(
            "Shoting_Behind_Angle",
            actionTitle: "Record Your Skill",
            instructions: setupExplanationText
        )
    }

    private var setupExplanationText: String {
        // Explain clearly what to do under the image
        return "Record a 3–5 second clip of any hockey skill — stickhandling, a trick shot, or a normal shot. Keep your whole body in frame. The app will analyze it."
    }


    // MARK: - Simplified Video Upload
    private var simplifiedVideoUpload: some View {
        MediaUploadView(
            configuration: MediaUploadView.Configuration(
                title: "Upload Your Video",
                description: videoURL != nil ? "Video captured successfully" : "Show us what you've got!",
                instructions: getInstructionsText(),
                mediaType: .video,
                buttonTitle: "Record/Upload Video",
                showSourceSelector: true,
                showTrimmerImmediately: true,
                preCameraGuideBuilder: { onComplete in
                    AnyView(
                        PhoneSetupTutorialView(flowContext: .standalone) { _ in
                            onComplete()
                        }
                    )
                },
                primaryColor: Color.green,
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
            print("✅ Video selected: \(url)")
            videoURL = url
            capturedVideoURL = url
            // Keep flow: primary button + bottom Continue (disabled until captured)
        }
    }

    private func getInstructionsText() -> String {
        // Three concise checklist items (MediaUploadView will render with check icons)
        return [
            "Whole body visible",
            "Phone stable (box, tripod, pucks)",
            "3–5 seconds of clean motion"
        ].joined(separator: "\n")
    }

    // MARK: - Bottom Action Button
    private var bottomActionButton: some View {
        AppButton(
            title: "Continue",
            action: {
                if let url = videoURL {
                    print("✅ [SkillCheckCaptureView] Proceeding with video: \(url)")
                    onVideoCaptured(url)
                } else {
                    // Trigger picker if no video selected
                    activeSheet = .sourceSelector
                }
            },
            style: .primary,
            size: .large,
            icon: "arrow.right",
            isDisabled: videoURL == nil
        )
        .padding()
        .background(
            theme.background
                .opacity(0.95)
                .ignoresSafeArea()
        )
    }
}

// MARK: - Helper Types
private extension SkillCheckCaptureView {
    enum ActiveSheet: Identifiable {
        case sourceSelector
        case camera
        case photoLibrary

        var id: String {
            switch self {
            case .sourceSelector: return "sourceSelector"
            case .camera: return "camera"
            case .photoLibrary: return "photoLibrary"
            }
        }
    }

    func calculateBottomSheetHeight() -> CGFloat {
        var height: CGFloat = 100
        height += 2 * 68
        height += 1
        height += 20
        return height
    }

    func handleSourceSelection(_ source: SelectedSource) {
        switch source {
        case .cameraVideo:
            activeSheet = .camera
        case .libraryVideo:
            activeSheet = .photoLibrary
        default:
            activeSheet = nil
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        SkillCheckCaptureView(
            capturedVideoURL: .constant(nil)
        ) { url in
            print("Video captured: \(url)")
        }
    }
    .preferredColorScheme(.dark)
}
