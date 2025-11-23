import SwiftUI
import AVFoundation
import CoreMotion

public struct CustomCameraView: View {
    @Binding public var capturedImage: UIImage?
    public var onVideoCaptured: ((URL) -> Void)?
    public var mode: MediaType = .image
    
    @Environment(\.dismiss) var dismiss
    
    @StateObject private var camera = CameraModel()
    @State private var showFocusIndicator = false
    @State private var focusLocation: CGPoint = .zero
    @State private var recordingTimer: Timer?
    @State private var recordingDuration: TimeInterval = 0
    @State private var isRecording = false
    
    // Quality feedback states
    @State private var qualityScore: Int = 0  // Start at 0 to show real detection
    @State private var isStable = false
    @State private var isWellLit = false
    @State private var motionUpdateTimer: Timer?
    @State private var lightingTimer: Timer?
    
    // Individual quality metrics (0-1 scale)
    @State private var stabilityScore: Double = 0
    @State private var lightingScore: Double = 0
    @State private var overallQuality: Double = 0
    
    // UI states
    @State private var showFirstUseOverlay = false
    
    // Motion manager
    private let motionManager = CMMotionManager()
    
    public init(capturedImage: Binding<UIImage?>, onVideoCaptured: ((URL) -> Void)? = nil, mode: MediaType = .image) {
        self._capturedImage = capturedImage
        self.onVideoCaptured = onVideoCaptured
        self.mode = mode
    }
    
    public var body: some View {
        mainContent
            .background(Color.black)
            .overlay(glowEffect)
            .overlay(tutorialOverlay)
            .onAppear(perform: handleOnAppear)
            .onDisappear(perform: handleOnDisappear)
            .alert("Camera Access", isPresented: $camera.showAlert) {
                Button("Settings") {
                    guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
                        print("❌ Failed to create Settings URL")
                        return
                    }
                    UIApplication.shared.open(settingsURL)
                }
                Button("Cancel", role: .cancel) { dismiss() }
            } message: {
                Text(camera.alertMessage)
            }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        ZStack {
            // Camera layer
            cameraLayer

            // Focus indicator
            if showFocusIndicator {
                focusIndicatorView
            }

            // Processing indicator
            if camera.isProcessingPhoto {
                processingOverlay
            }

            // Controls overlay
            controlsOverlay
        }
    }

    @ViewBuilder
    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)

                Text("Processing...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.7))
            )
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.2), value: camera.isProcessingPhoto)
    }
    
    @ViewBuilder
    private var controlsOverlay: some View {
        VStack {
            topBar
            
            if mode == .video {
                qualityIndicators
            }
            
            Spacer()
            
            bottomControls
        }
    }
    
    @ViewBuilder
    private var topBar: some View {
        HStack {
            Button("Cancel") {
                dismiss()
            }
            .foregroundColor(.white)
            
            Spacer()
            
            if isRecording {
                recordingStatus
            }
            
            Spacer()
            
            Button(action: {
                camera.toggleFlash()
            }) {
                Image(systemName: camera.flashMode == .on ? "bolt.fill" : "bolt.slash.fill")
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private var recordingStatus: some View {
        Text(timeString(from: recordingDuration))
            .font(.system(size: 17, weight: .medium, design: .monospaced))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.red)
            .cornerRadius(4)
    }
    
    @ViewBuilder
    private var qualityIndicators: some View {
        HStack(spacing: 20) {
            movementIndicator
            
            Divider()
                .frame(height: 20)
                .background(Color.white.opacity(0.2))
            
            brightnessIndicator
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.4))
        )
        .padding(.horizontal, 20)
        .padding(.top, -4)
    }
    
    @ViewBuilder
    private var movementIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
            
            HStack(spacing: 2) {
                ForEach(0..<3) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(stabilityScore > 0.3 ? Color.green : Color.red)
                        .frame(width: 3, height: CGFloat(8 + index * 3))
                        .opacity(stabilityScore < (0.3 + Double(index) * 0.3) ? 0.3 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: stabilityScore)
                }
            }
        }
    }
    
    @ViewBuilder
    private var brightnessIndicator: some View {
        HStack(spacing: 6) {
            Image(systemName: lightingScore < 0.5 ? "sun.max.trianglebadge.exclamationmark" : "sun.max")
                .font(.system(size: 14))
                .foregroundColor(lightingScore < 0.5 ? Color.red : .white.opacity(0.6))
            
            Text(getBrightnessText())
                .font(.system(size: 12))
                .foregroundColor(lightingScore < 0.5 ? Color.red : .white.opacity(0.8))
        }
    }
    
    @ViewBuilder
    private var bottomControls: some View {
        HStack(spacing: 60) {
            // Empty spacer to maintain balance
            Color.clear
                .frame(width: 50, height: 50)
            
            captureButton
            flipCameraButton
        }
        .padding(.bottom, 30)
    }
    
    
    @ViewBuilder
    private var captureButton: some View {
        Button(action: {
            if mode == .image {
                camera.capturePhoto()
            } else {
                if isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
            }
        }) {
            ZStack {
                Circle()
                    .stroke(Color.white, lineWidth: 4)
                    .frame(width: 70, height: 70)
                    .scaleEffect(isRecording ? 0.9 : 1.0)
                    .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isRecording)
                
                if mode == .video && isRecording {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.red)
                        .frame(width: 30, height: 30)
                } else {
                    Circle()
                        .fill(mode == .image ? Color.white : Color.red)
                        .frame(width: mode == .image ? 60 : 65, height: mode == .image ? 60 : 65)
                }
            }
        }
    }
    
    @ViewBuilder
    private var flipCameraButton: some View {
        Button(action: {
            camera.switchCamera()
        }) {
            Image(systemName: "camera.rotate")
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(Color.white.opacity(0.3))
                .clipShape(Circle())
        }
    }
    
    private func handleOnAppear() {
        camera.setup(mode: mode)
        camera.onPhotoCaptured = { image in
            capturedImage = image
            dismiss()
        }
        camera.onVideoCaptured = { url in
            onVideoCaptured?(url)
            // Auto-dismiss after video is captured to proceed to trim view
            dismiss()
        }
        
        if mode == .video {
            let hasSeenTutorial = UserDefaults.standard.bool(forKey: "hasSeenCameraQualityTutorial")
            let neverShowAgain = UserDefaults.standard.bool(forKey: "neverShowCameraQualityTutorial")
            
            if !hasSeenTutorial && !neverShowAgain {
                showFirstUseOverlay = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                startQualityMonitoring()
            }
        }
    }
    
    private func handleOnDisappear() {
        camera.stop()
        stopRecording()
        stopQualityMonitoring()
    }
    
    
    // MARK: - View Components
    
    private var cameraLayer: some View {
        CameraPreview(camera: camera)
            .ignoresSafeArea()
            .onTapGesture { location in
                focusLocation = location
                showFocusIndicator = true
                camera.setFocus(point: location)
                withAnimation(.easeOut(duration: 1.5)) {
                    showFocusIndicator = false
                }
            }
            .overlay(recordingOverlay)
    }
    
    private var focusIndicatorView: some View {
        RoundedRectangle(cornerRadius: 8)
            .stroke(Color.blue, lineWidth: 2)
            .frame(width: 80, height: 80)
            .position(focusLocation)
            .scaleEffect(showFocusIndicator ? 1.0 : 0.8)
            .opacity(showFocusIndicator ? 1.0 : 0)
            .animation(.easeOut(duration: 0.3), value: showFocusIndicator)
    }
    
    @ViewBuilder
    private var tutorialOverlay: some View {
        if showFirstUseOverlay {
            ZStack {
                // Tutorial card
                CameraQualityTutorial(isShowing: $showFirstUseOverlay)
                    .transition(.scale.combined(with: .opacity))
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.3), value: showFirstUseOverlay)
        }
    }
    
    @ViewBuilder
    private var recordingOverlay: some View {
        // Removed red overlay when recording
        EmptyView()
    }
    
    @ViewBuilder
    private var qualityFeedbackOverlay: some View {
        // Removed - using progress bar instead
        EmptyView()
    }
    
    @ViewBuilder
    private var glowEffect: some View {
        if mode == .video {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.blue.opacity(0.3),
                            Color.blue.opacity(0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 100,
                        endRadius: 300
                    )
                )
                .frame(width: 600, height: 600)
                .scaleEffect(isRecording ? 1.2 : 1.0)
                .opacity(isRecording ? 0.4 : 0.2)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isRecording)
                .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height - 200)
                .allowsHitTesting(false)
        }
    }
    
    
    
    private func startRecording() {
        isRecording = true
        recordingDuration = 0
        camera.startRecording()
        
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            recordingDuration += 0.1
            // Support up to 1 hour recording
            if recordingDuration >= 3600 {
                stopRecording()
            }
        }
    }
    
    private func stopRecording() {
        isRecording = false
        recordingTimer?.invalidate()
        recordingTimer = nil
        camera.stopRecording()
    }
    
    private func timeString(from interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func getBrightnessText() -> String {
        if lightingScore < 0.5 {
            // Dark conditions - check if flash is available and off
            if camera.flashMode == .off {
                return "Turn on flash"
            } else {
                return "Add lighting"
            }
        } else {
            return "Good lighting"
        }
    }
    
    // MARK: - Quality Monitoring
    private func startQualityMonitoring() {
        print("🎯 Starting quality monitoring...")
        
        // Start motion monitoring directly (CoreMotion handles permissions internally)
        startMotionMonitoring()
        
        // Start lighting monitoring
        startLightingMonitoring()
        
        // Update quality score periodically - faster for more responsive UI
        motionUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.updateEnhancedQualityScore()
        }
    }
    
    private func stopQualityMonitoring() {
        print("🚫 Stopping quality monitoring")
        motionManager.stopDeviceMotionUpdates()
        motionUpdateTimer?.invalidate()
        motionUpdateTimer = nil
        lightingTimer?.invalidate()
        lightingTimer = nil
    }
    
    private func startMotionMonitoring() {
        guard motionManager.isDeviceMotionAvailable else {
            print("⚠️ Device motion not available")
            // Fallback to assuming stable
            self.isStable = true
            return
        }
        
        print("📱 Starting motion monitoring...")
        motionManager.deviceMotionUpdateInterval = 0.1
        motionManager.startDeviceMotionUpdates(to: .main) { motion, error in
            guard let motion = motion else {
                if let error = error {
                    print("❌ Motion error: \(error)")
                }
                return
            }
            
            // Calculate stability based on acceleration
            let acceleration = motion.userAcceleration
            let totalAcceleration = sqrt(
                acceleration.x * acceleration.x +
                acceleration.y * acceleration.y +
                acceleration.z * acceleration.z
            )
            
            // Threshold for stability - more forgiving (only flag significant movement)
            let wasStable = self.isStable
            self.isStable = totalAcceleration < 1.5  // Increased from 0.5 to 1.5
            
            if wasStable != self.isStable {
                print("🏃 Stability changed: \(self.isStable ? "Stable" : "Moving") (accel: \(String(format: "%.2f", totalAcceleration)))")
            }
        }
    }
    
    private func startLightingMonitoring() {
        print("💡 Starting lighting monitoring...")
        // Check lighting conditions using camera exposure
        lightingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            guard let device = self.camera.currentDevice else {
                print("⚠️ No camera device available for lighting check")
                return
            }
            
            do {
                try device.lockForConfiguration()
                
                // Use exposure duration and ISO to estimate lighting
                let exposureDuration = device.exposureDuration.seconds
                let iso = device.iso
                
                // Simple heuristic: shorter exposure + lower ISO = better lighting
                // These thresholds are approximate and may need tuning
                let exposureScore = max(0.0, min(1.0, (0.033 - exposureDuration) / 0.033))
                let isoScore = max(0.0, min(1.0, Double(800 - iso) / 800))
                
                let lightingScore = (exposureScore + isoScore) / 2
                let wasWellLit = self.isWellLit
                self.isWellLit = lightingScore > 0.5
                
                if wasWellLit != self.isWellLit {
                    print("💡 Lighting changed: \(self.isWellLit ? "Good" : "Poor") (score: \(String(format: "%.2f", lightingScore)), ISO: \(iso), exposure: \(String(format: "%.4f", exposureDuration)))")
                }
                
                device.unlockForConfiguration()
            } catch {
                print("❌ Failed to check lighting: \(error)")
            }
        }
    }
    
    private func updateQualityScore() {
        // Calculate more granular scores
        var stabilityScore = 0.0
        var lightingScore = 0.0
        
        // Get current motion data for stability score
        if let motion = motionManager.deviceMotion {
            let acceleration = motion.userAcceleration
            let totalAcceleration = sqrt(
                acceleration.x * acceleration.x +
                acceleration.y * acceleration.y +
                acceleration.z * acceleration.z
            )
            
            // Convert acceleration to stability score (0-100)
            // 0 acceleration = 100% stable, 1.0+ acceleration = 0% stable
            stabilityScore = max(0, min(100, (1.0 - totalAcceleration) * 100))
        } else {
            // No motion data, assume moderate stability
            stabilityScore = isStable ? 75 : 25
        }
        
        // Get current lighting score
        if let device = camera.currentDevice {
            do {
                try device.lockForConfiguration()
                
                let exposureDuration = device.exposureDuration.seconds
                let iso = device.iso
                
                // Calculate lighting score based on exposure and ISO
                // More sensitive - flag moderate lighting issues
                // ISO above 800 and exposure above 1/30s indicates suboptimal lighting
                let exposureScore = exposureDuration < 0.033 ? 1.0 : max(0.0, min(1.0, (0.05 - exposureDuration) / 0.017))
                let isoScore = iso < 800 ? 1.0 : max(0.0, min(1.0, (1600.0 - Double(iso)) / 800.0))
                
                lightingScore = ((exposureScore + isoScore) / 2) * 100
                
                device.unlockForConfiguration()
            } catch {
                // Error getting lighting, use basic score
                lightingScore = isWellLit ? 75 : 25
            }
        } else {
            lightingScore = isWellLit ? 75 : 25
        }
        
        // Calculate weighted average (60% stability, 40% lighting)
        let score = Int((stabilityScore * 0.6) + (lightingScore * 0.4))
        
        if qualityScore != score {
            print("📊 Quality score: \(score)% (Stability: \(Int(stabilityScore))%, Lighting: \(Int(lightingScore))%)")
        }
        
        // Smooth the score changes
        withAnimation(.easeInOut(duration: 0.3)) {
            qualityScore = score
        }
    }
    
    // MARK: - Enhanced Quality Monitoring
    private func updateEnhancedQualityScore() {
        // Update individual scores (0-1 scale)
        if let motion = motionManager.deviceMotion {
            let acceleration = motion.userAcceleration
            let totalAcceleration = sqrt(
                acceleration.x * acceleration.x +
                acceleration.y * acceleration.y +
                acceleration.z * acceleration.z
            )
            // Map acceleration to score: 0-0.3 = 100%, 0.3-1.5 = gradual decrease, 1.5+ = 0%
            if totalAcceleration < 0.3 {
                stabilityScore = 1.0
            } else if totalAcceleration < 1.5 {
                stabilityScore = max(0, min(1, (1.5 - totalAcceleration) / 1.2))
            } else {
                stabilityScore = 0.0
            }
        } else {
            stabilityScore = isStable ? 0.9 : 0.3
        }
        
        // Update lighting score
        if let device = camera.currentDevice {
            do {
                try device.lockForConfiguration()
                
                let exposureDuration = device.exposureDuration.seconds
                let iso = device.iso
                
                // More sensitive thresholds for better lighting detection
                // When camera is blocked, ISO typically maxes out (3200-6400) and exposure is long
                let exposureScore = exposureDuration < 0.033 ? 1.0 : max(0.0, min(1.0, (0.05 - exposureDuration) / 0.017))
                let isoScore = iso < 800 ? 1.0 : max(0.0, min(1.0, (1600.0 - Double(iso)) / 800.0))
                
                lightingScore = (exposureScore + isoScore) / 2
                
                // Additional check for very dark conditions (camera blocked)
                if iso >= 3200 || exposureDuration >= 0.125 {
                    lightingScore = 0.0 // Force to 0 for extremely dark conditions
                }
                
                // Debug logging - log occasionally to see values
                if Int.random(in: 0..<10) == 0 {
                    print("📸 Camera metrics - ISO: \(iso), Exposure: \(String(format: "%.4f", exposureDuration))s, Score: \(String(format: "%.2f", lightingScore))")
                }
                
                device.unlockForConfiguration()
            } catch {
                lightingScore = isWellLit ? 0.8 : 0.3
            }
        } else {
            lightingScore = isWellLit ? 0.8 : 0.3
        }
        
        // Calculate overall quality (minimum of both metrics)
        overallQuality = min(stabilityScore, lightingScore)
        
        // Update legacy quality score for existing UI
        qualityScore = Int(overallQuality * 100)
    }
}

struct CameraPreview: UIViewRepresentable {
    let camera: CameraModel
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        camera.preview.frame = view.bounds
        camera.preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(camera.preview)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

@MainActor
class CameraModel: NSObject, ObservableObject, @preconcurrency AVCapturePhotoCaptureDelegate, @preconcurrency AVCaptureFileOutputRecordingDelegate {
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var flashMode: AVCaptureDevice.FlashMode = .off
    @Published var currentFrameRate: Int = 30
    @Published var isProcessingPhoto = false

    let session = AVCaptureSession()
    let preview = AVCaptureVideoPreviewLayer()
    let photoOutput = AVCapturePhotoOutput()
    let videoOutput = AVCaptureMovieFileOutput()

    var onPhotoCaptured: ((UIImage) -> Void)?
    var onVideoCaptured: ((URL) -> Void)?

    private var currentMode: MediaType = .image
    
    // Expose current device for lighting checks
    var currentDevice: AVCaptureDevice? {
        return (session.inputs.first as? AVCaptureDeviceInput)?.device
    }
    
    func setup(mode: MediaType) {
        currentMode = mode
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async { self?.setupCamera() }
                } else {
                    DispatchQueue.main.async {
                        self?.alertMessage = "Camera access is required to capture photos and videos."
                        self?.showAlert = true
                    }
                }
            }
        default:
            alertMessage = "Please enable camera access in Settings to use this feature."
            showAlert = true
        }
    }
    
    private func setupCamera() {
        session.beginConfiguration()

        // Use back camera by default for better quality photos, front camera for selfies
        // For photo mode, prefer back camera unless explicitly switched
        let preferredPosition: AVCaptureDevice.Position = currentMode == .image ? .back : .front
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: preferredPosition),
              let input = try? AVCaptureDeviceInput(device: device) else {
            print("❌ Failed to get camera device for position: \(preferredPosition)")
            return
        }

        // Set session preset for photo mode (video mode will be configured after session setup)
        if currentMode == .image {
            // For photo mode, use .photo preset for highest quality and maximum resolution
            // This enables highest ISO/exposure ranges, phase detection autofocus, and full resolution JPEG output
            session.sessionPreset = .photo
        }

        if session.canAddInput(input) {
            session.addInput(input)
        }

        // Configure camera for optimal photo quality (especially important for front camera)
        do {
            try device.lockForConfiguration()

            // Enable low light boost for better front camera performance
            if device.isLowLightBoostSupported {
                device.automaticallyEnablesLowLightBoostWhenAvailable = true
            }

            // Set exposure mode to continuous auto for best results
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }

            // Enable continuous autofocus
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }

            device.unlockForConfiguration()
        } catch {
            print("❌ Failed to configure camera settings: \(error)")
        }

        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            if #available(iOS 16.0, *) {
                // Use maxPhotoDimensions for iOS 16+
                if photoOutput.connection(with: .video) != nil {
                    if let maxDimensions = device.activeFormat.supportedMaxPhotoDimensions.last {
                        photoOutput.maxPhotoDimensions = maxDimensions
                    }
                }
            } else {
                // Fallback for older iOS versions
                photoOutput.isHighResolutionCaptureEnabled = true
            }

            // Set maximum quality prioritization (iOS 13+)
            if #available(iOS 13.0, *) {
                photoOutput.maxPhotoQualityPrioritization = .quality
            }
        }

        if currentMode == .video && session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            // Support up to 1 hour video recording
            videoOutput.maxRecordedDuration = CMTime(seconds: 3600, preferredTimescale: 1)

            // Set proper video orientation
            if let connection = videoOutput.connection(with: .video) {
                if #available(iOS 17.0, *) {
                    if connection.isVideoRotationAngleSupported(90) {
                        connection.videoRotationAngle = 90
                    }
                } else {
                    if connection.isVideoOrientationSupported {
                        connection.videoOrientation = .portrait
                    }
                }
            }
        }

        preview.session = session
        preview.videoGravity = .resizeAspectFill
        session.commitConfiguration()

        // Configure high frame rate AFTER committing session configuration
        // This prevents crashes when device capabilities don't match desired settings
        if currentMode == .video {
            configureHighFrameRateVideo(device: device)
        }

        // Start camera session with higher priority for faster startup
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            self?.session.startRunning()
            print("📸 Camera session started")
        }
    }
    
    private func configureHighFrameRateVideo(device: AVCaptureDevice) {
        do {
            try device.lockForConfiguration()
            defer { device.unlockForConfiguration() }

            // Helper to prefer 1080p formats and then highest FPS the device truly supports
            func bestFormat(for device: AVCaptureDevice) -> (format: AVCaptureDevice.Format, range: AVFrameRateRange)? {
                // Prefer 1080p if available, otherwise sort all formats by max FPS
                let allFormats = device.formats
                let preferred = allFormats.filter { format in
                    let d = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
                    return d.width == 1920 && d.height == 1080
                }
                let candidates = preferred.isEmpty ? allFormats : preferred

                // Choose the format that offers the highest max FPS actually reported by the range
                return candidates.compactMap { format in
                    guard let range = format.videoSupportedFrameRateRanges.first else { return nil }
                    return (format, range)
                }
                .sorted { lhs, rhs in lhs.range.maxFrameRate > rhs.range.maxFrameRate }
                .first
            }

            guard let (format, range) = bestFormat(for: device) else {
                print("⚠️ No suitable format found; falling back to 1080p preset if possible")
                if session.canSetSessionPreset(.hd1920x1080) { session.sessionPreset = .hd1920x1080 }
                return
            }

            // Apply the chosen format first
            device.activeFormat = format

            // Compute a safe target FPS based on camera position and actual supported range
            // Back cameras: try 240 → 120 → 60 → 30; Front: try 60 → 30
            let tiersBack: [Double] = [240, 120, 60, 30]
            let tiersFront: [Double] = [60, 30]
            let tiers = (device.position == .back) ? tiersBack : tiersFront

            let maxSupported = range.maxFrameRate
            let target = tiers.first(where: { $0 <= maxSupported }) ?? min(30.0, maxSupported)

            // Set frame duration to exactly the target FPS (within supported range)
            let duration = CMTime(value: 1, timescale: Int32(target.rounded()))

            // Clamp to supported range just to be extra safe
            if target >= range.minFrameRate && target <= range.maxFrameRate {
                device.activeVideoMinFrameDuration = duration
                device.activeVideoMaxFrameDuration = duration
                currentFrameRate = Int(target)
                print("📹 Camera configured at \(Int(target)) FPS (max supported: \(Int(maxSupported)))")
            } else {
                // Fall back to the range maximum (typically minFrameDuration)
                device.activeVideoMinFrameDuration = range.minFrameDuration
                device.activeVideoMaxFrameDuration = range.minFrameDuration
                currentFrameRate = Int(range.maxFrameRate)
                print("📹 Camera configured at device max FPS \(currentFrameRate)")
            }

            // Prefer not to touch sessionPreset here; leave resolution to activeFormat choice
            // but keep stabilization if available
            if let connection = videoOutput.connection(with: .video), connection.isVideoStabilizationSupported {
                connection.preferredVideoStabilizationMode = .auto
            }
        } catch {
            print("❌ Failed to configure high frame rate: \(error)")
            if session.canSetSessionPreset(.hd1920x1080) { session.sessionPreset = .hd1920x1080 }
        }
    }
    
    func capturePhoto() {
        // Show processing indicator immediately
        isProcessingPhoto = true

        // Prepare haptic feedback asynchronously (non-blocking)
        DispatchQueue.global(qos: .userInteractive).async {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred()
        }

        let settings = AVCapturePhotoSettings()
        settings.flashMode = flashMode

        // Enable high resolution for this capture
        settings.isHighResolutionPhotoEnabled = true

        // Set quality prioritization to maximum (iOS 13+)
        if #available(iOS 13.0, *) {
            settings.photoQualityPrioritization = .quality
        }

        // Enable auto still image stabilization for sharper photos
        settings.isAutoStillImageStabilizationEnabled = true

        // Enable auto red-eye reduction for better quality
        settings.isAutoRedEyeReductionEnabled = true

        print("📸 Capturing photo with settings: flashMode=\(flashMode.rawValue), highRes=true, quality=max")
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func startRecording() {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).mov")
        
        // Set video orientation before recording
        if let connection = videoOutput.connection(with: .video) {
            if #available(iOS 17.0, *) {
                if connection.isVideoRotationAngleSupported(90) {
                    connection.videoRotationAngle = 90
                }
            } else {
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = .portrait
                }
            }
        }
        
        // Torch should already be on if flash mode is on, but ensure it stays on
        // This is just a safety check in case torch was turned off somehow
        
        videoOutput.startRecording(to: tempURL, recordingDelegate: self)
    }
    
    func stopRecording() {
        videoOutput.stopRecording()
        
        // Keep torch on if flash mode is still on, otherwise turn it off
        if flashMode == .off, let device = (session.inputs.first as? AVCaptureDeviceInput)?.device {
            do {
                try device.lockForConfiguration()
                if device.hasTorch {
                    device.torchMode = .off
                }
                device.unlockForConfiguration()
            } catch {
                print("Failed to turn off torch: \(error)")
            }
        }
    }
    
    func switchCamera() {
        session.beginConfiguration()
        guard let currentInput = session.inputs.first as? AVCaptureDeviceInput else { return }
        session.removeInput(currentInput)

        let position: AVCaptureDevice.Position = currentInput.device.position == .back ? .front : .back
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
              let input = try? AVCaptureDeviceInput(device: device) else { return }

        if session.canAddInput(input) {
            session.addInput(input)
        }

        session.commitConfiguration()

        // Configure frame rate AFTER committing session changes
        // This prevents crashes when switching between cameras with different capabilities
        if currentMode == .video {
            configureHighFrameRateVideo(device: device)
        }

        // Restore torch state for video mode after switching cameras
        if currentMode == .video && flashMode == .on {
            do {
                try device.lockForConfiguration()
                if device.hasTorch && device.isTorchAvailable {
                    try device.setTorchModeOn(level: 1.0)
                }
                device.unlockForConfiguration()
            } catch {
                print("Failed to restore torch after camera switch: \(error)")
            }
        }
    }
    
    func toggleFlash() {
        flashMode = flashMode == .off ? .on : .off
        
        // For video mode, we need to toggle torch
        guard let device = (session.inputs.first as? AVCaptureDeviceInput)?.device else { return }
        
        do {
            try device.lockForConfiguration()
            
            if currentMode == .video {
                // For video, use torch mode immediately
                if device.hasTorch && device.isTorchAvailable {
                    if flashMode == .on {
                        try device.setTorchModeOn(level: 1.0)
                    } else {
                        device.torchMode = .off
                    }
                }
            }
            
            device.unlockForConfiguration()
        } catch {
            print("Failed to toggle flash/torch: \(error)")
        }
    }
    
    func setFocus(point: CGPoint) {
        guard let device = (session.inputs.first as? AVCaptureDeviceInput)?.device,
              device.isFocusPointOfInterestSupported else { return }
        
        do {
            try device.lockForConfiguration()
            device.focusPointOfInterest = preview.captureDevicePointConverted(fromLayerPoint: point)
            device.focusMode = .autoFocus
            device.unlockForConfiguration()
        } catch {}
    }
    
    func stop() {
        session.stopRunning()
    }
    
    // MARK: - AVCapturePhotoCaptureDelegate
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("❌ Photo capture error: \(error)")
            DispatchQueue.main.async { [weak self] in
                self?.isProcessingPhoto = false
            }
            return
        }

        // Process photo on background thread to avoid UI lag
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let data = photo.fileDataRepresentation(),
                  var image = UIImage(data: data) else {
                print("❌ Failed to get photo data")
                DispatchQueue.main.async {
                    self?.isProcessingPhoto = false
                }
                return
            }

            print("📸 Processing photo: original size \(image.size.width)x\(image.size.height)")

            // Optimize image size for better performance
            // Compress to reasonable size while maintaining quality
            let maxDimension: CGFloat = 2048 // Good balance between quality and performance
            let size = image.size

            if size.width > maxDimension || size.height > maxDimension {
                let scale = maxDimension / max(size.width, size.height)
                let newSize = CGSize(width: size.width * scale, height: size.height * scale)

                UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
                image.draw(in: CGRect(origin: .zero, size: newSize))
                if let resizedImage = UIGraphicsGetImageFromCurrentImageContext() {
                    image = resizedImage
                    print("📸 Resized to: \(newSize.width)x\(newSize.height)")
                }
                UIGraphicsEndImageContext()
            }

            // Compress to JPEG with high quality (0.85 is a good balance)
            if let compressedData = image.jpegData(compressionQuality: 0.85),
               let optimizedImage = UIImage(data: compressedData) {
                image = optimizedImage
                print("📸 Compressed image size: \(compressedData.count / 1024)KB")
            }

            // Return to main thread to update UI
            DispatchQueue.main.async {
                self?.isProcessingPhoto = false
                self?.onPhotoCaptured?(image)
                print("✅ Photo processing complete")
            }
        }
    }
    
    // MARK: - AVCaptureFileOutputRecordingDelegate
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        guard error == nil else { return }
        
        // Log the recorded video orientation for debugging
        Task {
            let asset = AVAsset(url: outputFileURL)
            if let track = try? await asset.loadTracks(withMediaType: .video).first {
                let transform = try? await track.load(.preferredTransform)
                let naturalSize = try? await track.load(.naturalSize)
                if let transform = transform {
                    let angle = atan2(transform.b, transform.a) * 180 / .pi
                    print("📹 [CustomCameraView] Recorded video - Transform angle: \(angle), Natural size: \(naturalSize ?? .zero)")
                }
            }
        }
        
        onVideoCaptured?(outputFileURL)
    }
}
