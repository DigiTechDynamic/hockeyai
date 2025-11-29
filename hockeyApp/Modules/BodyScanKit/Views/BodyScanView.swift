import SwiftUI
import AVFoundation
import Vision
import AVFAudio
import AudioToolbox

// MARK: - Body Scan View (Main Entry Point)
struct BodyScanView: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss

    let onComplete: (BodyScanResult) -> Void
    let onCancel: () -> Void

    @StateObject private var viewModel = BodyScanViewModel()
    @StateObject private var audioGuide = BodyScanAudioGuide()

    // Onboarding state
    @State private var showOnboarding = true
    @State private var onboardingPage = 0
    @State private var isAudioEnabled = true
    @State private var isPlayingTest = false
    private let totalOnboardingPages = 4

    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()

            if showOnboarding {
                // Onboarding Flow
                onboardingFlow
            } else {
                // Camera Layer
                BodyScanCameraPreview(viewModel: viewModel)
                    .ignoresSafeArea()
                    .opacity(viewModel.scanState == .analyzing ? 0.3 : 1.0)

                // Overlay based on state
                switch viewModel.scanState {
                case .intro:
                    // Skip intro, go straight to scanning after onboarding
                    Color.clear.onAppear {
                        viewModel.startScanning()
                    }
                case .scanning:
                    scanningOverlay
                case .success:
                    successOverlay
                case .analyzing:
                    analyzingOverlay
                case .complete:
                    resultsOverlay
                }

                // Top controls during scanning
                if viewModel.scanState == .scanning {
                    VStack {
                        scanningTopBar
                        Spacer()
                    }
                }
            }
        }
        .onAppear {
            viewModel.checkPermissions()
        }
        .onDisappear {
            viewModel.stopSession()
            audioGuide.stop()
        }
        .alert("Camera Access Required", isPresented: $viewModel.showAlert) {
            Button("Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { onCancel() }
        } message: {
            Text(viewModel.alertMessage)
        }
    }

    // MARK: - Onboarding Flow
    private var onboardingFlow: some View {
        ZStack {
            if onboardingPage == 0 {
                // Hero/Intro Screen
                heroScreen
            } else {
                // Tutorial Pages
                tutorialFlow
            }
        }
    }

    // MARK: - Hero Screen (Page 0)
    private var heroScreen: some View {
        VStack(spacing: 0) {
            // Close button
            HStack {
                Spacer()
                Button(action: { onCancel() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.9))
                        .clipShape(Circle())
                }
                .padding(.trailing, 20)
                .padding(.top, 16)
            }

            Spacer()

            // Title
            VStack(spacing: 16) {
                Text("Deep Dive Into\nYour Body")
                    .font(.system(size: 36, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.black)

                Text("Get accurate measurements for the\nperfect stick recommendation.")
                    .font(.system(size: 17))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 24)

            Spacer()

            // 3D Body Placeholder
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 400)

                // Body silhouette placeholder
                VStack(spacing: 0) {
                    Image(systemName: "figure.stand")
                        .font(.system(size: 180, weight: .ultraLight))
                        .foregroundColor(.black.opacity(0.7))

                    // Scanning rings effect
                    ForEach(0..<3, id: \.self) { index in
                        Ellipse()
                            .stroke(theme.primary.opacity(0.6 - Double(index) * 0.2), lineWidth: 2)
                            .frame(width: 120 + CGFloat(index * 40), height: 30 + CGFloat(index * 10))
                            .offset(y: -80 - CGFloat(index * 40))
                    }
                }
            }

            Spacer()

            // CTA Button
            Button(action: {
                withAnimation { onboardingPage = 1 }
            }) {
                Text("Scan Your Body")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.white)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(
            LinearGradient(
                colors: [Color(white: 0.95), Color(white: 0.9)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }

    // MARK: - Tutorial Flow (Pages 1-4)
    private var tutorialFlow: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("How It Works")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                Button(action: { onCancel() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 24)

            // Page Content
            TabView(selection: $onboardingPage) {
                howToStandPage.tag(1)
                phoneSetupPage.tag(2)
                tipsPage.tag(3)
                volumePage.tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Page Indicators
            HStack(spacing: 8) {
                ForEach(1...totalOnboardingPages, id: \.self) { page in
                    Capsule()
                        .fill(page == onboardingPage ? Color.white : Color.white.opacity(0.3))
                        .frame(width: page == onboardingPage ? 24 : 8, height: 8)
                        .animation(.easeInOut(duration: 0.2), value: onboardingPage)
                }
            }
            .padding(.vertical, 20)

            // Next Button
            Button(action: {
                if onboardingPage < totalOnboardingPages {
                    withAnimation { onboardingPage += 1 }
                } else {
                    withAnimation { showOnboarding = false }
                }
            }) {
                Text(onboardingPage == totalOnboardingPages ? "Start Scan" : "Next")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.white)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color.black.ignoresSafeArea())
    }

    // MARK: - Tutorial Page 1: How to Stand
    private var howToStandPage: some View {
        VStack(spacing: 24) {
            // Image placeholder with annotations
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 380)

                // Body pose placeholder with annotations
                ZStack {
                    // Person silhouette
                    Image(systemName: "figure.arms.open")
                        .font(.system(size: 160, weight: .thin))
                        .foregroundColor(.white.opacity(0.8))

                    // Annotation: Look straight ahead
                    annotationBubble(
                        text: "Look straight\nahead",
                        alignment: .leading
                    )
                    .offset(x: -80, y: -120)

                    // Annotation: Spread arms
                    annotationBubble(
                        text: "Spread your\narms in A pose",
                        alignment: .trailing
                    )
                    .offset(x: 90, y: -20)

                    // Annotation: Feet distance
                    annotationBubble(
                        text: "Keep a distance\nwith your feet",
                        alignment: .leading
                    )
                    .offset(x: -80, y: 100)
                }
            }
            .padding(.horizontal, 20)

            // Title and description
            VStack(spacing: 12) {
                Text("How to Stand")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)

                Text("Keep hands and feet within the frame")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()
        }
    }

    // MARK: - Tutorial Page 2: Phone Setup
    private var phoneSetupPage: some View {
        VStack(spacing: 24) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 380)

                VStack(spacing: 20) {
                    // Phone on surface icon
                    Image(systemName: "iphone.gen3.radiowaves.left.and.right")
                        .font(.system(size: 80))
                        .foregroundColor(theme.primary)

                    // Distance indicator
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.left.and.right")
                            .font(.system(size: 24))
                        Text("6-8 feet")
                            .font(.system(size: 20, weight: .semibold))
                    }
                    .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(.horizontal, 20)

            VStack(spacing: 12) {
                Text("Set Up Your Phone")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)

                Text("Place your phone on a stable surface,\n6-8 feet away at chest height")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
    }

    // MARK: - Tutorial Page 3: Tips
    private var tipsPage: some View {
        VStack(spacing: 24) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 380)

                VStack(spacing: 30) {
                    tipRow(icon: "lightbulb.fill", text: "Good lighting helps accuracy")
                    tipRow(icon: "tshirt.fill", text: "Fitted clothing works best")
                    tipRow(icon: "figure.stand", text: "Stand on a flat surface")
                    tipRow(icon: "clock.fill", text: "Hold still for 4 seconds")
                }
                .padding(.horizontal, 30)
            }
            .padding(.horizontal, 20)

            VStack(spacing: 12) {
                Text("Tips for Best Results")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)

                Text("Follow these tips for accurate measurements")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()
        }
    }

    // MARK: - Tutorial Page 4: Volume
    private var volumePage: some View {
        VStack(spacing: 24) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 380)

                VStack(spacing: 32) {
                    // Animated speaker icon
                    ZStack {
                        // Glow effect when playing
                        if isPlayingTest {
                            Circle()
                                .fill(theme.primary.opacity(0.3))
                                .frame(width: 140, height: 140)
                                .blur(radius: 20)
                        }

                        Image(systemName: isAudioEnabled ? "speaker.wave.3.fill" : "speaker.slash.fill")
                            .font(.system(size: 70))
                            .foregroundColor(isAudioEnabled ? theme.primary : .gray)
                            .symbolEffect(.variableColor.iterative, isActive: isPlayingTest)
                    }
                    .frame(height: 100)

                    // Test Sound Button
                    Button(action: {
                        playTestSound()
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: isPlayingTest ? "speaker.wave.2.fill" : "play.fill")
                                .font(.system(size: 16, weight: .semibold))

                            Text(isPlayingTest ? "Playing..." : "Test Sound")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(isAudioEnabled ? .black : .gray)
                        .frame(width: 160, height: 50)
                        .background(isAudioEnabled ? theme.primary : Color.white.opacity(0.2))
                        .cornerRadius(25)
                    }
                    .disabled(!isAudioEnabled || isPlayingTest)

                    // Audio Toggle
                    Button(action: {
                        isAudioEnabled.toggle()
                        if !isAudioEnabled {
                            audioGuide.stop()
                            isPlayingTest = false
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: isAudioEnabled ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 22))
                                .foregroundColor(isAudioEnabled ? theme.primary : .white.opacity(0.5))

                            Text("Audio Guidance")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)

                            Spacer()

                            Text(isAudioEnabled ? "On" : "Off")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(isAudioEnabled ? theme.primary : .white.opacity(0.5))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.horizontal, 20)

            VStack(spacing: 12) {
                Text("Audio Settings")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)

                Text(isAudioEnabled
                     ? "Tap 'Test Sound' to check your volume.\nYou'll hear voice guidance during the scan."
                     : "Audio guidance is disabled.\nYou can still complete the scan visually.")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
    }

    private func playTestSound() {
        guard isAudioEnabled else { return }
        isPlayingTest = true
        audioGuide.speak("Volume check. Can you hear me? If so, you're all set!", force: true)

        // Reset after speech completes (approximate duration)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            isPlayingTest = false
        }
    }

    // MARK: - Helper Views
    private func annotationBubble(text: String, alignment: HorizontalAlignment) -> some View {
        HStack(spacing: 6) {
            if alignment == .trailing {
                Spacer(minLength: 0)
            }

            Circle()
                .fill(theme.primary)
                .frame(width: 8, height: 8)

            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(alignment == .leading ? .leading : .trailing)

            if alignment == .leading {
                Spacer(minLength: 0)
            }
        }
        .frame(width: 120)
    }

    private func tipRow(icon: String, text: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(theme.primary)
                .frame(width: 32)

            Text(text)
                .font(.system(size: 16))
                .foregroundColor(.white)

            Spacer()
        }
    }

    // MARK: - Scanning Top Bar
    private var scanningTopBar: some View {
        HStack {
            Button(action: {
                viewModel.stopSession()
                onCancel()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }

            Spacer()

            // Pose detection status
            Text(viewModel.isPoseValid ? (viewModel.isStable ? "Hold still" : "Stop moving") : "Looking for body...")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(viewModel.isPoseValid ? (viewModel.isStable ? theme.primary : .orange) : .white.opacity(0.7))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .cornerRadius(20)

            Spacer()

            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            Button(action: {
                viewModel.stopSession()
                onCancel()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }

            Spacer()

            if viewModel.scanState == .scanning {
                // Pose detection status
                Text(viewModel.isPoseValid ? "Body detected" : "Looking for body...")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(viewModel.isPoseValid ? theme.primary : .white.opacity(0.7))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
            }

            Spacer()

            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Intro Overlay
    private var introOverlay: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(theme.primary.opacity(0.15))
                    .frame(width: 120, height: 120)

                Image(systemName: "figure.arms.open")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundColor(theme.primary)
            }

            VStack(spacing: 12) {
                Text("Body Scan")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                Text("Stand back so your full body is visible.\nWe'll capture front and side poses.")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            Button(action: {
                withAnimation { viewModel.startScanning() }
            }) {
                HStack {
                    Image(systemName: "camera.fill")
                    Text("Start Scan")
                }
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(theme.primary)
                .cornerRadius(16)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Color.black.opacity(0.6))
    }

    // MARK: - Scanning Overlay
    private var scanningOverlay: some View {
        GeometryReader { geo in
            ZStack {
                // Body outline guide (faint when skeleton detected)
                BodyOutlineShape(isSide: false)
                    .stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [12, 8]))
                    .foregroundColor(viewModel.detectedPoints.isEmpty ? .white.opacity(0.4) : .white.opacity(0.15))
                    .frame(width: geo.size.width * 0.65, height: geo.size.height * 0.7)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)

                // Skeleton overlay - shows detected body points
                SkeletonOverlayView(
                    points: viewModel.detectedPoints,
                    size: geo.size,
                    isStable: viewModel.isStable,
                    primaryColor: theme.primary
                )

                // Instructions at bottom
                VStack {
                    Spacer()

                    VStack(spacing: 8) {
                        Text(instructionText)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)

                        Text(statusText)
                            .font(.system(size: 15))
                            .foregroundColor(statusColor)

                        // Progress bar when holding
                        if viewModel.isPoseValid && viewModel.isStable && viewModel.holdProgress > 0 {
                            ProgressView(value: viewModel.holdProgress)
                                .progressViewStyle(LinearProgressViewStyle(tint: theme.primary))
                                .frame(width: 200)
                                .padding(.top, 8)
                        }
                    }
                    .padding(.vertical, 20)
                    .padding(.horizontal, 32)
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            if isAudioEnabled {
                audioGuide.speak("Stand back so your full body is visible")
            }
        }
        .onChange(of: viewModel.isPoseValid) { _, isValid in
            if isAudioEnabled && isValid && !viewModel.isStable {
                audioGuide.speak("Body detected. Hold still")
            }
        }
        .onChange(of: viewModel.isStable) { _, isStable in
            if isAudioEnabled && isStable && viewModel.isPoseValid {
                audioGuide.playSound(.beepValid)
            }
        }
    }

    private var instructionText: String {
        if !viewModel.isPoseValid {
            return "Stand with arms relaxed"
        } else if !viewModel.isStable {
            return "Hold still..."
        } else {
            return "Perfect! Keep holding..."
        }
    }

    private var statusText: String {
        if !viewModel.isPoseValid {
            return "Step back so your full body is visible"
        } else if !viewModel.isStable {
            return "Stop moving to capture"
        } else {
            return "Capturing... \(Int(viewModel.holdProgress * 100))%"
        }
    }

    private var statusColor: Color {
        if viewModel.isPoseValid && viewModel.isStable {
            return theme.primary
        } else if viewModel.isPoseValid {
            return .orange
        } else {
            return .white.opacity(0.7)
        }
    }

    // MARK: - Success Overlay
    private var successOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(theme.primary)

            Text("Captured!")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
        }
        .transition(.scale.combined(with: .opacity))
        .onAppear {
            if isAudioEnabled {
                audioGuide.playSound(.beepCapture)
                audioGuide.speak("Great! Analyzing your measurements")
            }
        }
    }

    // MARK: - Analyzing Overlay
    private var analyzingOverlay: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(theme.primary)

            Text("Analyzing measurements...")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)

            Text("Calculating body proportions")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(32)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }

    // MARK: - Results Overlay
    private var resultsOverlay: some View {
        VStack(spacing: 24) {
            Spacer()

            // Success checkmark
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(theme.primary)

            Text("Photo Captured!")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            Text("Your full body photo has been saved\nfor AI analysis.")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)

            // Show captured image
            if let capturedImage = viewModel.frontImage {
                Image(uiImage: capturedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 200, height: 300)
                    .cornerRadius(16)
                    .clipped()
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(theme.primary.opacity(0.5), lineWidth: 2)
                    )
            }

            Spacer()

            VStack(spacing: 12) {
                Button(action: {
                    if let result = viewModel.result {
                        BodyScanStorage.shared.save(result)
                        onComplete(result)
                    }
                }) {
                    Text("Use This Photo")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(theme.primary)
                        .cornerRadius(16)
                }

                Button(action: {
                    viewModel.restart()
                }) {
                    Text("Retake Photo")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Color.black.opacity(0.7))
    }
}

// MARK: - Detected Body Point
struct DetectedBodyPoint: Identifiable {
    let id: String
    let position: CGPoint // Normalized 0-1
    let confidence: Float
}

// MARK: - View Model
@MainActor
class BodyScanViewModel: NSObject, ObservableObject {
    // MARK: - Published State
    @Published var scanState: ScanState = .intro
    @Published var isPoseValid = false
    @Published var isStable = false
    @Published var holdProgress: Double = 0
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var frontImage: UIImage?
    @Published var result: BodyScanResult?
    @Published var detectedPoints: [DetectedBodyPoint] = []

    // MARK: - Scan State
    enum ScanState: Int {
        case intro = 0
        case scanning = 1
        case success = 2
        case analyzing = 3
        case complete = 4
    }

    // MARK: - Camera Management
    private let cameraManager = CameraSessionManager()

    /// Expose session for preview layer
    var cameraSession: AVCaptureSession { cameraManager.session }

    // MARK: - Pose Detection
    private var validPoseDuration: TimeInterval = 0
    private var stablePoseDuration: TimeInterval = 0
    private var lastFrameTime = Date()
    private let requiredHoldDuration: TimeInterval = 4.0 // Hold still for 4 seconds
    private let requiredStableDuration: TimeInterval = 0.8 // Must be stable for 0.8s before counting
    private var isCapturing = false

    // MARK: - Stability Tracking
    private var previousPoints: [String: CGPoint] = [:]
    private let stabilityThreshold: CGFloat = 0.015 // Max movement allowed (normalized)

    // MARK: - Setup
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.setupCamera()
                    } else {
                        self?.alertMessage = "Camera access is required for body scan."
                        self?.showAlert = true
                    }
                }
            }
        default:
            alertMessage = "Please enable camera access in Settings."
            showAlert = true
        }
    }

    private func setupCamera() {
        cameraManager.configure(videoDelegate: self) {
            print("[BodyScan] Camera session started")
        }
    }

    func stopSession() {
        cameraManager.stop()
    }

    func startScanning() {
        scanState = .scanning
        validPoseDuration = 0
        holdProgress = 0
    }

    func restart() {
        frontImage = nil
        result = nil
        validPoseDuration = 0
        stablePoseDuration = 0
        holdProgress = 0
        isPoseValid = false
        isStable = false
        isCapturing = false
        detectedPoints = []
        previousPoints = [:]
        scanState = .intro
    }
}

// MARK: - Video Delegate (Pose Detection)
extension BodyScanViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNDetectHumanBodyPoseRequest { [weak self] request, error in
            Task { @MainActor in
                self?.handlePoseDetection(request: request, error: error)
            }
        }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .leftMirrored, options: [:])
        try? handler.perform([request])
    }

    @MainActor
    private func handlePoseDetection(request: VNRequest, error: Error?) {
        // Only process during scanning state
        guard scanState == .scanning else { return }

        guard let observations = request.results as? [VNHumanBodyPoseObservation],
              let body = observations.first else {
            // No body detected
            isPoseValid = false
            isStable = false
            detectedPoints = []
            validPoseDuration = max(0, validPoseDuration - 0.1)
            stablePoseDuration = 0
            holdProgress = 0
            return
        }

        // Extract all detected points for visualization
        var newPoints: [DetectedBodyPoint] = []
        var currentPointPositions: [String: CGPoint] = [:]

        // Key joints to detect and display
        let jointNames: [(VNHumanBodyPoseObservation.JointName, String)] = [
            (.nose, "nose"),
            (.neck, "neck"),
            (.leftShoulder, "leftShoulder"),
            (.rightShoulder, "rightShoulder"),
            (.leftElbow, "leftElbow"),
            (.rightElbow, "rightElbow"),
            (.leftWrist, "leftWrist"),
            (.rightWrist, "rightWrist"),
            (.leftHip, "leftHip"),
            (.rightHip, "rightHip"),
            (.leftKnee, "leftKnee"),
            (.rightKnee, "rightKnee"),
            (.leftAnkle, "leftAnkle"),
            (.rightAnkle, "rightAnkle")
        ]

        var keyPointsConfidence: [Float] = []

        for (joint, name) in jointNames {
            if let point = try? body.recognizedPoint(joint), point.confidence > 0.2 {
                // Vision coordinates: origin at bottom-left, y increases upward
                // Convert to screen coordinates: origin at top-left, y increases downward
                let screenPoint = CGPoint(x: point.location.x, y: 1 - point.location.y)
                newPoints.append(DetectedBodyPoint(id: name, position: screenPoint, confidence: point.confidence))
                currentPointPositions[name] = screenPoint

                // Track confidence for key points
                if ["nose", "leftShoulder", "rightShoulder", "leftHip", "rightHip", "leftAnkle", "rightAnkle"].contains(name) {
                    keyPointsConfidence.append(point.confidence)
                }
            }
        }

        detectedPoints = newPoints

        // Check if we have all required key points
        let requiredPoints = ["nose", "leftShoulder", "rightShoulder", "leftHip", "rightHip", "leftAnkle", "rightAnkle"]
        let hasAllKeyPoints = requiredPoints.allSatisfy { name in
            currentPointPositions[name] != nil
        }

        let minConfidence = keyPointsConfidence.min() ?? 0
        let avgConfidence = keyPointsConfidence.isEmpty ? 0 : keyPointsConfidence.reduce(0, +) / Float(keyPointsConfidence.count)

        // Pose is valid if we see all key points with good confidence
        let poseValid = hasAllKeyPoints && minConfidence > 0.3 && avgConfidence > 0.5
        isPoseValid = poseValid

        // Check stability - compare current points to previous frame
        var totalMovement: CGFloat = 0
        var comparedPoints = 0

        for (name, currentPos) in currentPointPositions {
            if let previousPos = previousPoints[name] {
                let dx = currentPos.x - previousPos.x
                let dy = currentPos.y - previousPos.y
                let movement = sqrt(dx * dx + dy * dy)
                totalMovement += movement
                comparedPoints += 1
            }
        }

        let avgMovement = comparedPoints > 0 ? totalMovement / CGFloat(comparedPoints) : 1.0
        let currentlyStable = avgMovement < stabilityThreshold && poseValid

        // Store current points for next frame comparison
        previousPoints = currentPointPositions

        // Update stability duration
        if currentlyStable {
            stablePoseDuration += 0.033 // ~30fps
            if stablePoseDuration >= requiredStableDuration {
                isStable = true
            }
        } else {
            stablePoseDuration = max(0, stablePoseDuration - 0.066) // Decay faster
            if stablePoseDuration < requiredStableDuration * 0.5 {
                isStable = false
            }
        }

        // Only count hold progress when STABLE
        if poseValid && isStable {
            validPoseDuration += 0.033
            holdProgress = min(1.0, validPoseDuration / requiredHoldDuration)

            if validPoseDuration >= requiredHoldDuration && !isCapturing {
                captureAndAdvance(confidence: Double(avgConfidence))
            }
        } else {
            validPoseDuration = max(0, validPoseDuration - 0.066)
            holdProgress = max(0, validPoseDuration / requiredHoldDuration)
        }

        // Debug logging (less frequent)
        if Int.random(in: 0..<15) == 0 {
            print("[BodyScan] Points: \(newPoints.count), Valid: \(poseValid), Stable: \(isStable), Movement: \(String(format: "%.4f", avgMovement)), Hold: \(String(format: "%.1f", holdProgress * 100))%")
        }
    }

    @MainActor
    private func captureAndAdvance(confidence: Double) {
        isCapturing = true

        // Capture photo via camera manager
        cameraManager.capturePhoto(delegate: self)

        // Show success then analyze
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }
            withAnimation { self.scanState = .success }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation { self.scanState = .analyzing }
                self.generateResults(confidence: confidence)
            }
        }
    }

    @MainActor
    private func generateResults(confidence: Double) {
        // Brief delay for UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }

            // Save image to disk
            var imagePath: String?
            if let image = self.frontImage {
                imagePath = BodyScanStorage.shared.saveImage(image)
                print("[BodyScan] Image saved to: \(imagePath ?? "failed")")
            }

            // Create result with just the image (no measurements - those were fake)
            let result = BodyScanResult(
                imagePath: imagePath,
                poseConfidence: confidence,
                detectedPose: .relaxedStand,
                referenceMethod: .userProvidedHeight
            )

            self.result = result
            withAnimation { self.scanState = .complete }
        }
    }

}

// MARK: - Photo Capture Delegate
extension BodyScanViewModel: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            print("[BodyScan] Failed to capture photo")
            return
        }

        // Mirror image for front camera
        let mirrored = UIImage(cgImage: image.cgImage!, scale: image.scale, orientation: .leftMirrored)

        Task { @MainActor in
            self.frontImage = mirrored
            print("[BodyScan] Image captured: \(mirrored.size)")
        }
    }
}

// MARK: - Camera Preview
struct BodyScanCameraPreview: UIViewRepresentable {
    @ObservedObject var viewModel: BodyScanViewModel

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = viewModel.cameraSession
        view.previewLayer.videoGravity = .resizeAspectFill
        view.backgroundColor = .black
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        // Frame updates automatically via layoutSubviews
    }

    class PreviewView: UIView {
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }

        var previewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            previewLayer.frame = bounds
        }
    }
}

// MARK: - Body Outline Shape
struct BodyOutlineShape: Shape {
    var isSide: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        if !isSide {
            // Front silhouette (T-pose)
            // Head
            path.addEllipse(in: CGRect(x: w * 0.38, y: h * 0.02, width: w * 0.24, height: h * 0.1))

            // Body outline
            path.move(to: CGPoint(x: w * 0.38, y: h * 0.11))
            path.addQuadCurve(to: CGPoint(x: w * 0.08, y: h * 0.18), control: CGPoint(x: w * 0.2, y: h * 0.14))
            path.addLine(to: CGPoint(x: w * 0.05, y: h * 0.22)) // Left hand
            path.addLine(to: CGPoint(x: w * 0.08, y: h * 0.26))
            path.addQuadCurve(to: CGPoint(x: w * 0.30, y: h * 0.28), control: CGPoint(x: w * 0.18, y: h * 0.26))
            path.addLine(to: CGPoint(x: w * 0.28, y: h * 0.55)) // Left waist
            path.addLine(to: CGPoint(x: w * 0.25, y: h * 0.95)) // Left leg
            path.addLine(to: CGPoint(x: w * 0.42, y: h * 0.95))
            path.addLine(to: CGPoint(x: w * 0.50, y: h * 0.58)) // Crotch
            path.addLine(to: CGPoint(x: w * 0.58, y: h * 0.95))
            path.addLine(to: CGPoint(x: w * 0.75, y: h * 0.95)) // Right leg
            path.addLine(to: CGPoint(x: w * 0.72, y: h * 0.55)) // Right waist
            path.addLine(to: CGPoint(x: w * 0.70, y: h * 0.28))
            path.addQuadCurve(to: CGPoint(x: w * 0.92, y: h * 0.26), control: CGPoint(x: w * 0.82, y: h * 0.26))
            path.addLine(to: CGPoint(x: w * 0.95, y: h * 0.22)) // Right hand
            path.addLine(to: CGPoint(x: w * 0.92, y: h * 0.18))
            path.addQuadCurve(to: CGPoint(x: w * 0.62, y: h * 0.11), control: CGPoint(x: w * 0.8, y: h * 0.14))
        } else {
            // Side silhouette
            path.addEllipse(in: CGRect(x: w * 0.35, y: h * 0.02, width: w * 0.22, height: h * 0.1))

            path.move(to: CGPoint(x: w * 0.40, y: h * 0.11))
            path.addCurve(to: CGPoint(x: w * 0.32, y: h * 0.35),
                          control1: CGPoint(x: w * 0.35, y: h * 0.15),
                          control2: CGPoint(x: w * 0.30, y: h * 0.25))
            path.addCurve(to: CGPoint(x: w * 0.35, y: h * 0.55),
                          control1: CGPoint(x: w * 0.34, y: h * 0.45),
                          control2: CGPoint(x: w * 0.38, y: h * 0.50))
            path.addLine(to: CGPoint(x: w * 0.38, y: h * 0.95))
            path.addLine(to: CGPoint(x: w * 0.55, y: h * 0.95))
            path.addLine(to: CGPoint(x: w * 0.58, y: h * 0.55))
            path.addCurve(to: CGPoint(x: w * 0.55, y: h * 0.25),
                          control1: CGPoint(x: w * 0.62, y: h * 0.40),
                          control2: CGPoint(x: w * 0.60, y: h * 0.30))
            path.addQuadCurve(to: CGPoint(x: w * 0.52, y: h * 0.11), control: CGPoint(x: w * 0.52, y: h * 0.18))
        }

        return path
    }
}

// MARK: - Skeleton Overlay View
struct SkeletonOverlayView: View {
    let points: [DetectedBodyPoint]
    let size: CGSize
    let isStable: Bool
    let primaryColor: Color

    // Define bone connections
    private let boneConnections: [(String, String)] = [
        ("nose", "neck"),
        ("neck", "leftShoulder"),
        ("neck", "rightShoulder"),
        ("leftShoulder", "leftElbow"),
        ("rightShoulder", "rightElbow"),
        ("leftElbow", "leftWrist"),
        ("rightElbow", "rightWrist"),
        ("neck", "leftHip"),
        ("neck", "rightHip"),
        ("leftHip", "rightHip"),
        ("leftHip", "leftKnee"),
        ("rightHip", "rightKnee"),
        ("leftKnee", "leftAnkle"),
        ("rightKnee", "rightAnkle")
    ]

    var body: some View {
        Canvas { context, canvasSize in
            let pointsDict = Dictionary(uniqueKeysWithValues: points.map { ($0.id, $0) })

            // Draw bones (lines between joints)
            for (from, to) in boneConnections {
                if let fromPoint = pointsDict[from],
                   let toPoint = pointsDict[to] {
                    let start = CGPoint(
                        x: fromPoint.position.x * canvasSize.width,
                        y: fromPoint.position.y * canvasSize.height
                    )
                    let end = CGPoint(
                        x: toPoint.position.x * canvasSize.width,
                        y: toPoint.position.y * canvasSize.height
                    )

                    var path = Path()
                    path.move(to: start)
                    path.addLine(to: end)

                    let lineColor = isStable ? primaryColor : Color.white.opacity(0.8)
                    context.stroke(path, with: .color(lineColor), lineWidth: 3)
                }
            }

            // Draw joints (circles at each point)
            for point in points {
                let center = CGPoint(
                    x: point.position.x * canvasSize.width,
                    y: point.position.y * canvasSize.height
                )

                let radius: CGFloat = point.id == "nose" ? 10 : 6
                let circle = Path(ellipseIn: CGRect(
                    x: center.x - radius,
                    y: center.y - radius,
                    width: radius * 2,
                    height: radius * 2
                ))

                let fillColor = isStable ? primaryColor : Color.white
                context.fill(circle, with: .color(fillColor))

                // Add glow effect for stable state
                if isStable {
                    let glowCircle = Path(ellipseIn: CGRect(
                        x: center.x - radius - 2,
                        y: center.y - radius - 2,
                        width: (radius + 2) * 2,
                        height: (radius + 2) * 2
                    ))
                    context.stroke(glowCircle, with: .color(primaryColor.opacity(0.5)), lineWidth: 2)
                }
            }
        }
        .animation(.easeInOut(duration: 0.15), value: isStable)
    }
}

// MARK: - Audio Guide
class BodyScanAudioGuide: ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    private var lastSpokenText: String = ""
    private var lastSpeakTime: Date = .distantPast
    private var isConfigured = false

    enum SoundType {
        case beepValid
        case beepCapture
        case beepError
    }

    init() {
        configureAudioSession()
    }

    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            // Use playback category to mix with other audio and play through speaker
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers, .duckOthers])
            try audioSession.setActive(true)
            isConfigured = true
            print("[BodyScan Audio] Audio session configured successfully")
        } catch {
            print("[BodyScan Audio] Failed to configure audio session: \(error)")
        }
    }

    func speak(_ text: String, force: Bool = false) {
        // Ensure audio session is active
        if !isConfigured {
            configureAudioSession()
        }

        // Debounce - don't repeat same message within 3 seconds
        let now = Date()
        if !force && text == lastSpokenText && now.timeIntervalSince(lastSpeakTime) < 3.0 {
            return
        }

        // Stop any current speech
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 1.0
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0 // Max volume
        utterance.preUtteranceDelay = 0.1
        utterance.postUtteranceDelay = 0.1

        // Use a natural sounding voice - prefer Samantha (common US English voice)
        if let voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.Samantha-compact") {
            utterance.voice = voice
        } else if let voice = AVSpeechSynthesisVoice(language: "en-US") {
            utterance.voice = voice
        }

        lastSpokenText = text
        lastSpeakTime = now

        print("[BodyScan Audio] Speaking: \(text)")
        synthesizer.speak(utterance)
    }

    func playSound(_ type: SoundType) {
        // Ensure audio session is active
        if !isConfigured {
            configureAudioSession()
        }

        // Use system sounds for feedback
        switch type {
        case .beepValid:
            AudioServicesPlaySystemSound(1052) // Light tap
            print("[BodyScan Audio] Playing beep valid sound")
        case .beepCapture:
            AudioServicesPlaySystemSound(1108) // Camera shutter
            print("[BodyScan Audio] Playing capture sound")
        case .beepError:
            AudioServicesPlaySystemSound(1053) // Error
            print("[BodyScan Audio] Playing error sound")
        }
    }

    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
}

// MARK: - Camera Session Manager (Thread-safe, non-actor)
/// Manages AVCaptureSession on a dedicated serial queue to avoid actor isolation issues
final class CameraSessionManager: NSObject {
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "bodyscan.camera.session")
    private let videoQueue = DispatchQueue(label: "bodyscan.camera.video")
    private var isConfigured = false

    func configure(videoDelegate: AVCaptureVideoDataOutputSampleBufferDelegate?, completion: @escaping () -> Void) {
        sessionQueue.async { [weak self] in
            guard let self = self, !self.isConfigured else { return }

            self.session.beginConfiguration()
            self.session.sessionPreset = .high

            // Front camera
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
                  let input = try? AVCaptureDeviceInput(device: device) else {
                print("[CameraManager] Failed to get front camera")
                self.session.commitConfiguration()
                return
            }

            if self.session.canAddInput(input) {
                self.session.addInput(input)
            }

            // Video output for pose detection
            self.videoOutput.setSampleBufferDelegate(videoDelegate, queue: self.videoQueue)
            self.videoOutput.alwaysDiscardsLateVideoFrames = true
            if self.session.canAddOutput(self.videoOutput) {
                self.session.addOutput(self.videoOutput)
            }

            // Photo output for captures
            if self.session.canAddOutput(self.photoOutput) {
                self.session.addOutput(self.photoOutput)
            }

            self.session.commitConfiguration()
            self.isConfigured = true
            self.session.startRunning()

            DispatchQueue.main.async {
                completion()
            }
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
                print("[CameraManager] Session stopped")
            }
        }
    }

    func capturePhoto(delegate: AVCapturePhotoCaptureDelegate) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            let settings = AVCapturePhotoSettings()
            self.photoOutput.capturePhoto(with: settings, delegate: delegate)
        }
    }
}
