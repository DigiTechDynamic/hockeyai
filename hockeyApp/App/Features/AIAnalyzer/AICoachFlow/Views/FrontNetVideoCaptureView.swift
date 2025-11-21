import SwiftUI

// MARK: - Front Net Video Capture View
struct FrontNetVideoCaptureView: View {
    @ObservedObject var flowState: AIFlowState
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss
    @State private var videoURL: URL?
    @State private var showContent = false
    @State private var showInstructions = false
    @State private var showUploadCard = false
    
    private var selectedShotType: ShotType {
        // Check for pre-selected shot type
        if let preSelected = flowState.getData(for: "selected-shot-type") as? ShotType {
            return preSelected
        }
        
        // Check for user-selected shot type from selection stage
        if let selectedId = flowState.getData(for: "shot-type-selection") as? String {
            switch selectedId {
            case "wrist": return .wristShot
            case "slap": return .slapShot
            case "backhand": return .backhandShot
            case "snapshot": return .snapShot
            default: return .wristShot
            }
        }
        
        return .wristShot
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: theme.spacing.lg) {
                    // Combined demo video with setup instructions
                    combinedDemoSection
                        .padding(.horizontal, theme.spacing.lg)
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
        .trackScreen("ai_coach_front_video")
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
        return "Position 10-15ft behind the shooter, facing toward the net. Capture the shooter's back, their full shooting motion, and the puck trajectory to the net."
    }
    
    // MARK: - Simplified Video Upload
    private var simplifiedVideoUpload: some View {
        MediaUploadView(
            configuration: MediaUploadView.Configuration(
                title: "Behind Shooter",
                description: videoURL != nil ? "Video captured successfully" : "Capture puck release and trajectory",
                instructions: getInstructions().map { "• \($0)" }.joined(separator: "\n"),
                mediaType: .video,
                buttonTitle: "Start Recording",
                showSourceSelector: true,
                showTrimmerImmediately: true,
                preCameraGuideBuilder: { onComplete in
                    AnyView(
                        PhoneSetupTutorialView(flowContext: .aiCoach) { _ in
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
            featureType: .aiCoach
        ) { url in
            print("✅ Front net video selected: \(url)")
            videoURL = url
        }
    }
    
    // MARK: - Bottom Action Button
    private var bottomActionButton: some View {
        AppButton(
            title: "Continue",
            action: {
                if let url = videoURL {
                    print("✅ [FrontNetVideoCaptureView] Proceeding with video: \(url)")
                    var mediaData = MediaStageData()
                    mediaData.videos.append(url)
                    flowState.setData(mediaData, for: "front-net-capture")
                    flowState.proceed()
                } else {
                    print("❌ [FrontNetVideoCaptureView] No video to proceed with")
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
    
    // MARK: - Get Instructions
    private func getInstructions() -> [String] {
        return [
            "Stand 10-15ft behind the shooter",
            "Face camera toward the net",
            "Capture shooter from behind",
            "Show puck trajectory to net",
            "Keep both shooter and net in frame"
        ]
    }
}
