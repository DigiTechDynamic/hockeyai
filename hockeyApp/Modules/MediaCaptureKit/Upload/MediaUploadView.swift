import SwiftUI
import AVKit
import PhotosUI
import UIKit

// MARK: - Media Upload View
/// A unified, reusable component for uploading photos or videos
/// Can be configured for different media types and display options
public struct MediaUploadView: View {
    
    // MARK: - Configuration
    public struct Configuration {
        public let title: String
        public let description: String
        public let instructions: String
        public let mediaType: MediaType
        public let buttonTitle: String
        public let showSourceSelector: Bool
        public let showTrimmerImmediately: Bool
        public let customTrimmer: ((URL, @escaping (URL?) -> Void) -> AnyView)?
        // Optional pre-camera guide shown only when user selects "Record Video"
        // Builder receives an onComplete callback that should be invoked to proceed to camera.
        public let preCameraGuideBuilder: ((@escaping () -> Void) -> AnyView)?
        
        // Theme colors (optional for decoupling)
        public let primaryColor: Color?
        public let backgroundColor: Color?
        public let surfaceColor: Color?
        public let textColor: Color?
        public let textSecondaryColor: Color?
        public let successColor: Color?
        public let cornerRadius: CGFloat?
        
        public init(
            title: String,
            description: String,
            instructions: String,
            mediaType: MediaType,
            buttonTitle: String? = nil,
            showSourceSelector: Bool = true,
            showTrimmerImmediately: Bool = false,
            customTrimmer: ((URL, @escaping (URL?) -> Void) -> AnyView)? = nil,
            preCameraGuideBuilder: ((@escaping () -> Void) -> AnyView)? = nil,
            primaryColor: Color? = nil,
            backgroundColor: Color? = nil,
            surfaceColor: Color? = nil,
            textColor: Color? = nil,
            textSecondaryColor: Color? = nil,
            successColor: Color? = nil,
            cornerRadius: CGFloat? = nil
        ) {
            self.title = title
            self.description = description
            self.instructions = instructions
            self.mediaType = mediaType
            self.buttonTitle = buttonTitle ?? (mediaType == .image ? "Add Photo" : "Add Video")
            self.showSourceSelector = showSourceSelector
            self.showTrimmerImmediately = showTrimmerImmediately
            self.customTrimmer = customTrimmer
            self.preCameraGuideBuilder = preCameraGuideBuilder
            self.primaryColor = primaryColor
            self.backgroundColor = backgroundColor
            self.surfaceColor = surfaceColor
            self.textColor = textColor
            self.textSecondaryColor = textSecondaryColor
            self.successColor = successColor
            self.cornerRadius = cornerRadius
        }
    }
    
    // MARK: - Properties
    @Environment(\.theme) var theme
    public let configuration: Configuration
    @Binding public var selectedImage: UIImage?
    @Binding public var selectedVideoURL: URL?
    public let onMediaSelected: ((MediaType, Any) -> Void)?
    
    // MARK: - State
    @State private var activeSheet: ActiveSheet?
    @State private var previousSheet: ActiveSheet?
    @State private var showRemoveConfirmation = false
    @State private var videoThumbnail: UIImage?
    @State private var videoAspectRatio: CGFloat?
    @State private var thumbnailGenerationFailed = false
    @State private var showVideoPlayer = false
    @State private var player: AVPlayer?
    @State private var isProcessingSelection = false
    @State private var isExpectingVideoSelection = false
    @State private var showFullScreenTrimmer = false
    @State private var trimmerVideoURL: URL?
    @State private var showVideoTooLongAlert = false
    @State private var rejectedVideoDuration: Double = 0
    @State private var showProcessingOverlay = false
    @State private var processingMessage = "Preparing video editor..."
    @State private var isThumbnailGenerating = false
    @State private var processingTimeoutTask: Task<Void, Never>?
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    // Pre-camera guide state
    @State private var showPreCameraGuide = false
    @State private var pendingOpenVideoCamera = false
    
    // Sheet types
    private enum ActiveSheet: Identifiable, Equatable {
        case sourceSelector
        case camera
        case photoLibrary
        case videoCamera
        case videoLibrary
        
        var id: String {
            switch self {
            case .sourceSelector: return "sourceSelector"
            case .camera: return "camera"
            case .photoLibrary: return "photoLibrary"
            case .videoCamera: return "videoCamera"
            case .videoLibrary: return "videoLibrary"
            }
        }
    }
    
    // MARK: - Initializers
    public init(
        configuration: Configuration,
        selectedImage: Binding<UIImage?>,
        selectedVideoURL: Binding<URL?>,
        onMediaSelected: ((MediaType, Any) -> Void)? = nil
    ) {
        self.configuration = configuration
        self._selectedImage = selectedImage
        self._selectedVideoURL = selectedVideoURL
        self.onMediaSelected = onMediaSelected
    }
    
    // Convenience initializer for photo only
    public init(
        configuration: Configuration,
        selectedImage: Binding<UIImage?>,
        onImageSelected: ((UIImage) -> Void)? = nil
    ) {
        self.configuration = configuration
        self._selectedImage = selectedImage
        self._selectedVideoURL = .constant(nil)
        self.onMediaSelected = { type, media in
            if type == .image, let image = media as? UIImage {
                onImageSelected?(image)
            }
        }
    }
    
    // Convenience initializer for video only
    public init(
        configuration: Configuration,
        selectedVideoURL: Binding<URL?>,
        onVideoSelected: ((URL) -> Void)? = nil
    ) {
        self.configuration = configuration
        self._selectedImage = .constant(nil)
        self._selectedVideoURL = selectedVideoURL
        self.onMediaSelected = { type, media in
            if type == .video, let url = media as? URL {
                onVideoSelected?(url)
            }
        }
    }
    
    // MARK: - Body
    public var body: some View {
        ZStack {
            // Show loading state inside the card instead of overlay
            if showProcessingOverlay {
                // Loading state card
                VStack(spacing: 24) {
                    // Icon and spinner grouped together
                    VStack(spacing: 16) {
                        // Video icon
                        Image(systemName: "video.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(configuration.primaryColor ?? Color.green)
                        
                        // Progress spinner
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: configuration.primaryColor ?? Color.green))
                            .scaleEffect(1.2)
                    }
                    
                    // Message text
                    Text(processingMessage)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(configuration.textColor ?? Color.primary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
                .padding(.horizontal, 40)
                .background(configuration.surfaceColor ?? Color(.secondarySystemBackground))
                .cornerRadius((configuration.cornerRadius ?? 12) * 1.5)
                .overlay(
                    RoundedRectangle(cornerRadius: (configuration.cornerRadius ?? 12) * 1.5)
                        .stroke((configuration.primaryColor ?? Color.green).opacity(0.3), lineWidth: 1)
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                // Normal card content
                VStack(spacing: 0) {
                    // Header with icon
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 16) {
                            Image(systemName: "video.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(configuration.primaryColor ?? Color.blue)
                            
                            Text(hasMedia ? "Media Captured" : configuration.title)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(configuration.textColor ?? Color.primary)
                                .tracking(0.5)
                            
                            Spacer()
                            
                            if hasMedia {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(configuration.successColor ?? Color.green)
                            }
                        }
                        
                        // Subtitle when video is recorded
                        if hasMedia && configuration.mediaType == .video {
                            Text("Tap to preview • Replace to re-record")
                                .font(.system(size: 14))
                                .foregroundColor(configuration.textSecondaryColor ?? Color.secondary)
                                .padding(.leading, 36) // Align with title text
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 16)
                    
                    // Instructions as checkmark list
                    if !hasMedia && !configuration.instructions.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(configuration.instructions.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }, id: \.self) { instruction in
                                HStack(spacing: 16) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor((configuration.successColor ?? Color.green).opacity(0.8))
                                    Text(instruction.replacingOccurrences(of: "•", with: "").trimmingCharacters(in: .whitespaces))
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(configuration.textSecondaryColor ?? Color.secondary)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                    
                    // Media Preview or Upload Button
                    if hasMedia {
                        mediaPreviewSection
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                    } else {
                        uploadButtonSection
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                            .padding(.bottom, 16)
                            .disabled(isProcessingSelection || activeSheet != nil)
                            .opacity((isProcessingSelection || activeSheet != nil) ? 0.5 : 1.0)
                    }
                }
                .background(configuration.surfaceColor ?? Color(.secondarySystemBackground))
                .cornerRadius((configuration.cornerRadius ?? 12) * 1.5)
                .overlay(
                    RoundedRectangle(cornerRadius: (configuration.cornerRadius ?? 12) * 1.5)
                        .stroke((configuration.primaryColor ?? Color.blue).opacity(0.2), lineWidth: 1)
                )
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showProcessingOverlay)
        .sheet(item: $activeSheet) { sheet in
            if sheet == .sourceSelector {
                sheetContent(for: sheet)
                    .presentationDetents([.height(300)])
                    .presentationDragIndicator(.hidden)
                    .presentationCornerRadius(24)
                    .presentationBackgroundInteraction(.enabled(upThrough: .height(300)))
            } else {
                sheetContent(for: sheet)
            }
        }
        .fullScreenCover(isPresented: $showPreCameraGuide) {
            if let builder = configuration.preCameraGuideBuilder {
                builder({
                    // Dismiss the guide and proceed to camera
                    showPreCameraGuide = false
                    // Ensure camera opens with the correct pre-loading behavior
                    DispatchQueue.main.async {
                        openVideoCamera()
                    }
                })
            } else {
                // Safety: if no builder, just ensure we proceed
                Color.clear.onAppear {
                    showPreCameraGuide = false
                    openVideoCamera()
                }
            }
        }
        .alert("Video Too Long", isPresented: $showVideoTooLongAlert) {
            Button("OK") { }
        } message: {
            Text("Please select a video under 2 minutes. Your video is \(Int(rejectedVideoDuration/60)):\(String(format: "%02d", Int(rejectedVideoDuration.truncatingRemainder(dividingBy: 60))))")
        }
        .fullScreenCover(isPresented: $showFullScreenTrimmer) {
            if let url = trimmerVideoURL {
                // Show a loading view first, then load the trimmer
                DelayedVideoTrimmerView(
                    sourceVideoURL: url,
                    configuration: configuration,
                    customTrimmer: configuration.customTrimmer,
                    onTrimComplete: handleTrimmedVideo
                )
                .accessibilityHidden(true) // Prevent AX from analyzing during transition
            }
        }
        .alert("Remove Media", isPresented: $showRemoveConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                removeMedia()
            }
        } message: {
            Text("Are you sure you want to remove this \(configuration.mediaType == .image ? "photo" : "video")?")
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onChange(of: activeSheet) { oldValue, newValue in
            handleSheetDismissal(newValue)
        }
        .onAppear {
            if let videoURL = selectedVideoURL, !isThumbnailGenerating && videoThumbnail == nil {
                generateVideoThumbnail(from: videoURL)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("VideoProcessingStarted"))) { _ in
            // Show loading overlay immediately when video processing starts in the picker
            // Check both library and camera sources
            if (activeSheet == .videoLibrary || activeSheet == .videoCamera) {
                DispatchQueue.main.async {
                    self.processingMessage = "Processing video..."
                    self.showProcessingOverlay = true
                    self.isProcessingSelection = true
                }
            }
        }
        .fullScreenCover(isPresented: $showVideoPlayer) {
            if let player = player, let url = selectedVideoURL {
                // Use a custom video player that handles orientation
                OrientationAwareVideoPlayer(url: url)
                    .ignoresSafeArea()
                    .overlay(alignment: .topTrailing) {
                        Button(action: {
                            player.pause()
                            showVideoPlayer = false
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .background(Circle().fill(Color.black.opacity(0.6)))
                                .padding()
                        }
                    }
            }
        }
    }
    
    
    // MARK: - Media Preview Section
    @ViewBuilder
    private var mediaPreviewSection: some View {
        Group {
            // Media preview
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            } else if let _ = selectedVideoURL {
                if thumbnailGenerationFailed {
                    // Error state
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                        .frame(height: 200)
                        .overlay(
                            VStack(spacing: 16) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 40))
                                    .foregroundColor(Color.red)
                                
                                Text("Invalid video")
                                    .font(.system(.body))
                                    .foregroundColor(Color.secondary)
                                
                                Text("Please re-upload")
                                    .font(.system(.body))
                                    .foregroundColor(Color.secondary)
                            }
                        )
                } else if let thumbnail = videoThumbnail {
                    ZStack {
                        // Video thumbnail container
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemBackground))
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .overlay(
                                Image(uiImage: thumbnail)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 200)
                                    .clipped()
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        
                        // Play icon overlay (centered)
                        Button(action: {
                            showVideoPlayer = true
                            if let url = selectedVideoURL {
                                player = AVPlayer(url: url)
                            }
                        }) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                                .background(Circle().fill(Color.black.opacity(0.5)))
                        }
                        
                        // Bottom buttons row (Replace + Trim)
                        VStack {
                            Spacer()
                            HStack {
                                // Replace button (left)
                                Button(action: {
                                    removeMedia()
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "arrow.triangle.2.circlepath")
                                            .font(.system(size: 14))
                                        Text("Replace")
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(Color.black.opacity(0.6))
                                    )
                                }

                                Spacer()

                                // Trim button (right) - only show when trimmer is available
                                Button(action: {
                                    if let url = selectedVideoURL {
                                        trimmerVideoURL = url
                                        showFullScreenTrimmer = true
                                    }
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "scissors")
                                            .font(.system(size: 14))
                                        Text("Trim")
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(Color.black.opacity(0.6))
                                    )
                                }
                            }
                            .padding(16)
                        }
                    }
                    .accessibilityLabel("Video preview. Tap to play.")
                } else {
                    // Loading placeholder while thumbnail generates
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: configuration.primaryColor ?? Color.blue))
                        )
                }
            }
        }
    }
    
    // MARK: - Upload Button Section
    private var uploadButtonSection: some View {
        AppButton(
            title: configuration.buttonTitle,
            action: {
                handleUploadTap()
            },
            style: .primary,
            size: .large,
            icon: configuration.mediaType == .image ? "camera.fill" : "video.fill",
            fullWidth: true
        )
    }
    
    // MARK: - Sheet Content
    @ViewBuilder
    private func sheetContent(for sheet: ActiveSheet) -> some View {
        switch sheet {
        case .sourceSelector:
            MediaPickerSourceSelector(
                options: configuration.mediaType == .image ? .photoOnly : .videoOnly,
                onSelect: { source in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        handleSourceSelection(source)
                    }
                }
            )
            
        case .camera:
            PermissionAwareMediaPicker.camera { image in
                if let image = image {
                    selectedImage = image
                    onMediaSelected?(.image, image)
                }
            }
            
        case .photoLibrary:
            PermissionAwareMediaPicker.imageLibrary { image in
                if let image = image {
                    selectedImage = image
                    onMediaSelected?(.image, image)
                }
            }
            
        case .videoCamera:
            PermissionAwareMediaPicker.videoCamera { url in
                // Process URL completely off main thread to avoid AX blocking
                Task.detached(priority: .userInitiated) {
                                        
                    guard let url = url else {
                        // User cancelled - hide loading
                        await MainActor.run {
                            self.isExpectingVideoSelection = false
                            self.showProcessingOverlay = false
                            self.isProcessingSelection = false
                        }
                        return
                    }
                    
                    // We have the URL, no longer waiting for picker/camera callback
                    await MainActor.run {
                        self.isExpectingVideoSelection = false
                        self.processingMessage = "Checking video length..."
                    }
                    
                    if self.configuration.showTrimmerImmediately {
                        // Preflight duration before presenting the trimmer
                        let ok = await self.checkVideoDuration(url: url)
                        if ok {
                            print("✅ [MediaUploadView] Video duration check passed")
                            // Small delay to let camera fully dismiss and AX settle
                            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
                            await MainActor.run {
                                                                // Cancel timeout - video loaded successfully
                                self.processingTimeoutTask?.cancel()
                                self.processingTimeoutTask = nil
                                
                                // Hide loading overlay as trimmer will show its own
                                self.showProcessingOverlay = false
                                self.isProcessingSelection = false
                                self.trimmerVideoURL = url
                                self.showFullScreenTrimmer = true
                            }
                        } else {
                            // Too long or undetermined handled inside checkVideoDuration (alert + overlay)
                            await MainActor.run {
                                self.isProcessingSelection = false
                                self.trimmerVideoURL = nil
                                self.showFullScreenTrimmer = false
                            }
                        }
                    } else {
                        // Normal flow (no trimmer) - still check duration
                        let ok = await self.checkVideoDuration(url: url)
                        if ok {
                            await MainActor.run {
                                self.selectedVideoURL = url
                                self.generateVideoThumbnail(from: url)
                                self.onMediaSelected?(.video, url)
                            }
                        }
                        // If not ok, checkVideoDuration already showed alert
                    }
                }
            }

        case .videoLibrary:
            PermissionAwareMediaPicker.videoLibrary { url in
                // Process URL completely off main thread to avoid AX blocking
                Task.detached(priority: .userInitiated) {
                                        
                    guard let url = url else {
                        // User cancelled - hide loading
                        await MainActor.run {
                            self.isExpectingVideoSelection = false
                            self.showProcessingOverlay = false
                            self.isProcessingSelection = false
                        }
                        return
                    }
                    
                    // We have the URL, no longer waiting for picker callback
                    await MainActor.run {
                        self.isExpectingVideoSelection = false
                        self.processingMessage = "Checking video length..."
                    }
                    
                    if self.configuration.showTrimmerImmediately {
                        // Preflight duration before presenting the trimmer
                        let ok = await self.checkVideoDuration(url: url)
                        if ok {
                            print("✅ [MediaUploadView] Video duration check passed")
                            // Small delay to let picker fully dismiss and AX settle
                            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
                            await MainActor.run {
                                                                // Cancel timeout - video loaded successfully
                                self.processingTimeoutTask?.cancel()
                                self.processingTimeoutTask = nil
                                
                                // Hide loading overlay as trimmer will show its own
                                self.showProcessingOverlay = false
                                self.isProcessingSelection = false
                                self.trimmerVideoURL = url
                                self.showFullScreenTrimmer = true
                            }
                        } else {
                            // Too long or undetermined handled inside checkVideoDuration (alert + overlay)
                            await MainActor.run {
                                self.isProcessingSelection = false
                                self.trimmerVideoURL = nil
                                self.showFullScreenTrimmer = false
                            }
                        }
                    } else {
                        // Normal flow (no trimmer) - still check duration
                        let ok = await self.checkVideoDuration(url: url)
                        if ok {
                            await MainActor.run {
                                self.selectedVideoURL = url
                                self.generateVideoThumbnail(from: url)
                                self.onMediaSelected?(.video, url)
                            }
                        }
                        // If not ok, checkVideoDuration already showed alert
                    }
                }
            }
        }
    }

    // MARK: - Helper Methods
    private func handleTrimmedVideo(_ trimmedURL: URL?) {
                DispatchQueue.main.async {
            self.showFullScreenTrimmer = false
            self.trimmerVideoURL = nil
            self.isProcessingSelection = false
            self.showProcessingOverlay = false
            if let finalURL = trimmedURL {
                self.selectedVideoURL = finalURL
                self.generateVideoThumbnail(from: finalURL)
                self.onMediaSelected?(.video, finalURL)
            } else {
                            }
        }
    }
    
    private var hasMedia: Bool {
        selectedImage != nil || selectedVideoURL != nil
    }
    
    private func handleUploadTap() {
                
        // Prevent re-entrant calls while processing a selection or if sheet is already shown
        guard !isProcessingSelection && activeSheet == nil else {
            return
        }
        
        if configuration.showSourceSelector {
            activeSheet = .sourceSelector
        } else {
            // Direct to camera/library based on media type
            if configuration.mediaType == .image {
                activeSheet = .photoLibrary
            } else {
                activeSheet = .videoLibrary
            }
        }
    }
    
    private func handleSourceSelection(_ source: SelectedSource) {
        switch source {
        case .cameraPhoto:
            activeSheet = .camera
        case .libraryPhoto:
            activeSheet = .photoLibrary
        case .cameraVideo:
            // If a pre-camera guide is provided and tutorial not dismissed, show it first
            let shouldShowGuide: Bool = {
                // Respect one-time dismissal if available
                if let _ = configuration.preCameraGuideBuilder {
                    // Access optional extension flag if present; default to false if not defined
                    return !(UserDefaults.standard.value(forKey: "phoneSetupTutorialDismissed") as? Bool ?? false)
                }
                return false
            }()

            if shouldShowGuide {
                // Defer camera open until guide completes
                pendingOpenVideoCamera = true
                showPreCameraGuide = true
            } else {
                openVideoCamera()
            }
        case .libraryVideo:
            // Show loading immediately for video that will be trimmed
            if configuration.showTrimmerImmediately {
                showProcessingOverlay = true
                processingMessage = "Opening video library..."
                isProcessingSelection = true
                // We expect a URL callback after the picker dismisses
                isExpectingVideoSelection = true
                startProcessingTimeout(seconds: 30)
            }
            activeSheet = .videoLibrary
        }
    }

    private func openVideoCamera() {
        // Show loading immediately for video that will be trimmed
        if configuration.showTrimmerImmediately {
            showProcessingOverlay = true
            processingMessage = "Opening camera..."
            isProcessingSelection = true
            // We expect a URL callback after the camera dismisses
            isExpectingVideoSelection = true
            startProcessingTimeout(seconds: 30)
        }
        pendingOpenVideoCamera = false
        activeSheet = .videoCamera
    }
    
    private func handleSheetDismissal(_ newValue: ActiveSheet?) {
        
        // Cancel any pending timeout
        processingTimeoutTask?.cancel()
        processingTimeoutTask = nil

        // Track sheet transitions
        let wasVideoSheet = previousSheet == .videoCamera || previousSheet == .videoLibrary

        // Reset processing flags when sheet is fully dismissed
        if newValue == nil {
            
            // If a video picker/camera was just dismissed and we're expecting a selection,
            // give the callback a very short time to fire
            if isExpectingVideoSelection && wasVideoSheet {
                processingMessage = "Processing video..."
                showProcessingOverlay = true
                isProcessingSelection = true
                // Use a MUCH shorter timeout for cancellation detection (2 seconds)
                // This prevents the infinite loading when user cancels
                startProcessingTimeout(seconds: 2)
            } else {
                // If we don't have media after dismissal and nothing is pending,
                // reset all processing states immediately
                if selectedVideoURL == nil && selectedImage == nil {
                                        resetProcessingState()
                }
            }
        }

        // Update previousSheet for next transition
        previousSheet = newValue
    }
    
    private func resetProcessingState() {
                showProcessingOverlay = false
        isProcessingSelection = false
        isExpectingVideoSelection = false
        processingMessage = "Preparing video editor..."
        processingTimeoutTask?.cancel()
        processingTimeoutTask = nil
    }
    
    private func startProcessingTimeout(seconds: TimeInterval = 30) {
        // Cancel any existing timeout
        processingTimeoutTask?.cancel()

        // Start new timeout
        processingTimeoutTask = Task {
            do {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))

                // If we're still processing after timeout, reset state
                if !Task.isCancelled && showProcessingOverlay {
                    await MainActor.run {
                        print("⏱️ [MediaUploadView] Processing timeout reached after \(seconds)s")
                        resetProcessingState()
                        // Only show error if it was a long timeout (user was actually waiting)
                        if seconds > 5 {
                            errorMessage = "Video loading timed out. Please try again."
                            showErrorAlert = true
                        }
                    }
                }
            } catch {
                // Task was cancelled, which is expected
            }
        }
    }
    
    private func removeMedia() {
                selectedImage = nil
        selectedVideoURL = nil
        videoThumbnail = nil
        videoAspectRatio = nil
        thumbnailGenerationFailed = false
    }
    
    // Check video duration (2-minute max)
    private func checkVideoDuration(url: URL) async -> Bool {
        // Run entirely on background to avoid any main thread blocking
        return await Task.detached(priority: .userInitiated) {
            // Create asset with performance options
            let asset = AVURLAsset(url: url, options: [
                AVURLAssetPreferPreciseDurationAndTimingKey: false,
                AVURLAssetAllowsCellularAccessKey: false
            ])
            
            do {
                // Load duration on background thread
                let duration = try await asset.load(.duration)
                let seconds = duration.seconds
                
                if seconds > 120 { // 2 minutes max
                    print("🚫 [MediaUploadView] Video too long: \(seconds)s (max 120s)")
                    await MainActor.run {
                        self.rejectedVideoDuration = seconds
                        self.showVideoTooLongAlert = true
                        self.showProcessingOverlay = false
                    }
                    return false
                }
                print("✅ [MediaUploadView] Video duration OK: \(seconds)s")
                return true
            } catch {
                print("⚠️ [MediaUploadView] Could not determine video duration: \(error)")
                // Allow the video if we can't determine duration
                return true
            }
        }.value
    }
    
    private func generateVideoThumbnail(from url: URL) {
        // Prevent duplicate generation
        guard !isThumbnailGenerating else {
            print("⚠️ [MediaUploadView] Thumbnail generation already in progress")
            return
        }
        
        // Reset state
        isThumbnailGenerating = true
        thumbnailGenerationFailed = false
        videoAspectRatio = nil
        videoThumbnail = nil
        
        // CRITICAL: Use Task.detached to avoid inheriting main actor context
        // This ensures ALL operations run on background thread
        Task.detached(priority: .userInitiated) {
            
            // Create asset with performance options
            let asset = AVURLAsset(url: url, options: [
                AVURLAssetPreferPreciseDurationAndTimingKey: false,
                AVURLAssetAllowsCellularAccessKey: false
            ])
            
            do {
                // Load duration on background thread
                let duration = try await asset.load(.duration)
                let midpointTime = CMTime(seconds: duration.seconds / 2, preferredTimescale: 600)
                
                // Create generator with optimized settings
                let generator = AVAssetImageGenerator(asset: asset)
                generator.appliesPreferredTrackTransform = true
                // REDUCED SIZE for much faster generation
                generator.maximumSize = CGSize(width: 640, height: 360)
                // Use tolerances for speed over precision
                generator.requestedTimeToleranceBefore = CMTime(seconds: 2, preferredTimescale: 600)
                generator.requestedTimeToleranceAfter = CMTime(seconds: 2, preferredTimescale: 600)
                
                // Generate single thumbnail asynchronously
                var thumbnailImage: UIImage?
                
                // Use async generation API to avoid blocking
                await withCheckedContinuation { continuation in
                    generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: midpointTime)]) { _, image, _, result, error in
                        if let image = image, result == .succeeded {
                            thumbnailImage = UIImage(cgImage: image)
                        }
                        continuation.resume()
                    }
                }
                
                // Update UI on main thread
                await MainActor.run {
                    if let thumbnail = thumbnailImage {
                        self.videoThumbnail = thumbnail
                        print("📹 [MediaUploadView] Thumbnail generated with size: \(thumbnail.size)")
                    } else {
                        self.thumbnailGenerationFailed = true
                        print("❌ [MediaUploadView] Thumbnail generation failed")
                    }
                    self.isThumbnailGenerating = false
                }
            } catch {
                print("Failed to generate video thumbnail: \(error)")
                await MainActor.run {
                    self.thumbnailGenerationFailed = true
                    self.isThumbnailGenerating = false
                }
            }
        }
    }
    
    private func calculateBottomSheetHeight() -> CGFloat {
        // Base: drag indicator + header + padding
        var height: CGFloat = 100
        
        // Each option is approximately 68 points tall
        let optionHeight: CGFloat = 68
        
        var optionCount = 0
        if configuration.mediaType == .image {
            optionCount = 2 // Take Photo + Choose from Library
        } else {
            optionCount = 2 // Record Video + Choose from Library
        }
        
        height += CGFloat(optionCount) * optionHeight
        
        // Add space for divider if we have both options
        if optionCount == 2 {
            height += 1
        }
        
        // Bottom padding
        height += 20
        
        return height
    }
}


// MARK: - Preview Provider
struct MediaUploadView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Photo upload example
            MediaUploadView(
                configuration: MediaUploadView.Configuration(
                    title: "Player Stance & Lie",
                    description: "This photo helps us analyze your stick's lie angle",
                    instructions: "Stand in your natural hockey stance with stick flat on the ground. Take a photo from the side.",
                    mediaType: .image,
                    buttonTitle: "Add Photo"
                ),
                selectedImage: .constant(nil)
            )
            
            // Video upload example
            MediaUploadView(
                configuration: MediaUploadView.Configuration(
                    title: "Shot Video",
                    description: "Record your shot for analysis",
                    instructions: "Record a short video (7-10 seconds) of your shot from the side angle.",
                    mediaType: .video,
                    buttonTitle: "Add Video"
                ),
                selectedVideoURL: .constant(nil)
            )
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
}

// MARK: - Orientation Aware Video Player
struct OrientationAwareVideoPlayer: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        let playerItem = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: playerItem)
        
        // Always mute the player
        player.isMuted = true
        player.volume = 0.0
        
        controller.player = player
        controller.videoGravity = .resizeAspect
        
        // Apply video composition to handle orientation
        Task {
            let asset = AVAsset(url: url)
            if let track = try? await asset.loadTracks(withMediaType: .video).first {
                let transform = try? await track.load(.preferredTransform)
                let naturalSize = try? await track.load(.naturalSize)
                let duration = try? await asset.load(.duration)
                
                if let transform = transform, let naturalSize = naturalSize, let duration = duration {
                    // Calculate rotation angle
                    let angle = atan2(transform.b, transform.a) * 180 / .pi
                    print("📹 [OrientationAwareVideoPlayer] Video rotation angle: \(angle) degrees, natural size: \(naturalSize)")
                    
                    // Only apply composition if video is rotated
                    if abs(angle) > 1 {
                        // Create composition to apply correct transform
                        let composition = AVMutableVideoComposition()
                        composition.frameDuration = CMTime(value: 1, timescale: 30)
                        
                        // Determine render size based on orientation
                        var renderSize = naturalSize
                        if abs(angle - 90) < 1 || abs(angle + 90) < 1 {
                            // Video is rotated 90 degrees, swap dimensions
                            renderSize = CGSize(width: naturalSize.height, height: naturalSize.width)
                        }
                        
                        composition.renderSize = renderSize
                        
                        // Create instruction to apply transform
                        let instruction = AVMutableVideoCompositionInstruction()
                        instruction.timeRange = CMTimeRange(start: .zero, duration: duration)
                        
                        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
                        layerInstruction.setTransform(transform, at: .zero)
                        
                        instruction.layerInstructions = [layerInstruction]
                        composition.instructions = [instruction]
                        
                        // Apply composition to player item
                        await MainActor.run {
                            playerItem.videoComposition = composition
                        }
                    }
                }
            }
            
            // Start playback
            await MainActor.run {
                player.play()
            }
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}

// MARK: - Convenience Extension for Video Trimmer
extension MediaUploadView {
    /// Convenience initializer for video uploads with built-in trimmer
    /// This simplifies the common case where VideoTrimmerView is used
    public init(
        configuration: Configuration,
        selectedVideoURL: Binding<URL?>,
        trimmerConfig: VideoTrimmerConfig,
        onVideoSelected: ((URL) -> Void)? = nil
    ) {
        // Create a new configuration with the trimmer embedded
        let configWithTrimmer = Configuration(
            title: configuration.title,
            description: configuration.description,
            instructions: configuration.instructions,
            mediaType: configuration.mediaType,
            buttonTitle: configuration.buttonTitle,
            showSourceSelector: configuration.showSourceSelector,
            showTrimmerImmediately: configuration.showTrimmerImmediately,
            customTrimmer: { url, completion in
                AnyView(
                    VideoTrimmerView(
                        sourceVideoURL: url,
                        configuration: trimmerConfig,
                        onTrimComplete: completion
                    )
                )
            },
            preCameraGuideBuilder: configuration.preCameraGuideBuilder,
            primaryColor: configuration.primaryColor,
            backgroundColor: configuration.backgroundColor,
            surfaceColor: configuration.surfaceColor,
            textColor: configuration.textColor,
            textSecondaryColor: configuration.textSecondaryColor,
            successColor: configuration.successColor,
            cornerRadius: configuration.cornerRadius
        )
        
        // Call the main initializer
        self.init(
            configuration: configWithTrimmer,
            selectedVideoURL: selectedVideoURL,
            onVideoSelected: onVideoSelected
        )
    }
    
    /// Even simpler convenience initializer using default trimmer configs
    public init(
        configuration: Configuration,
        selectedVideoURL: Binding<URL?>,
        featureType: AIFeatureType,
        onVideoSelected: ((URL) -> Void)? = nil
    ) {
        let trimmerConfig: VideoTrimmerConfig
        switch featureType {
        case .shotRater:
            trimmerConfig = .shotRater()
        case .aiCoach:
            trimmerConfig = .aiCoach()
        case .stickAnalyzer:
            trimmerConfig = .stickAnalyzer()
        case .skillCheck:
            trimmerConfig = .skillCheck()
        }
        
        self.init(
            configuration: configuration,
            selectedVideoURL: selectedVideoURL,
            trimmerConfig: trimmerConfig,
            onVideoSelected: onVideoSelected
        )
    }
}

// MARK: - AI Feature Type
public enum AIFeatureType {
    case shotRater
    case aiCoach
    case stickAnalyzer
    case skillCheck
}

// MARK: - Delayed Video Trimmer View
// This wrapper shows a loading state immediately and delays VideoTrimmerView creation
private struct DelayedVideoTrimmerView: View {
    let sourceVideoURL: URL
    let configuration: MediaUploadView.Configuration
    let customTrimmer: ((URL, @escaping (URL?) -> Void) -> AnyView)?
    let onTrimComplete: (URL?) -> Void
    
    @State private var showActualTrimmer = false
    @State private var loadingProgress: Double = 0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if !showActualTrimmer {
                // Show loading immediately with progress animation
                VStack(spacing: 24) {
                    ZStack {
                        // Animated ring
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 4)
                            .frame(width: 60, height: 60)
                        
                        Circle()
                            .trim(from: 0, to: loadingProgress)
                            .stroke(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 4, lineCap: .round)
                            )
                            .frame(width: 60, height: 60)
                            .rotationEffect(Angle(degrees: -90))
                            .animation(.easeInOut(duration: 0.5), value: loadingProgress)
                    }
                    
                    VStack(spacing: 8) {
                        Text("Loading video editor")
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Text("Please wait...")
                            .font(.system(.caption))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .onAppear {
                    // Animate progress
                    withAnimation(.easeInOut(duration: 0.3)) {
                        loadingProgress = 0.3
                    }
                    
                    // Use RunLoop to defer trimmer creation to next cycle
                    RunLoop.main.perform {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            loadingProgress = 0.7
                        }
                        
                        // Create trimmer after a very short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            withAnimation(.easeInOut(duration: 0.1)) {
                                loadingProgress = 1.0
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                showActualTrimmer = true
                            }
                        }
                    }
                }
            } else {
                // Now create the actual trimmer
                if let customTrimmer = customTrimmer {
                    customTrimmer(sourceVideoURL) { trimmedURL in
                        onTrimComplete(trimmedURL)
                    }
                } else {
                    VideoTrimmerView(
                        sourceVideoURL: sourceVideoURL,
                        configuration: VideoTrimmerConfig(),
                        onTrimComplete: { trimmedURL in
                            onTrimComplete(trimmedURL)
                        }
                    )
                }
            }
        }
    }
}
