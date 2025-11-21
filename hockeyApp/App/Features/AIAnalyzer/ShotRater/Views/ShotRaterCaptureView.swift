import SwiftUI
import AVKit

// MARK: - Shot Rater Capture View
/// Dedicated capture view for Shot Rater that provides:
/// - Example video display with overlay instructions
/// - Media upload functionality (record + upload existing)
/// - Shot-specific recording tips
/// - Professional UI matching the original design
struct ShotRaterCaptureView: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss
    
    // MARK: - Properties
    let shotType: ShotType
    @Binding var capturedVideoURL: URL?
    let onVideoCaptured: (URL) -> Void
    
    // MARK: - State
    @State private var videoURL: URL?
    @State private var showContent = false
    @State private var showInstructions = false
    @State private var showUploadCard = false
    
    init(shotType: ShotType, capturedVideoURL: Binding<URL?>, onVideoCaptured: @escaping (URL) -> Void) {
        self.shotType = shotType
        self._capturedVideoURL = capturedVideoURL
        self.onVideoCaptured = onVideoCaptured
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: theme.spacing.lg) {
                    // Combined demo video with setup instructions
                    combinedDemoSection
                        .padding(.horizontal, theme.spacing.lg)
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
            
            // Bottom action button
            bottomActionButton
        }
        .navigationTitle("Record \(shotType.displayName)")
        .navigationBarTitleDisplayMode(.inline)
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
        .trackScreen("shot_rater_capture")
    }
    
    // MARK: - Combined Demo Section
    private var combinedDemoSection: some View {
        // Example image using AIExampleMediaView with Shoting_Behind_Angle asset
        AIExampleMediaView.image(
            "Shoting_Behind_Angle",
            actionTitle: "Behind Shooter",
            instructions: setupExplanationText
        )
    }

    private var setupExplanationText: String {
        // Standardized description regardless of shot type
        return "Stand 10ft to the side at chest height. Capture full shooting motion including stick, puck, and net in frame."
    }
    
    
    // MARK: - Simplified Video Upload
    private var simplifiedVideoUpload: some View {
        MediaUploadView(
            configuration: MediaUploadView.Configuration(
                title: "Side Angle Recording",
                description: videoURL != nil ? "Video captured successfully" : "Follow the tips below for best results",
                instructions: getInstructionsText(),
                mediaType: .video,
                buttonTitle: "Start Recording",
                showSourceSelector: true,
                showTrimmerImmediately: true,
                preCameraGuideBuilder: { onComplete in
                    AnyView(
                        PhoneSetupTutorialView(flowContext: .shotRater) { _ in
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
            featureType: .shotRater
        ) { url in
            print("✅ Video selected: \(url)")
            videoURL = url
            capturedVideoURL = url
            // Don't auto-navigate - wait for user to click Continue
        }
    }
    
    private func getInstructionsText() -> String {
        // Standardized instructions regardless of shot type
        let tips = [
            "Stand 10ft to the side of shooter",
            "Position camera at chest height",
            "Capture full shooting motion",
            "Show setup to follow-through",
            "Keep stick, puck, and net visible"
        ]
        return tips.map { "• \($0)" }.joined(separator: "\n")
    }
    
    private func formatTrimDuration() -> String {
        let duration = ShotConfigurationFactory.getTrimDuration(for: shotType)
        if duration.min == duration.max {
            return String(format: "%.1f", duration.min)
        } else {
            return "\(String(format: "%.1f", duration.min))-\(String(format: "%.1f", duration.max))"
        }
    }
    
    // MARK: - Bottom Action Button
    private var bottomActionButton: some View {
        AppButton(
            title: "Continue",
            action: {
                if let url = videoURL {
                    print("✅ [ShotRaterCaptureView] Proceeding with video: \(url)")
                    onVideoCaptured(url)
                } else {
                    print("❌ [ShotRaterCaptureView] No video to proceed with")
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


// MARK: - VideoTrimmerConfig
// VideoTrimmerConfig is imported from MediaCaptureKit

// MARK: - Preview
#Preview {
    NavigationView {
        ShotRaterCaptureView(
            shotType: .wristShot,
            capturedVideoURL: .constant(nil)
        ) { url in
            print("Video captured: \(url)")
        }
    }
    .preferredColorScheme(.dark)
}
