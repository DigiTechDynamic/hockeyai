import SwiftUI
import AVKit
#if canImport(SharedServices)
import SharedServices
#endif

// MARK: - Video Trim Error
enum VideoTrimError: LocalizedError {
    case exportFailed
    
    var errorDescription: String? {
        switch self {
        case .exportFailed:
            return "Failed to export trimmed video"
        }
    }
}

// MARK: - Video Trimmer Configuration
public struct VideoTrimmerConfig {
    let title: String
    let subtitle: String
    let minDuration: Double
    let maxDuration: Double
    let buttonTitle: String
    let validationMessage: String?
    
    // Theme colors (optional for decoupling)
    public let primaryColor: Color?
    public let backgroundColor: Color?
    public let surfaceColor: Color?
    public let textColor: Color?
    public let textSecondaryColor: Color?
    public let errorColor: Color?
    public let cornerRadius: CGFloat?
    
    // Computed property for invalid message
    var invalidMessage: String {
        // Don't mention the minimum, just show appropriate error
        return "Clip too short - select more video"
    }
    
    // Get appropriate error message based on duration
    func getErrorMessage(for duration: Double) -> String {
        if duration < minDuration {
            return "Clip too short - select more video"
        } else if duration > maxDuration {
            return "Maximum 3 seconds"
        }
        return ""
    }
    
    // Default initializer with sensible defaults
    public init(
        title: String = "Trim Video",
        subtitle: String? = nil,
        minDuration: Double = 1.0,
        maxDuration: Double = 15.0,
        buttonTitle: String = "Use This Clip",
        validationMessage: String? = nil,
        primaryColor: Color? = nil,
        backgroundColor: Color? = nil,
        surfaceColor: Color? = nil,
        textColor: Color? = nil,
        textSecondaryColor: Color? = nil,
        errorColor: Color? = nil,
        cornerRadius: CGFloat? = nil
    ) {
        self.title = title
        self.subtitle = subtitle ?? "Select a clip (3 seconds or less)"
        self.minDuration = minDuration
        self.maxDuration = maxDuration
        self.buttonTitle = buttonTitle
        self.validationMessage = validationMessage ?? "Perfect duration!"
        self.primaryColor = primaryColor
        self.backgroundColor = backgroundColor
        self.surfaceColor = surfaceColor
        self.textColor = textColor
        self.textSecondaryColor = textSecondaryColor
        self.errorColor = errorColor
        self.cornerRadius = cornerRadius
    }
}

// MARK: - Video Trimmer View (Version 3)
public struct VideoTrimmerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) var theme
    
    let sourceVideoURL: URL
    let configuration: VideoTrimmerConfig
    var onTrimComplete: (URL?) -> Void
    
    // Player State
    @State private var player: AVPlayer
    @State private var isPlaying = false
    @State private var isTrimming = false
    @State private var videoDuration: Double = 0
    @State private var currentTime: Double = 0
    @State private var timeObserver: Any?
    
    // Trimming State
    @State private var trimStartTime: Double = 0
    @State private var trimEndTime: Double = 0
    
    // Loading State
    @State private var isLoadingVideo = true
    @State private var loadingProgress: Double = 0
    @State private var thumbnailFrames: [UIImage] = []
    @State private var videoTooLongError = false
    @State private var showFullScreenPlayer = false
    @State private var isThumbnailGenerating = true
    
    // Gesture State
    @State private var activeDrag: DragType = .none
    @State private var gestureStartState: (start: Double, end: Double)?
    // Magnifier/popup removed for cleaner interface
    @State private var constraintViolation: ConstraintViolationType = .none
    @State private var seekDebounceTimer: Timer?
    @State private var pendingSeekTime: Double?
    
    // Auto-Zoom State for timeline
    @State private var isZoomed = false
    @State private var zoomScale: Double = 1.0 // 1.0 = no zoom, 2.0 = 2x zoom, etc.
    @State private var zoomCenter: Double = 0.5 // 0.0 = start, 1.0 = end of video
    @State private var isDraggingHandle = false // Track if currently dragging a handle
    // Auto-zoom is always enabled (removed toggle)
    @State private var lastSelectionDuration: Double = 0 // Track selection changes
    
    private enum DragType { case none, start, end, scrubber }
    private enum ConstraintViolationType { case none, minDuration, maxDuration, minPixelWidth }
    
    // MARK: - Constants
    enum Constants {
        static let timelineHeight: CGFloat = 60  // Clean timeline height
        static let handleWidth: CGFloat = 16     // Handle width
        static let handleCornerRadius: CGFloat = 6 // Corner radius
        static let timelineCornerRadius: CGFloat = 8 // Timeline corners
        static let edgeHeight: CGFloat = 3       // Edge height
        static let minimumTrimPixelWidth: CGFloat = 44 // Min touch target (Apple HIG)
        static let thumbnailCount: Int = 15 // Fixed thumbnail count for all videos
        static let zoomAnimationDuration: Double = 0.25 // Quick zoom animation
        
        // AI-optimized export settings
        static let exportQualityPreset = AVAssetExportPresetHighestQuality
        static let exportMaxDuration: Double = 120.0 // 2 minutes max for optimal AI processing
        static let thumbnailMaxSize = CGSize(width: 120, height: 80) // Memory-efficient thumbnail size
        
        // Target file sizes for AI processing (Gemini has ~20MB limit per request)
        static let targetFileSizeMB: Double = 15.0 // Conservative target to ensure success
        static let geminiMaxFileSizeMB: Double = 20.0 // Gemini's actual limit
    }
    
    public init(sourceVideoURL: URL, configuration: VideoTrimmerConfig, onTrimComplete: @escaping (URL?) -> Void) {
        self.sourceVideoURL = sourceVideoURL
        self.configuration = configuration
        self.onTrimComplete = onTrimComplete
        // Create an empty player initially to avoid blocking
        let player = AVPlayer()
        player.isMuted = true
        player.volume = 0.0
        self._player = State(initialValue: player)
    }
    
    // MARK: - Body
    public var body: some View {
        NavigationView {
            ZStack {
                // Black background
                Color.black.ignoresSafeArea()
                    .accessibilityHidden(true) // Reduce accessibility system load
                
                if isLoadingVideo || isThumbnailGenerating {
                    // Show immediate loading state while video processes
                    VStack(spacing: 20) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color.blue))
                            .scaleEffect(1.2)
                        
                        Text(isThumbnailGenerating ? "Generating thumbnails..." : "Setting up video editor...")
                            .font(.system(.body))
                            .foregroundColor(.white.opacity(0.8))
                        
                        if isThumbnailGenerating && loadingProgress > 0 {
                            Text("\(Int(loadingProgress * 100))%")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                    .accessibilityHidden(true) // Prevent AX from analyzing loading state
                } else {
                    // Main trimmer content
                    mainTrimmerContent
                }
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
        .onAppear { setupPlayer() }
        .onDisappear { cleanupPlayer() }
    }
    
    // MARK: - Main Trimmer Content
    @ViewBuilder
    private var mainTrimmerContent: some View {
        VStack(spacing: 0) {
            // Header with background that extends into safe area
            headerWithBackground
            
            // Content below header
            ScrollView {
                VStack(spacing: 0) {
                    // Subtitle
                    Text(configuration.subtitle)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(Color.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                    
                    // 2. Video Player (placeholder removed since we show immediate loading)
                    videoPreview
                        .padding(.bottom, 12)
                    
                    // 3. Trimmer UI & Controls
                    trimmerInterface
                        .padding(.bottom, 100) // Space for footer
                }
            }
            .scrollIndicators(.hidden)
        }
        
        // Fixed footer at bottom
        VStack {
            Spacer()
            footer
        }
    }

    // MARK: - View Components
    private var loadingPlaceholderView: some View {
        VStack(spacing: 24) {
            // Video preview placeholder
            RoundedRectangle(cornerRadius: configuration.cornerRadius ?? 16)
                .fill(Color.gray.opacity(0.2))
                .aspectRatio(16/9, contentMode: .fit)
                .overlay(
                    VStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: theme.primary))
                            .scaleEffect(1.5)
                        
                        Text("Loading Video...")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        
                        if loadingProgress > 0 {
                            Text("\(Int(loadingProgress * 100))%")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                )
                .padding(.horizontal, 16)
            
            // Timeline placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.1))
                .frame(height: Constants.timelineHeight)
                .padding(.horizontal, 16)
                .overlay(
                    Text("Preparing timeline...")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.3))
                )
        }
    }
    
    private var headerWithBackground: some View {
        VStack(spacing: 0) {
            // Header content with background extending into safe area
            header
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 10)
                .frame(maxWidth: .infinity)
                .background(
                    ZStack {
                        // Glass morphism background
                        Rectangle()
                            .fill(.ultraThinMaterial)
                        
                        // Gradient overlay
                        LinearGradient(
                            colors: [
                                theme.surface.opacity(0.9),
                                theme.background.opacity(0.7)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                    .ignoresSafeArea(edges: .top)
                )
            
            // Subtle separator line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            theme.primary.opacity(0),
                            theme.primary.opacity(0.3),
                            theme.primary.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
        }
    }
    
    private var header: some View {
        HStack {
            // Left side - Title with icon matching Profile header
            HStack(spacing: 12) {
                // Icon with glass effect
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    theme.primary.opacity(0.15),
                                    theme.primary.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 42, height: 42)
                        .overlay(
                            Circle()
                                .stroke(theme.primary.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: theme.primary.opacity(0.2), radius: 8, x: 0, y: 2)
                    
                    Image(systemName: "scissors")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(theme.primary)
                }
                
                // Title text
                Text("Trim Video")
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.white,
                                Color.white.opacity(0.9)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color.white.opacity(0.3), radius: 0, x: 0, y: 0)
                    .shadow(color: Color.white.opacity(0.2), radius: 4, x: 0, y: 0)
                    .shadow(color: theme.primary.opacity(0.3), radius: 8, x: 0, y: 2)
            }
            
            Spacer()
            
            // Close button
            Button(action: {
                onTrimComplete(nil)
                dismiss()
            }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    theme.primary.opacity(0.15),
                                    theme.primary.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 42, height: 42)
                        .overlay(
                            Circle()
                                .stroke(theme.primary.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: theme.primary.opacity(0.2), radius: 8, x: 0, y: 2)
                    
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(theme.primary)
                }
            }
        }
    }
    
    private var videoPreview: some View {
        GeometryReader { geometry in
            ZStack {
                // Background with gradient
                LinearGradient(
                    colors: [Color.black, Color.black.opacity(0.9)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Video player
                VideoPlayer(player: player)
                    .disabled(true) // Disable default controls
                    .onAppear {
                        // Ensure player is ready
                        player.seek(to: CMTime(seconds: trimStartTime, preferredTimescale: 600))
                        // Always mute the player
                        player.isMuted = true
                        player.volume = 0.0
                    }
            }
        }
        .aspectRatio(16/9, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: configuration.cornerRadius ?? 16))
        .overlay(
            RoundedRectangle(cornerRadius: configuration.cornerRadius ?? 16)
                .stroke(
                    LinearGradient(
                        colors: [
                            theme.primary.opacity(0.3),
                            theme.primary.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
        .overlay(playPauseOverlay)
        .padding(.horizontal, 16)
    }
    
    private var trimmerInterface: some View {
        VStack(spacing: 24) {
            // Modern timeline card with better organization
            VStack(spacing: 0) {
                // Duration header section  
                VStack(spacing: 15) {
                    // Status message at top (moved from header)
                    if !isDurationValid {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 14, weight: .semibold))
                            Text(clipDuration < configuration.minDuration ? 
                                "Select at least \(String(format: "%.1fs", configuration.minDuration))" : 
                                "Trim to \(String(format: "%.1fs", configuration.maxDuration)) or less")
                                .font(.system(size: 14, weight: .medium))
                                .fixedSize()
                        }
                        .foregroundColor(Color.red)
                        .padding(.top, -10)
                    }
                    
                    HStack {
                        durationStatusHeader
                        
                        Spacer()
                        
                        // Zoom info only (removed auto/manual toggle)
                        HStack(spacing: 8) {
                            Spacer() // Push zoom indicator to the right
                            
                            // Zoom indicator - styled like duration badge
                            if isZoomed && zoomScale > 1.1 {
                                ZStack {
                                    Capsule()
                                        .fill(Color.gray.opacity(0.2))
                                        .overlay(
                                            Capsule()
                                                .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                                        )
                                        .frame(width: 70, height: 32) // Fixed size like duration
                                    
                                    Text(String(format: "%.1fx", zoomScale))
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundColor(.white.opacity(0.8))
                                        .lineLimit(1)
                                }
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                    
                    // Timeline section with proper spacing
                    VStack(spacing: 16) {
                        // Timeline container with adequate height
                        VStack(spacing: 0) {
                            // Extra space for playhead knob
                            Spacer()
                                .frame(height: 20)
                            
                            // Timeline view - clean without problematic overlay
                            timelineWithGestures
                                // Remove the misaligned stroke overlay that was causing the white box
                            
                            // Small gap after timeline
                            Spacer()
                                .frame(height: 8)
                        }
                        .frame(height: Constants.timelineHeight + 40) // Fixed height container
                        
                        // Time markers with proper spacing
                        HStack {
                            Text(formatTimeShort(trimStartTime))
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.6))
                            
                            Spacer()
                            
                            Text(formatTimeShort(trimEndTime))
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.06),
                                    Color.white.opacity(0.02)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            theme.primary.opacity(0.2),
                                            theme.primary.opacity(0.05)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                )
            }
            
            // Playback controls
            playbackControls
        }
        .padding(.horizontal, 20)
    }
    
    private func formatTimeShort(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
    
    // Removed old toggleZoom implementation
    
    private func shouldEnableAutoZoom() -> Bool {
        // Enable auto-zoom for videos longer than 10 seconds
        return videoDuration > 10
    }
    
    private func calculateAutoZoomScale(for selectionDuration: Double) -> Double {
        guard videoDuration > 0 && selectionDuration > 0 else { return 1.0 }
        
        let selectionRatio = selectionDuration / videoDuration
        
        // Auto-zoom thresholds based on your specification
        if selectionRatio < 0.10 { // Less than 10% of video
            // Show 5x selection width for very small selections
            let targetDuration = selectionDuration * 5
            return min(videoDuration / targetDuration, 8.0) // Max 8x zoom
        } else if selectionRatio < 0.20 { // Less than 20% of video
            // Show 3x selection width for small selections  
            let targetDuration = selectionDuration * 3
            return min(videoDuration / targetDuration, 5.0) // Max 5x zoom
        } else {
            // No zoom for larger selections
            return 1.0
        }
    }
    
    private func calculateOptimalZoomScale() -> Double {
        // Fallback for manual zoom - show ~10 seconds
        guard videoDuration > 0 else { return 1.0 }
        let targetDuration: Double = 10.0
        let scale = videoDuration / targetDuration
        return min(max(scale, 1.0), 10.0)
    }
    
    // Removed toggleAutoZoom - auto-zoom is always enabled
    
    private func updateAutoZoom() {
        guard shouldEnableAutoZoom() else { return } // Auto-zoom is always enabled
        
        let selectionDuration = trimEndTime - trimStartTime
        let newZoomScale = calculateAutoZoomScale(for: selectionDuration)
        
        // Only update if zoom scale changed significantly
        if abs(newZoomScale - zoomScale) > 0.2 {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                zoomScale = newZoomScale
                isZoomed = newZoomScale > 1.1
                
                // Center zoom on current selection
                let selectionCenter = (trimStartTime + trimEndTime) / 2
                zoomCenter = selectionCenter / videoDuration
                zoomCenter = max(0.1, min(0.9, zoomCenter)) // Keep away from edges
            }
        }
    }
    
    private func updateZoomCenterOnly() {
        guard videoDuration > 0 && isZoomed else { return }
        
        // Only update zoom center to keep selection visible, don't change zoom scale
        let selectionCenter = (trimStartTime + trimEndTime) / 2
        let newCenter = selectionCenter / videoDuration
        
        // Smoothly update zoom center if it moved significantly
        if abs(newCenter - zoomCenter) > 0.05 {
            withAnimation(.easeInOut(duration: 0.2)) {
                zoomCenter = max(0.1, min(0.9, newCenter))
            }
        }
    }
    
    private func formatTimeCompact(_ seconds: Double) -> String {
        if seconds < 60 {
            return String(format: "%.1fs", seconds)
        } else {
            let mins = Int(seconds) / 60
            let secs = Int(seconds) % 60
            return String(format: "%d:%02d", mins, secs)
        }
    }
    
    private var durationStatusHeader: some View {
        HStack(spacing: 12) {
            // Duration badge - dynamic text size to always fit
            ZStack {
                // Fixed size capsule container
                Capsule()
                    .fill(isDurationValid ? theme.primary.opacity(0.12) : Color.red.opacity(0.12))
                    .overlay(
                        Capsule()
                            .strokeBorder(
                                isDurationValid ? theme.primary.opacity(0.3) : Color.red.opacity(0.3),
                                lineWidth: 1
                            )
                    )
                    .frame(width: 90, height: 32) // Fixed size
                
                HStack(spacing: 4) {
                    Image(systemName: "timer")
                        .font(.system(size: 13, weight: .semibold))
                    // Dynamic font size based on duration length
                    Text(String(format: "%.1fs", clipDuration))
                        .font(.system(size: clipDuration >= 100 ? 13 : (clipDuration >= 10 ? 14 : 15), weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.7) // Allow shrinking if needed
                        .lineLimit(1)
                }
                .foregroundColor(isDurationValid ? theme.primary : Color.red)
            }
            
            Spacer()
        }
    }

    private var footer: some View {
        VStack(spacing: 0) {
            // Separator line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0),
                            Color.white.opacity(0.1),
                            Color.white.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 0.5)
            
            Button(action: performTrim) {
                ZStack {
                    // Glassmorphic background like error view
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    theme.surface.opacity(0.8),
                                    theme.surface.opacity(0.6)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    LinearGradient(
                                        colors: isDurationValid && !isTrimming ? [
                                            theme.success.opacity(0.6),
                                            theme.success.opacity(0.3)
                                        ] : [
                                            theme.primary.opacity(0.3),
                                            theme.primary.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: isDurationValid && !isTrimming ? 2 : 1
                                )
                        )
                    
                    HStack(spacing: 10) {
                        if isTrimming {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: isDurationValid ? "checkmark.circle.fill" : "xmark.circle")
                                .font(.system(size: 20, weight: .medium))
                        }
                        
                        Text(isTrimming ? "Processing..." : (isDurationValid ? configuration.buttonTitle : "Invalid Duration"))
                            .font(.system(size: 16, weight: .semibold))
                            .tracking(0.5)
                    }
                    .foregroundColor(isTrimming || !isDurationValid ? theme.text.opacity(0.4) : theme.text)
                }
                .frame(height: 56)
                .scaleEffect(isTrimming ? 0.95 : 1.0)
                .animation(.spring(response: 0.3), value: isTrimming)
            }
            .disabled(isTrimming || !isDurationValid)
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 34)
        }
        .background(
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.95),
                        Color.black
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Subtle pattern overlay
                LinearGradient(
                    colors: [
                        theme.primary.opacity(0.03),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .center
                )
            }
            .ignoresSafeArea(edges: .bottom)
        )
    }
    
    @ViewBuilder private var playPauseOverlay: some View {
        if !isPlaying {
            ZStack {
                Color.black.opacity(0.3)
                Button(action: togglePlayPause) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 64, weight: .regular))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 10)
                }
            }
        }
    }
    
    
    private var playbackControls: some View {
        HStack(spacing: 20) {
            // Skip to start
            Button(action: { seekToTime(trimStartTime) }) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 44, height: 44)
                    Image(systemName: "backward.end.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            
            // Play/Pause with animation
            Button(action: togglePlayPause) {
                ZStack {
                    // Animated ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    theme.primary,
                                    theme.primary.opacity(0.5)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 64, height: 64)
                        .scaleEffect(isPlaying ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: isPlaying)
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    theme.primary,
                                    theme.primary.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.black)
                        .offset(x: isPlaying ? 0 : 2) // Slight offset for play icon
                }
            }
            .scaleEffect(isTrimming ? 0.9 : 1.0)
            .animation(.spring(response: 0.3), value: isTrimming)
            
            // Skip to end
            Button(action: { seekToTime(trimEndTime) }) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 44, height: 44)
                    Image(systemName: "forward.end.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                }
            }
        }
        .opacity(isTrimming ? 0.5 : 1.0)
    }

    // MARK: - Timeline & Gestures
    private var timelineWithGestures: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            
            // Calculate effective duration and offset based on zoom state
            let zoomDuration = videoDuration > 0 ? videoDuration / zoomScale : videoDuration
            let centerTime = videoDuration * zoomCenter
            let effectiveDuration = isZoomed && videoDuration > 0 ? zoomDuration : videoDuration
            let effectiveOffset = isZoomed && videoDuration > 0 ? 
                max(0, min(videoDuration - zoomDuration, centerTime - zoomDuration / 2)) : 0
            
            // Calculate pixels per second based on effective duration
            let pixelsPerSecond = effectiveDuration > 0 ? totalWidth / effectiveDuration : 0
            // Calculate zoom level for thumbnail scaling
            let zoomLevel = effectiveDuration > 0 && videoDuration > 0 ? videoDuration / effectiveDuration : 1.0
            
            // Adjust handle and scrubber positions for zoom
            // Calculate handle positions with proper bounds checking to prevent negative values
            let adjustedTrimStart = max(0, min(effectiveDuration, trimStartTime - effectiveOffset))
            let adjustedTrimEnd = max(0, min(effectiveDuration, trimEndTime - effectiveOffset))
            let adjustedCurrentTime = max(0, min(effectiveDuration, currentTime - effectiveOffset))
            
            // Calculate positions ensuring they are never negative
            let rawStartX = max(0, adjustedTrimStart * pixelsPerSecond)
            let rawEndX = max(0, adjustedTrimEnd * pixelsPerSecond)
            let rawScrubberX = max(0, adjustedCurrentTime * pixelsPerSecond)
            
            // Apply proper bounds with handle width consideration (16px total, centered at 8px)
            // Ensure positions are always within valid range and never negative
            let startHandleX = max(0, min(max(0, totalWidth - 16), rawStartX))
            let endHandleX = max(0, min(max(0, totalWidth - 16), rawEndX)) 
            let scrubberX = max(0, min(max(0, totalWidth - 2), rawScrubberX)) // 2px for line width
            
            ZStack(alignment: .leading) {
                // Base timeline layer - LOWEST z-index
                timelineBaseView
                    .frame(width: totalWidth, height: Constants.timelineHeight)
                    .zIndex(1) // Base layer
                
                // Background gesture area for timeline scrubbing (fallback only)
                Color.clear
                    .contentShape(Rectangle())
                    .frame(width: totalWidth, height: Constants.timelineHeight + 20)
                    .zIndex(0) // Lowest z-index
                    .accessibilityHidden(true) // Hide from accessibility system
                    // Removed duplicate gesture - scrubber has its own
                
                // Left trim handle with individual drag gesture
                VerticalTrimHandle(isLeft: true, isActive: activeDrag == .start)
                    .offset(x: max(0, startHandleX), y: 0) // Ensure never negative
                    .zIndex(100)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                if activeDrag == .none {
                                    activeDrag = .start
                                    gestureStartState = (trimStartTime, trimEndTime)
                                    #if canImport(SharedServices)
                                    HapticManager.shared.playImpact(style: .medium)
                                    #else
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    #endif
                                }
                                
                                if activeDrag == .start, let startState = gestureStartState, pixelsPerSecond > 0 {
                                    let deltaTime = value.translation.width / pixelsPerSecond
                                    let newStartTime = startState.start + deltaTime
                                    let clampedStart = max(0, min(newStartTime, videoDuration))
                                    let finalStart = min(clampedStart, trimEndTime - configuration.minDuration)
                                    
                                    // Update without animation to prevent conflicts
                                    trimStartTime = max(0, finalStart)
                                }
                            }
                            .onEnded { _ in
                                activeDrag = .none
                                gestureStartState = nil
                                
                                // Apply auto-zoom when user lifts finger (after handle scale animation completes)
                                // Auto-zoom is always enabled
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    updateAutoZoom()
                                }
                                
                                #if canImport(SharedServices)
                                HapticManager.shared.playImpact(style: .light)
                                #else
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                #endif
                            }
                    )
                
                // Right trim handle with individual drag gesture  
                VerticalTrimHandle(isLeft: false, isActive: activeDrag == .end)
                    .offset(x: max(0, endHandleX), y: 0) // Ensure never negative
                    .zIndex(100)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                if activeDrag == .none {
                                    activeDrag = .end
                                    gestureStartState = (trimStartTime, trimEndTime)
                                    #if canImport(SharedServices)
                                    HapticManager.shared.playImpact(style: .medium)
                                    #else
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    #endif
                                }
                                
                                if activeDrag == .end, let startState = gestureStartState, pixelsPerSecond > 0 {
                                    let deltaTime = value.translation.width / pixelsPerSecond
                                    let newEndTime = startState.end + deltaTime
                                    let clampedEnd = max(0, min(newEndTime, videoDuration))
                                    let finalEnd = max(clampedEnd, trimStartTime + configuration.minDuration)
                                    
                                    // Update without animation to prevent conflicts
                                    trimEndTime = min(videoDuration, finalEnd)
                                }
                            }
                            .onEnded { _ in
                                activeDrag = .none
                                gestureStartState = nil
                                
                                // Apply auto-zoom when user lifts finger (after handle scale animation completes)
                                // Auto-zoom is always enabled
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    updateAutoZoom()
                                }
                                
                                #if canImport(SharedServices)
                                HapticManager.shared.playImpact(style: .light)
                                #else
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                #endif
                            }
                    )
                
                // Time labels removed for cleaner interface
                
                // Always visible draggable playhead
                ZStack {
                    // Main playhead line extending through timeline
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 2, height: Constants.timelineHeight + 16)
                        .shadow(color: .black.opacity(0.4), radius: 1)
                    
                    // Top draggable knob - always visible
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.white, Color.white.opacity(0.9)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 16, height: 16) // Larger for better touch target
                        .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                        .overlay(
                            Circle()
                                .stroke(theme.primary.opacity(0.6), lineWidth: activeDrag == .scrubber ? 2 : 0)
                        )
                        .offset(y: -(Constants.timelineHeight/2 + 20))
                        .scaleEffect(activeDrag == .scrubber ? 1.2 : 1.0)
                        .animation(.spring(response: 0.15, dampingFraction: 0.8), value: activeDrag)
                }
                .offset(x: max(0, scrubberX - 1), y: -16)
                .animation(.linear(duration: 0.05), value: max(0, currentTime)) // Animate only positive values
                .zIndex(98) // Below handles but above timeline
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if activeDrag == .none {
                                activeDrag = .scrubber
                                // Store initial time for smooth dragging
                                gestureStartState = (currentTime, 0)
                                player.currentItem?.preferredForwardBufferDuration = 0
                                #if canImport(SharedServices)
                                HapticManager.shared.playImpact(style: .medium)
                                #else
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                #endif
                            }
                            
                            if activeDrag == .scrubber && pixelsPerSecond > 0, let startState = gestureStartState {
                                // Calculate time delta based on drag translation
                                let deltaTime = value.translation.width / pixelsPerSecond
                                let newTime = startState.start + deltaTime
                                // Clamp to video bounds
                                let clampedTime = max(0, min(videoDuration, newTime))
                                currentTime = clampedTime
                                seekToTime(clampedTime)
                            }
                        }
                        .onEnded { _ in
                            activeDrag = .none
                            gestureStartState = nil
                            player.currentItem?.preferredForwardBufferDuration = 2.0
                            #if canImport(SharedServices)
                            HapticManager.shared.playImpact(style: .light)
                            #else
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            #endif
                        }
                )
                
                // Magnified preview removed
            }
        }
.frame(height: Constants.timelineHeight) // Clean timeline without extra padding
    }
    
    // Removed unused scrubberArea - functionality now integrated into timelineWithGestures
    
    private var timelineBaseView: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            
            // Use zoom-aware calculations
            let zoomDuration = videoDuration > 0 ? videoDuration / zoomScale : videoDuration
            let centerTime = videoDuration * zoomCenter
            let effectiveDuration = isZoomed && videoDuration > 0 ? zoomDuration : videoDuration
            let effectiveOffset = isZoomed && videoDuration > 0 ? 
                max(0, min(videoDuration - zoomDuration, centerTime - zoomDuration / 2)) : 0
            let pixelsPerSecond = effectiveDuration > 0 ? totalWidth / effectiveDuration : 0
            // Calculate zoom level for thumbnail scaling
            let zoomLevel = effectiveDuration > 0 && videoDuration > 0 ? videoDuration / effectiveDuration : 1.0
            
            // Adjust positions for zoom with proper bounds checking
            let adjustedTrimStart = max(0, trimStartTime - effectiveOffset)
            let adjustedTrimEnd = max(0, trimEndTime - effectiveOffset)
            
            let startHandlePosition = max(0, adjustedTrimStart * pixelsPerSecond)
            let endHandlePosition = max(0, adjustedTrimEnd * pixelsPerSecond)
            
            ZStack(alignment: .leading) {
                // Background timeline with thumbnails
                if thumbnailFrames.isEmpty {
                    RoundedRectangle(cornerRadius: Constants.timelineCornerRadius)
                        .fill(Color.black.opacity(0.8))
                        .overlay(
                            ZStack {
                                // Subtle animated gradient background
                                LinearGradient(
                                    colors: [
                                        Color.black.opacity(0.6),
                                        theme.primary.opacity(0.1),
                                        Color.black.opacity(0.6)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .opacity(0.5)
                                
                                // Progress bar at bottom
                                VStack {
                                    Spacer()
                                    GeometryReader { geometry in
                                        Rectangle()
                                            .fill(theme.primary.opacity(0.15))
                                            .frame(width: geometry.size.width, height: 2)
                                            .overlay(
                                                Rectangle()
                                                    .fill(theme.primary)
                                                    .frame(width: geometry.size.width * loadingProgress, height: 2)
                                                    .animation(.easeInOut(duration: 0.3), value: loadingProgress)
                                            )
                                    }
                                    .frame(height: 2)
                                }
                                
                                // Loading indicator in center
                                VStack(spacing: 8) {
                                    // Custom loading animation
                                    HStack(spacing: 4) {
                                        ForEach(0..<3) { index in
                                            Circle()
                                                .fill(theme.primary)
                                                .frame(width: 4, height: 4)
                                                .scaleEffect(loadingProgress > Double(index) / 3 ? 1.2 : 0.6)
                                                .animation(
                                                    Animation.easeInOut(duration: 0.6)
                                                        .repeatForever(autoreverses: true)
                                                        .delay(Double(index) * 0.15),
                                                    value: loadingProgress
                                                )
                                        }
                                    }
                                    
                                    Text("Loading frames...")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.white.opacity(0.5))
                                    
                                    if loadingProgress > 0 {
                                        Text("\(Int(loadingProgress * 100))%")
                                            .font(.system(size: 9, weight: .regular))
                                            .foregroundColor(.white.opacity(0.3))
                                    }
                                }
                            }
                        )
                } else {
                    // iOS-style timeline with proper thumbnail display
                    ZStack {
                        // Black background for timeline
                        RoundedRectangle(cornerRadius: Constants.timelineCornerRadius)
                            .fill(Color.black)
                        
                        // Thumbnail track - shift and scale based on zoom
                        HStack(spacing: 0) {
                            ForEach(thumbnailFrames.indices, id: \.self) { index in
                                // Calculate frame width based on zoom
                                let frameWidth = (totalWidth * zoomLevel) / CGFloat(thumbnailFrames.count)
                                Image(uiImage: thumbnailFrames[index])
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: frameWidth)
                                    .frame(height: Constants.timelineHeight)
                                    .clipped()
                                    .accessibilityHidden(true) // Prevent AX issues with thumbnails
                            }
                        }
                        .frame(width: totalWidth * zoomLevel, height: Constants.timelineHeight)
                        .offset(x: -effectiveOffset * pixelsPerSecond, y: 0)
                        .clipped()
                    }
                    .frame(width: totalWidth, height: Constants.timelineHeight)
                    .clipped() // Clip the ZStack to prevent thumbnails from overflowing
                    // Remove clipShape to allow handles to extend beyond timeline bounds
                }
                
                // iOS-style dimming overlay (matches GitHub thumbnailLeadingCoverView/thumbnailTrailingCoverView)
                HStack(spacing: 0) {
                    // Left dimmed area (75% black opacity like GitHub)
                    if startHandlePosition > 0 {
                        Rectangle()
                            .fill(Color(white: 0, opacity: 0.75))
                            .frame(width: startHandlePosition, height: Constants.timelineHeight)
                    }
                    
                    // Selected area with yellow top/bottom borders
                    ZStack {
                        // Clear selected area
                        Color.clear
                            .frame(width: max(0, endHandlePosition - startHandlePosition), height: Constants.timelineHeight)
                        
                        // Clean top and bottom accent lines
                        VStack(spacing: 0) {
                            Rectangle()
                                .fill(theme.primary)
                                .frame(height: Constants.edgeHeight)
                                .clipShape(RoundedRectangle(cornerRadius: 1.5))
                            Spacer()
                            Rectangle()
                                .fill(theme.primary)
                                .frame(height: Constants.edgeHeight)
                                .clipShape(RoundedRectangle(cornerRadius: 1.5))
                        }
                        .frame(width: max(0, endHandlePosition - startHandlePosition), height: Constants.timelineHeight)
                    }
                    
                    // Right dimmed area (75% black opacity like GitHub)
                    if endHandlePosition < totalWidth {
                        Rectangle()
                            .fill(Color(white: 0, opacity: 0.75))
                            .frame(width: totalWidth - endHandlePosition, height: Constants.timelineHeight)
                    }
                }
                .allowsHitTesting(false)
                .zIndex(1) // Lower z-index so handles appear above
            }
        }
    }
    
    // Removed oldTimelineArea - now using timelineBaseView

    // MARK: - Logic & Helpers
    private var clipDuration: Double { trimEndTime - trimStartTime }
    private var isDurationValid: Bool { clipDuration >= configuration.minDuration && clipDuration <= configuration.maxDuration }

    private func setupPlayer() {
        // Ensure player is muted
        player.isMuted = true
        player.volume = 0.0
        
        // Start loading immediately on background queue
        Task(priority: .userInitiated) {
            do {
                // Create the player item asynchronously
                let playerItem = AVPlayerItem(url: sourceVideoURL)
                
                // Replace the player's current item on main thread
                await MainActor.run {
                    self.player.replaceCurrentItem(with: playerItem)
                }
                
                let asset = playerItem.asset
                let duration = try await asset.load(.duration)
                
                // Check if video is too long (>2 minutes max for optimal performance)
                if duration.seconds > Constants.exportMaxDuration {
                    await MainActor.run {
                        self.videoTooLongError = true
                        self.isLoadingVideo = false
                    }
                    print("❌ Video too long: \(duration.seconds)s (max 2 minutes)")
                    return // Stop processing
                }
                
                // Update duration immediately to show UI
                await MainActor.run {
                    self.videoDuration = duration.seconds
                    self.trimEndTime = min(self.trimEndTime, duration.seconds)
                }
                
                // Apply video composition for proper orientation
                if let videoTrack = try await asset.loadTracks(withMediaType: .video).first {
                    let transform = try await videoTrack.load(.preferredTransform)
                    let naturalSize = try await videoTrack.load(.naturalSize)
                    
                    // Create video composition for orientation
                    let videoComp = AVMutableVideoComposition()
                    videoComp.frameDuration = CMTime(value: 1, timescale: 30)
                    
                    // Determine render size
                    let angle = atan2(transform.b, transform.a) * 180 / .pi
                    var renderSize = naturalSize
                    if abs(angle - 90) < 1 || abs(angle + 90) < 1 {
                        renderSize = CGSize(width: naturalSize.height, height: naturalSize.width)
                    }
                    videoComp.renderSize = renderSize
                    
                    // Create instruction
                    let instruction = AVMutableVideoCompositionInstruction()
                    instruction.timeRange = CMTimeRange(start: .zero, duration: duration)
                    
                    let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
                    layerInstruction.setTransform(transform, at: .zero)
                    
                    instruction.layerInstructions = [layerInstruction]
                    videoComp.instructions = [instruction]
                    
                    // Apply to player item
                    await MainActor.run {
                        self.player.currentItem?.videoComposition = videoComp
                    }
                }
                
                // Start with placeholder frames immediately to show UI faster
                await MainActor.run {
                    self.thumbnailFrames = self.createVideoFrames(count: Constants.thumbnailCount)
                    
                    // Keep loading state visible, but indicate we're generating thumbnails
                    self.isLoadingVideo = false
                    self.isThumbnailGenerating = true
                }
                
                // Generate real thumbnails in background without blocking UI
                // Using Task.detached ensures complete isolation from main actor
                Task.detached(priority: .userInitiated) {
                    // Generate thumbnails completely off main thread
                    let generatedFrames = await self.generateThumbnails(for: asset)
                    
                    // Replace placeholder frames with real ones progressively
                    await MainActor.run {
                        if !generatedFrames.isEmpty {
                            self.thumbnailFrames = generatedFrames
                            print("✅ Real thumbnails loaded and replaced placeholders")
                        }
                        
                        // Now hide the loading overlay
                        withAnimation(.easeOut(duration: 0.3)) {
                            self.isThumbnailGenerating = false
                        }
                    }
                }
                
                await MainActor.run {
                    self.videoDuration = duration.seconds
                    
                    // Set initial trim to show the full video (start to end)
                    // Always start with full video selected, regardless of length
                    self.trimStartTime = 0
                    self.trimEndTime = duration.seconds
                    
                    // If video is longer than max duration, the user will need to trim it
                    // But show them the full timeline initially so they can choose what to keep
                    
                    // Apply initial auto-zoom (always enabled)
                    updateAutoZoom()
                    
                    // Store initial selection duration
                    self.lastSelectionDuration = self.trimEndTime - self.trimStartTime
                    
                    self.timeObserver = player.addPeriodicTimeObserver(forInterval: .init(seconds: 0.05, preferredTimescale: 600), queue: .main) { time in
                        self.currentTime = time.seconds
                        if self.isPlaying && self.currentTime >= self.trimEndTime {
                            player.pause(); self.isPlaying = false; seekToTime(self.trimStartTime)
                        }
                    }
                    
                    // Loading complete is now handled earlier with placeholder thumbnails
                }
            } catch { print("Error loading video properties: \(error)") }
        }
    }

    private func cleanupPlayer() {
        player.pause()
        if let observer = timeObserver { player.removeTimeObserver(observer); timeObserver = nil }
    }
    
    private func togglePlayPause() {
        // Add haptic feedback
        #if canImport(SharedServices)
        HapticManager.shared.playImpact(style: .light)
        #else
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
        
        isPlaying.toggle()
        if isPlaying {
            if currentTime < trimStartTime || currentTime >= trimEndTime { seekToTime(trimStartTime) }
            // Ensure player is muted before playing
            player.isMuted = true
            player.volume = 0.0
            player.play()
        } else {
            player.pause()
        }
    }
    
    private func seekToTime(_ time: Double) {
        // Cancel any pending seek operations
        seekDebounceTimer?.invalidate()
        
        // If we're actively dragging, use debounced seeking for smoother performance
        if activeDrag != .none {
            pendingSeekTime = time
            seekDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: false) { _ in
                self.performSeek(time)
            }
        } else {
            // Immediate seek when not dragging
            performSeek(time)
        }
    }
    
    private func performSeek(_ time: Double) {
        // Use appropriate tolerance based on context
        let tolerance = activeDrag != .none 
            ? CMTime(seconds: 0.2, preferredTimescale: 600)  // Coarser for dragging
            : CMTime(seconds: 0.01, preferredTimescale: 600) // Finer for precise seeks
        
        // Cancel any in-progress seeks
        player.currentItem?.cancelPendingSeeks()
        
        player.seek(
            to: CMTime(seconds: max(0, time), preferredTimescale: 600),
            toleranceBefore: tolerance,
            toleranceAfter: tolerance,
            completionHandler: { finished in
                if finished {
                    // Only preroll if not actively dragging
                    if self.activeDrag == .none {
                        self.player.currentItem?.preferredForwardBufferDuration = 2.0
                    }
                }
            }
        )
    }
    
    private func performTrim() {
        guard !isTrimming else { return }
        
        // Validate duration before trimming
        guard isDurationValid else {
            // Show feedback that duration is invalid
            #if canImport(SharedServices)
            HapticManager.shared.playNotification(type: .error)
            #else
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            #endif
            print("❌ Cannot trim: Invalid duration \(clipDuration)s (min: \(configuration.minDuration)s, max: \(configuration.maxDuration)s)")
            return
        }
        
        // Add haptic feedback for trim action
        #if canImport(SharedServices)
        HapticManager.shared.playImpact(style: .medium)
        #else
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
        
        isTrimming = true
        player.pause()
        
        print("🎬 Starting trim: \(trimStartTime)s to \(trimEndTime)s (duration: \(clipDuration)s)")
        print("📱 Source video URL: \(sourceVideoURL)")
        
        Task {
            do {
                let url = try await trimVideo(at: sourceVideoURL, startTime: trimStartTime, endTime: trimEndTime)
                print("✅ Trim successful: \(url.lastPathComponent)")
                await MainActor.run { 
                    onTrimComplete(url)
                    dismiss() 
                }
            } catch {
                print("❌ Trim failed with error: \(error)")
                print("❌ Trim failed description: \(error.localizedDescription)")
                // Provide user feedback
                #if canImport(SharedServices)
                HapticManager.shared.playNotification(type: .error)
                #else
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                #endif
                await MainActor.run { 
                    isTrimming = false
                    // Could show an alert to the user here
                }
            }
        }
    }
    
    private func trimVideo(at url: URL, startTime: Double, endTime: Double) async throws -> URL {
        print("🎬 Starting video trim process...")
        let asset = AVAsset(url: url)
        
        // Pre-validate the asset and get detailed info
        do {
            let tracks = try await asset.loadTracks(withMediaType: .video)
            guard !tracks.isEmpty else {
                print("❌ No video tracks found in asset")
                throw VideoTrimError.exportFailed
            }
            
            // Log video characteristics for debugging problematic videos
            if let firstTrack = tracks.first {
                let naturalSize = try await firstTrack.load(.naturalSize)
                let nominalFrameRate = try await firstTrack.load(.nominalFrameRate)
                let estimatedDataRate = try await firstTrack.load(.estimatedDataRate)
                print("📊 Video specs - Size: \(naturalSize), FPS: \(nominalFrameRate), Bitrate: \(estimatedDataRate)")
            }
        } catch {
            print("❌ Failed to validate video asset: \(error)")
            throw VideoTrimError.exportFailed
        }
        
        // Validate and constrain time values
        let assetDuration = try await asset.load(.duration).seconds
        let validStartTime = max(0, min(startTime, assetDuration))
        let validEndTime = max(validStartTime, min(endTime, assetDuration))
        
        print("📏 Trimming with validated times: \(validStartTime)s to \(validEndTime)s (original: \(startTime)s to \(endTime)s)")
        
        // Create output URL first - using mp4 for better compression
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("trimmed_\(UUID().uuidString).mp4")
        
        // Remove existing file if needed
        try? FileManager.default.removeItem(at: outputURL)
        
        // Ensure we can write to the output location
        let outputDir = outputURL.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: outputDir.path) {
            try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
        }
        
        // Try multiple export presets for compatibility
        let presets = [
            Constants.exportQualityPreset,
            AVAssetExportPresetHighestQuality,
            AVAssetExportPresetMediumQuality,
            AVAssetExportPreset1920x1080
        ]
        
        var exportSession: AVAssetExportSession?
        var usedPreset = ""
        
        for preset in presets {
            if AVAssetExportSession.exportPresets(compatibleWith: asset).contains(preset) {
                exportSession = AVAssetExportSession(asset: asset, presetName: preset)
                usedPreset = preset
                print("📱 Export session created with preset: \(preset)")
                break
            } else {
                print("⚠️ Preset \(preset) not compatible with this video")
            }
        }
        
        guard let exportSession = exportSession else {
            print("❌ No compatible export presets found for this video")
            throw VideoTrimError.exportFailed
        }
        
        // Configure the export session
        exportSession.outputURL = outputURL
        exportSession.outputFileType = AVFileType.mp4
        exportSession.shouldOptimizeForNetworkUse = true
        
        // For problematic videos, be more conservative with settings
        if usedPreset != Constants.exportQualityPreset {
            print("⚠️ Using fallback preset - video may have compatibility issues")
            // Disable metadata copying for problematic videos
            exportSession.metadataItemFilter = AVMetadataItemFilter.forSharing()
        }
        
        // Set the time range for trimming with validated times
        let startCMTime = CMTime(seconds: validStartTime, preferredTimescale: 600)
        let endCMTime = CMTime(seconds: validEndTime, preferredTimescale: 600)
        exportSession.timeRange = CMTimeRange(start: startCMTime, end: endCMTime)
        
        print("⏰ Time range set: \(startCMTime) to \(endCMTime)")
        
        // Export the video
        await exportSession.export()
        
        print("📊 Export completed with status: \(exportSession.status.rawValue)")
        
        // Check the export status
        switch exportSession.status {
        case .completed:
            // Verify the file was actually created and has content
            if FileManager.default.fileExists(atPath: outputURL.path) {
                let attributes = try? FileManager.default.attributesOfItem(atPath: outputURL.path)
                let fileSize = attributes?[.size] as? Int64 ?? 0
                print("✅ Export successful - File size: \(fileSize) bytes")
                if fileSize > 0 {
                    return outputURL
                } else {
                    print("❌ Export file is empty")
                    throw VideoTrimError.exportFailed
                }
            } else {
                print("❌ Export file doesn't exist at path: \(outputURL.path)")
                throw VideoTrimError.exportFailed
            }
        case .failed:
            let errorMsg = exportSession.error?.localizedDescription ?? "Unknown error"
            print("❌ Export failed: \(errorMsg)")
            if let error = exportSession.error {
                print("❌ Export error details: \(error)")
            }
            throw exportSession.error ?? VideoTrimError.exportFailed
        case .cancelled:
            print("⚠️ Export cancelled")
            throw VideoTrimError.exportFailed
        default:
            print("❌ Export status: \(exportSession.status.rawValue)")
            throw VideoTrimError.exportFailed
        }
    }

    
    // MARK: - Gestures
    // Removed scrubberDragGesture - functionality now integrated into unified gesture handler
    
    // Magnified Preview removed - no popup when dragging
    
    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        let millis = Int((seconds - Double(Int(seconds))) * 100)
        return String(format: "%02d:%02d.%02d", mins, secs, millis)
    }
    
    private func getConstraintMessage() -> String {
        switch constraintViolation {
        case .minDuration:
            return "Min: \(String(format: "%.1fs", configuration.minDuration))"
        case .maxDuration:
            return "Max: \(String(format: "%.1fs", configuration.maxDuration))"
        case .minPixelWidth:
            return "Too narrow"
        case .none:
            if clipDuration < configuration.minDuration {
                return "Too short"
            } else if clipDuration > configuration.maxDuration {
                return "Too long"
            } else {
                return "Duration: \(String(format: "%.1fs", clipDuration))"
            }
        }
    }
    
    private func startHandleDragGesture(pixelsPerSecond: Double, geometry: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if activeDrag == .none { 
                    activeDrag = .start
                    gestureStartState = (trimStartTime, trimEndTime)
                    // Haptic feedback
                    #if canImport(SharedServices)
                    HapticManager.shared.playImpact(style: .medium)
                    #else
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    #endif
                }
                
                guard let startState = gestureStartState else { return }
                let newStartTime = startState.start + value.translation.width / pixelsPerSecond
                
                // Calculate new start time, constrained to video bounds
                let potentialStart = max(0, min(newStartTime, videoDuration))
                
                // Ensure minimum duration is maintained
                let minDuration = configuration.minDuration
                let maxDuration = configuration.maxDuration
                
                // Check constraints
                if potentialStart > trimEndTime - minDuration {
                    // Would violate minimum duration, stop at minimum
                    trimStartTime = max(0, trimEndTime - minDuration)
                } else if potentialStart < trimEndTime - maxDuration {
                    // Would violate maximum duration, stop at maximum
                    trimStartTime = max(0, trimEndTime - maxDuration)
                } else {
                    // Within valid range, move freely
                    trimStartTime = potentialStart
                }
            }
            .onEnded { _ in 
                activeDrag = .none
                gestureStartState = nil
                // Restore buffer settings
                player.currentItem?.preferredForwardBufferDuration = 2.0
                // Haptic feedback
                #if canImport(SharedServices)
                HapticManager.shared.playImpact(style: .light)
                #else
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                #endif
            }
    }

    private func endHandleDragGesture(pixelsPerSecond: Double, geometry: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if activeDrag == .none { 
                    activeDrag = .end
                    gestureStartState = (trimStartTime, trimEndTime)
                    // Haptic feedback
                    #if canImport(SharedServices)
                    HapticManager.shared.playImpact(style: .medium)
                    #else
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    #endif
                }
                
                guard let startState = gestureStartState else { return }
                let newEndTime = startState.end + value.translation.width / pixelsPerSecond
                
                // Calculate new end time, constrained to video bounds
                let potentialEnd = max(0, min(newEndTime, videoDuration))
                
                // Ensure minimum and maximum duration constraints
                let minDuration = configuration.minDuration
                let maxDuration = configuration.maxDuration
                
                // Check constraints
                if potentialEnd < trimStartTime + minDuration {
                    // Would violate minimum duration, stop at minimum
                    trimEndTime = min(videoDuration, trimStartTime + minDuration)
                } else if potentialEnd > trimStartTime + maxDuration {
                    // Would violate maximum duration, stop at maximum
                    trimEndTime = min(videoDuration, trimStartTime + maxDuration)
                } else {
                    // Within valid range, move freely
                    trimEndTime = potentialEnd
                }
            }
            .onEnded { _ in 
                activeDrag = .none
                gestureStartState = nil
                // Restore buffer settings
                player.currentItem?.preferredForwardBufferDuration = 2.0
                // Haptic feedback
                #if canImport(SharedServices)
                HapticManager.shared.playImpact(style: .light)
                #else
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                #endif
            }
    }
    
    // MARK: - Thumbnail Generation
    private func generateThumbnails(for asset: AVAsset) async -> [UIImage] {
        print("🎬 Starting thumbnail generation at \(Date())")
        
        // CRITICAL FIX: Wrap entire generation in background task to prevent UI blocking
        return await Task.detached(priority: .userInitiated) {
            await self.generateThumbnailsInternal(for: asset)
        }.value
    }
    
    private func generateThumbnailsInternal(for asset: AVAsset) async -> [UIImage] {
        // Check if this is a camera-recorded video (has complex transforms/metadata)
        var isCameraVideo = false
        
        // First check if we have video tracks
        do {
            let videoTracks = try await asset.loadTracks(withMediaType: .video)
            guard !videoTracks.isEmpty else {
                print("❌ No video tracks found")
                return createVideoFrames(count: Constants.thumbnailCount)
            }
            
            // Detect camera videos by checking for transforms
            if let firstTrack = videoTracks.first {
                let transform = try await firstTrack.load(.preferredTransform)
                let angle = atan2(transform.b, transform.a) * 180 / .pi
                isCameraVideo = abs(angle) > 1 // Has rotation = camera video
                print("📱 Video type: \(isCameraVideo ? "Camera-recorded" : "Screen/other") (rotation: \(angle)°)")
            }
        } catch {
            print("❌ Failed to load video tracks: \(error)")
            return createVideoFrames(count: Constants.thumbnailCount)
        }
        
        // Get duration safely
        let duration: Double
        do {
            duration = try await asset.load(.duration).seconds
        } catch {
            print("❌ Failed to load duration: \(error)")
            return createVideoFrames(count: Constants.thumbnailCount)
        }
        
        guard duration > 0 else { 
            print("❌ Invalid duration: \(duration)")
            return createVideoFrames(count: Constants.thumbnailCount)
        }
        
        print("📹 Video duration: \(duration) seconds")
        
        // Simple thumbnail generation for all videos (5 minutes max typical)
        let generator = AVAssetImageGenerator(asset: asset)
        
        // For camera videos, be more careful about transforms to avoid AX issues
        if isCameraVideo {
            generator.appliesPreferredTrackTransform = true
            generator.apertureMode = .cleanAperture // Use clean aperture for camera videos
            print("🎥 Using camera-optimized settings for thumbnail generation")
        } else {
            generator.appliesPreferredTrackTransform = true
            generator.apertureMode = .encodedPixels // Use encoded pixels for screen recordings
        }
        
        // Fixed settings - simple and fast for all videos
        let frameCount = Constants.thumbnailCount
        // Use zero tolerance to force exact frame extraction (helps with sparse keyframes)
        let tolerance = CMTime.zero
        let maxSize = Constants.thumbnailMaxSize
        let timeoutSeconds: UInt64 = 15_000_000_000 // 15 second timeout for longer videos
        
        // Simple fixed settings for all videos
        // No need for adaptive settings for 5-minute max videos
        
        generator.maximumSize = maxSize
        // Use zero tolerance to get exact frames - helps with videos that have sparse keyframes
        generator.requestedTimeToleranceBefore = CMTime.zero
        generator.requestedTimeToleranceAfter = CMTime.zero
        
        var times: [NSValue] = []
        
        // For longer videos, sample more conservatively to avoid decode errors
        // Skip 5% at start and end for videos over 3 minutes to avoid problematic areas
        let skipRatio = duration > 180 ? 0.05 : 0.01
        let startOffset = min(duration * skipRatio, 5.0) // Skip up to 5 seconds for long videos
        let endOffset = max(duration - min(duration * skipRatio, 5.0), duration * (1 - skipRatio))
        let range = endOffset - startOffset
        
        // Generate evenly spaced sample points
        for i in 0..<frameCount {
            let progress = Double(i) / Double(max(frameCount - 1, 1))
            let time = CMTime(seconds: startOffset + (range * progress), preferredTimescale: 600)
            times.append(NSValue(time: time))
        }
        
        // Use async generation with adaptive timeout
        return await withCheckedContinuation { continuation in
            var frames: [UIImage] = []
            var completed = 0
            let lock = NSLock()
            var hasResumed = false
            
            // Add adaptive timeout
            Task {
                try? await Task.sleep(nanoseconds: timeoutSeconds)
                lock.lock()
                defer { lock.unlock() }
                
                if !hasResumed {
                    hasResumed = true
                    let timeoutSec = Double(timeoutSeconds) / 1_000_000_000
                    print("⏱️ Thumbnail generation timed out after \(timeoutSec)s, returning \(frames.count)/\(frameCount) frames")
                    
                    // Fill remaining with black frames
                    while frames.count < frameCount {
                        frames.append(self.createVideoFrame())
                    }
                    
                    continuation.resume(returning: frames.isEmpty ? self.createVideoFrames(count: frameCount) : frames)
                }
            }
            
            // CRITICAL: Wrap generation in background queue to prevent initial blocking
            DispatchQueue.global(qos: .userInitiated).async {
                generator.generateCGImagesAsynchronously(forTimes: times) { requestedTime, cgImage, actualTime, result, error in
                    lock.lock()
                    defer { lock.unlock() }
                
                guard !hasResumed else { return }
                
                completed += 1
                
                if let cgImage = cgImage {
                    // For camera videos, create normalized UIImage to avoid AX issues
                    let thumbnailImage = if isCameraVideo {
                        // Normalize orientation for camera videos to reduce AX system confusion
                        UIImage(cgImage: cgImage, scale: 1.0, orientation: .up)
                    } else {
                        UIImage(cgImage: cgImage)
                    }
                    frames.append(thumbnailImage)
                    // Removed verbose logging to reduce console noise
                } else {
                    // For decode errors on long videos, try to use a nearby frame
                    if error?.localizedDescription.contains("Decode") == true && completed > 1 && !frames.isEmpty {
                        // Reuse the last successful frame instead of a black placeholder
                        frames.append(frames.last!)
                        print("⚠️ Frame \(completed) decode error - reusing previous frame")
                    } else {
                        // Create a video-like placeholder
                        frames.append(self.createVideoFrame())
                        if let error = error {
                            print("⚠️ Frame \(completed) error: \(error.localizedDescription)")
                        } else {
                            print("⚠️ Using placeholder for frame \(completed)/\(frameCount)")
                        }
                    }
                }
                
                // Update progress only every few frames to reduce main thread updates
                if completed % 3 == 0 || completed == frameCount {
                    Task { @MainActor in
                        self.loadingProgress = Double(completed) / Double(frameCount)
                    }
                }
                
                // Check if done
                if completed == times.count && !hasResumed {
                    hasResumed = true
                    print("✅ Thumbnail generation complete: \(frames.count) frames at \(Date())")
                    
                    // Ensure we have the right count
                    while frames.count < frameCount {
                        frames.append(self.createVideoFrame())
                    }
                    
                    continuation.resume(returning: frames)
                }
            } // End of generateCGImagesAsynchronously closure
            } // End of DispatchQueue.global block
        }
    }
    
    // Create video-like frames instead of gray placeholders
    private func createVideoFrames(count: Int) -> [UIImage] {
        var frames: [UIImage] = []
        for _ in 0..<count {
            frames.append(createVideoFrame())
        }
        return frames
    }
    
    private func createVideoFrame() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 200, height: 150))
        return renderer.image { ctx in
            // Dark background like a video frame
            UIColor.black.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 200, height: 150))
            
            // Add subtle gradient to look like video
            let colors = [
                UIColor.black.cgColor,
                UIColor(white: 0.1, alpha: 1.0).cgColor
            ]
            if let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors as CFArray,
                locations: [0, 1]
            ) {
                ctx.cgContext.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: 0, y: 0),
                    end: CGPoint(x: 200, y: 150),
                    options: []
                )
            }
        }
    }
    
    // MARK: - Removed Code (kept for reference)
    // Progressive loading was removed as it's not needed for 2-minute max videos
    /* REMOVED:
    private func generateThumbnailsProgressive(for asset: AVAsset, duration: Double) async -> [UIImage] {
        print("🎬 Using progressive loading for large video (\(duration)s)")
        
        // Use fewer frames for very long videos to save memory
        let frameCount = duration > 600 ? Constants.largVideoThumbnailCount : Constants.thumbnailCount
        var frames: [UIImage] = createVideoFrames(count: frameCount)
        
        // Generate frames progressively in background
        Task.detached(priority: .background) { [weak self] in
            guard let self = self else { return }
            
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            
            // Memory-efficient settings for large videos
            let maxDimension: CGFloat = duration > 600 ? 40 : 60
            generator.maximumSize = CGSize(width: maxDimension, height: maxDimension)
            
            // Aggressive tolerance for large videos
            let toleranceSeconds = duration > 600 ? 20.0 : 10.0
            let tolerance = CMTime(seconds: toleranceSeconds, preferredTimescale: 600)
            generator.requestedTimeToleranceBefore = tolerance
            generator.requestedTimeToleranceAfter = tolerance
            
            // Cancel any pending requests when task is cancelled
            generator.cancelAllCGImageGeneration()
            
            // Generate only key frames evenly distributed
            let startOffset = min(duration * 0.02, 2.0) // Skip first 2% or 2 seconds
            let endOffset = max(duration - min(duration * 0.02, 2.0), duration * 0.98)
            let range = endOffset - startOffset
            
            // Batch generate for better performance
            var times: [NSValue] = []
            for i in 0..<frameCount {
                let progress = Double(i) / Double(max(frameCount - 1, 1))
                let time = CMTime(seconds: startOffset + (range * progress), preferredTimescale: 600)
                times.append(NSValue(time: time))
            }
            
            // Generate with async batch API
            var successCount = 0
            generator.generateCGImagesAsynchronously(forTimes: times) { [weak self] requestedTime, cgImage, actualTime, result, error in
                guard let self = self else { return }
                
                // Find index for this time
                if let index = times.firstIndex(where: { $0.timeValue == requestedTime }) {
                    if let cgImage = cgImage {
                        // Create smaller UIImage to save memory
                        let uiImage = UIImage(cgImage: cgImage)
                        
                        Task { @MainActor in
                            if self.thumbnailFrames.count == frameCount {
                                self.thumbnailFrames[index] = uiImage
                                successCount += 1
                                print("✅ Progressive frame \(index+1)/\(frameCount) loaded")
                                
                                // Update loading progress
                                self.loadingProgress = Double(successCount) / Double(frameCount)
                            }
                        }
                    } else if let error = error {
                        print("⚠️ Frame \(index+1) error: \(error.localizedDescription)")
                    }
                }
            }
        }
        
        // Return placeholders immediately
        return frames
    }
    */
    
    
    @ViewBuilder private func playheadLine(pixelsPerSecond: Double) -> some View {
        if videoDuration > 0 && currentTime >= trimStartTime && currentTime <= trimEndTime {
            // Simple white playhead line
            Rectangle()
                .fill(Color.white)
                .frame(width: 2, height: Constants.timelineHeight)
                .shadow(color: .black.opacity(0.3), radius: 1)
                .offset(x: max(0, currentTime * pixelsPerSecond - 1))
                .allowsHitTesting(false)
                .animation(.linear(duration: 0.05), value: currentTime)
        }
    }
}

// MARK: - Modern Scrubber Handle
private struct ModernScrubberHandle: View {
    @Environment(\.theme) var theme
    let isActive: Bool
    
    public var body: some View {
        VStack(spacing: 0) {
            // Handle dot
            ZStack {
                // Glow effect
                Circle()
                    .fill(theme.primary)
                    .frame(width: 16, height: 16)
                    .blur(radius: isActive ? 5 : 2)
                    .opacity(isActive ? 0.5 : 0.2)
                
                // Main handle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white,
                                theme.primary.opacity(0.9)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: isActive ? 16 : 14, height: isActive ? 16 : 14)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
            }
            
            // Connecting line to timeline
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.8),
                            Color.white.opacity(0.4)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 2, height: 10)
                .shadow(color: .black.opacity(0.3), radius: 1)
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isActive)
    }
}

// MARK: - Vertical Trim Handle
// iOS Photos App Style Trim Handle (matches GitHub VideoTrimmerThumb)
private struct VerticalTrimHandle: View {
    @Environment(\.theme) var theme
    let isLeft: Bool
    let isActive: Bool
    
    public var body: some View {
        ZStack {
            // Modern handle with gradient and better shadows
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            theme.primary,
                            theme.primary.opacity(0.9)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 16, height: VideoTrimmerView.Constants.timelineHeight)
                .clipShape(
                    VideoTrimmerRoundedCorner(
                        radius: VideoTrimmerView.Constants.handleCornerRadius,
                        corners: isLeft ? [.topLeft, .bottomLeft] : [.topRight, .bottomRight]
                    )
                )
                .overlay(
                    // Subtle inner highlight
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.2),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                        .clipShape(
                            VideoTrimmerRoundedCorner(
                                radius: VideoTrimmerView.Constants.handleCornerRadius,
                                corners: isLeft ? [.topLeft, .bottomLeft] : [.topRight, .bottomRight]
                            )
                        )
                )
                .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
            
            // Refined grip lines instead of chevron
            VStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 2, height: 8)
                        .clipShape(RoundedRectangle(cornerRadius: 1))
                }
            }
        }
        .frame(width: 16, height: VideoTrimmerView.Constants.timelineHeight)
        .contentShape(Rectangle())
        .scaleEffect(isActive ? 1.05 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isActive)
    }
}

// Helper for rounded corners on specific edges
private struct VideoTrimmerRoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}


// MARK: - Reusable Timeline Preview
public struct VideoTimelineView: View {
    let videoURL: URL
    @State private var frames: [UIImage] = []
    
    public var body: some View {
        HStack(spacing: 0) {
            if frames.isEmpty {
                Color.black.opacity(0.2)
            } else {
                ForEach(frames.indices, id: \.self) { index in
                    Image(uiImage: frames[index])
                        .resizable()
                        .scaledToFill()
                }
            }
        }
        .clipped()
        .onAppear(perform: generateFrames)
    }
    
    private func generateFrames() {
        Task(priority: .userInitiated) {
            let asset = AVAsset(url: videoURL)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = CGSize(width: 200, height: 200) // Square to handle both orientations
            
            let duration = try? await asset.load(.duration).seconds
            guard let duration, duration > 0 else { return }
            
            let frameCount = 10
            var generatedFrames: [UIImage] = []
            
            for i in 0..<frameCount {
                let time = CMTime(seconds: duration * Double(i) / Double(frameCount), preferredTimescale: 600)
                if let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) {
                    // The generator applies transform automatically when appliesPreferredTrackTransform = true
                    generatedFrames.append(UIImage(cgImage: cgImage))
                }
            }
            
            await MainActor.run { self.frames = generatedFrames }
        }
    }
}

// MARK: - Triangle Shape
private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
