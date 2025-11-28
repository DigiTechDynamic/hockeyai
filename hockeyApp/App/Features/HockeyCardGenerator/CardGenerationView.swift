import SwiftUI
import UIKit

// MARK: - Card Generation View
/// Final screen that generates and displays the hockey card
struct CardGenerationView: View {
    @Environment(\.theme) var theme
    @StateObject private var viewModel: CardGenerationViewModel
    let playerInfo: PlayerCardInfo
    let jerseySelection: JerseySelection
    let onDismiss: () -> Void

    // Animation states
    @State private var showCard = false
    @State private var cardScale: CGFloat = 0.8
    @State private var cardRotation: Double = 10
    @State private var showingPaywall = false

    init(playerInfo: PlayerCardInfo, jerseySelection: JerseySelection, onDismiss: @escaping () -> Void) {
        self.playerInfo = playerInfo
        self.jerseySelection = jerseySelection
        self.onDismiss = onDismiss
        _viewModel = StateObject(wrappedValue: CardGenerationViewModel(
            playerInfo: playerInfo,
            jerseySelection: jerseySelection
        ))
    }

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Content
                if viewModel.isGenerating {
                    // Full-screen processing view (matches other AI features)
                    CardGenerationProcessingView(viewModel: viewModel, onCancel: onDismiss)
                } else if viewModel.error != nil {
                    // Full-screen error view using reusable component
                    AIServiceErrorView(
                        errorType: viewModel.errorType ?? .processingFailed,
                        onRetry: {
                            viewModel.generateCard()
                        },
                        onDismiss: onDismiss
                    )
                } else if let generatedCard = viewModel.generatedCard {
                    // Header for result state
                    header
                    ScrollView {
                        generatedCardView(image: generatedCard)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                        Spacer(minLength: 80)
                    }
                    .scrollIndicators(.hidden)
                } else {
                    // Initial state - should auto-generate
                    CardGenerationProcessingView(viewModel: viewModel, onCancel: onDismiss)
                }
            }

            // Bottom actions (only when showing generated card)
            if !viewModel.isGenerating && viewModel.error == nil && viewModel.generatedCard != nil {
                VStack {
                    Spacer()
                    bottomActions
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.generateCard()
        }
        .fullScreenCover(isPresented: $showingPaywall) {
            PaywallPresenter(source: "card_result_upsell")
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            Button(action: onDismiss) {
                ZStack {
                    Circle()
                        .fill(theme.surface.opacity(0.5))
                        .frame(width: 40, height: 40)

                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
            }

            Spacer()

            Text("Your Card")
                .font(.system(size: 20, weight: .black))
                .glowingHeaderText()

            Spacer()

            // Invisible spacer
            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            theme.background.opacity(0.8)
                .blur(radius: 20)
                .ignoresSafeArea()
        )
    }

    // MARK: - Generated Card View
    private func generatedCardView(image: UIImage) -> some View {
        VStack(spacing: 32) {
            VStack(spacing: 8) {
                Text("Your custom hockey card is ready")
                    .font(theme.fonts.body)
                    .foregroundColor(theme.textSecondary)
            }

            // Card image
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke((viewModel.dominantColor ?? theme.primary).opacity(0.5), lineWidth: 2)
                )
                .shadow(color: (viewModel.dominantColor ?? theme.primary).opacity(0.6), radius: 30, x: 0, y: 15)
                .shadow(color: (viewModel.dominantColor ?? theme.primary).opacity(0.3), radius: 50, x: 0, y: 0)
                .padding(.horizontal, 20)
                .scaleEffect(cardScale)
                .rotation3DEffect(.degrees(cardRotation), axis: (x: 0, y: 1, z: 0))
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        cardScale = 1.0
                        cardRotation = 0
                    }
                }
        }
        .padding(.top, 20)
    }

    // MARK: - Bottom Actions
    private var bottomActions: some View {
        VStack(spacing: 12) {
            // Save to Photos button
            Button(action: {
                viewModel.saveCard()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 16, weight: .bold))
                    Text("Save to Photos")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(theme.surface.opacity(0.5))
                .cornerRadius(25)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(theme.primary.opacity(0.5), lineWidth: 1)
                )
            }

            // Create Another Card - BIG CTA
            Button(action: {
                HapticManager.shared.playSelection()
                onDismiss()
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18, weight: .bold))
                    Text("Create Another Card")
                        .font(.system(size: 17, weight: .bold))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(theme.primary)
                .cornerRadius(28)
                .shadow(color: theme.primary.opacity(0.4), radius: 10, x: 0, y: 5)
            }

            // Upsell for free users - subtle
            if !MonetizationManager.shared.isPremium {
                Button(action: {
                    HapticManager.shared.playSelection()
                    showingPaywall = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.yellow)
                        Text("Unlock Unlimited Cards")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(theme.textSecondary)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .background(
            LinearGradient(colors: [theme.background.opacity(0), theme.background], startPoint: .top, endPoint: .bottom)
                .frame(height: 100)
                .offset(y: 20)
        )
    }
}

// MARK: - Card Generation Processing View
/// Modern processing view matching other AI analyzer features
struct CardGenerationProcessingView: View {
    @Environment(\.theme) var theme
    @ObservedObject var viewModel: CardGenerationViewModel
    let onCancel: () -> Void

    // Animation states
    @State private var pulseAnimation = false
    @State private var showPercentage = false
    @State private var showCancelConfirm = false

    // Haptic feedback
    private let impactGenerator = UIImpactFeedbackGenerator(style: .light)
    @State private var hapticTimer: Timer?

    var body: some View {
        ZStack {
            // Background
            theme.background.ignoresSafeArea()

            // Subtle radial glow
            RadialGradient(
                colors: [theme.primary.opacity(0.08), Color.clear],
                center: .top,
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Main content
                VStack(spacing: theme.spacing.xxl) {
                    // Icon with glow effects
                    ZStack {
                        // Outer glow layer
                        Circle()
                            .fill(theme.primary)
                            .frame(width: 120, height: 120)
                            .blur(radius: 35)
                            .opacity(pulseAnimation ? 0.5 : 0.3)
                            .scaleEffect(pulseAnimation ? 1.3 : 1.0)
                            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: pulseAnimation)

                        // Mid glow layer
                        Circle()
                            .fill(theme.primary.opacity(0.4))
                            .frame(width: 100, height: 100)
                            .blur(radius: 20)
                            .scaleEffect(pulseAnimation ? 1.15 : 0.95)
                            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseAnimation)

                        // Outer pulsing ring
                        Circle()
                            .stroke(theme.primary.opacity(0.3), lineWidth: 2)
                            .frame(width: 110, height: 110)
                            .scaleEffect(pulseAnimation ? 1.25 : 1.0)
                            .opacity(pulseAnimation ? 0 : 0.6)
                            .animation(.easeOut(duration: 2.0).repeatForever(autoreverses: false), value: pulseAnimation)

                        // Inner circle background
                        Circle()
                            .stroke(theme.divider.opacity(0.3), lineWidth: 3)
                            .frame(width: 90, height: 90)

                        // Progress circle
                        Circle()
                            .trim(from: 0, to: viewModel.progress)
                            .stroke(
                                LinearGradient(
                                    colors: [theme.primary, theme.primary.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 3, lineCap: .round)
                            )
                            .frame(width: 90, height: 90)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 0.5), value: viewModel.progress)

                        // Center icon - hockey card themed
                        Image(systemName: "rectangle.portrait.on.rectangle.portrait.angled.fill")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(theme.primary)
                            .shadow(color: theme.primary.opacity(0.8), radius: 4)
                            .shadow(color: theme.primary.opacity(0.5), radius: 10)
                            .shadow(color: theme.primary.opacity(0.3), radius: 20)
                            .scaleEffect(pulseAnimation ? 1.05 : 0.95)
                            .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: pulseAnimation)
                    }
                    .frame(height: 120)

                    // Title and phase with athletic styling
                    VStack(spacing: theme.spacing.md) {
                        // Main title with gradient
                        Text("CREATING CARD")
                            .font(.system(size: 32, weight: .black))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color.white,
                                        Color.white.opacity(0.95)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: Color.white.opacity(0.5), radius: 0, x: 0, y: 0)
                            .shadow(color: Color.white.opacity(0.3), radius: 4, x: 0, y: 0)
                            .shadow(color: theme.primary.opacity(0.4), radius: 10, x: 0, y: 2)
                            .tracking(3)

                        // Current phase
                        VStack(spacing: theme.spacing.xs) {
                            Text(viewModel.currentPhase)
                                .font(.system(size: 14, weight: .heavy))
                                .foregroundColor(theme.primary)
                                .tracking(2)
                                .animation(.easeInOut(duration: 0.4), value: viewModel.currentPhase)

                            Text(viewModel.phaseDetail)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(theme.textSecondary.opacity(0.6))
                                .animation(.easeInOut(duration: 0.4), value: viewModel.phaseDetail)
                        }

                        // Time expectation
                        Text("This usually takes 1-2 minutes")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(theme.textSecondary.opacity(0.4))
                            .padding(.top, theme.spacing.sm)
                    }

                    // Animated cards indicator
                    CardGenerationDotsIndicator(theme: theme)
                        .padding(.top, theme.spacing.sm)
                }

                Spacer()

                // Percentage display at bottom
                if showPercentage {
                    Text("\(viewModel.percentageValue)%")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(theme.textSecondary.opacity(0.4))
                        .animation(.easeIn(duration: 0.3), value: viewModel.percentageValue)
                }

                Spacer().frame(height: 40)
            }
        }
        // Cancel button overlay
        .overlay(alignment: .topTrailing) {
            Button(action: { showCancelConfirm = true }) {
                Text("Cancel")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.red.opacity(0.95)))
            }
            .padding(.top, 16)
            .padding(.trailing, 20)
        }
        .onAppear {
            startAnimations()
        }
        .onDisappear {
            stopHaptics()
        }
        .confirmationDialog(
            "Cancel card generation?",
            isPresented: $showCancelConfirm,
            titleVisibility: .visible
        ) {
            Button("Stop Generation", role: .destructive) {
                onCancel()
            }
            Button("Keep Creating", role: .cancel) {}
        }
    }

    private func startAnimations() {
        // Start pulse animation
        withAnimation {
            pulseAnimation = true
        }

        // Show percentage after initial delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showPercentage = true
            }
        }

        // Start haptic feedback
        impactGenerator.prepare()
        startHapticPulse()
    }

    private func startHapticPulse() {
        // Gentle haptic pulse every 3 seconds during processing
        hapticTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            impactGenerator.impactOccurred(intensity: 0.3)
        }
    }

    private func stopHaptics() {
        hapticTimer?.invalidate()
        hapticTimer = nil
    }
}

// MARK: - Animated Dots Component (Card themed)
struct CardGenerationDotsIndicator: View {
    let theme: any AppTheme
    @State private var activeIndex = 0
    @State private var dotScale: [CGFloat] = [1.0, 1.0, 1.0, 1.0, 1.0]

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<5) { index in
                ZStack {
                    // Glow effect for active dot
                    if activeIndex == index {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(theme.primary)
                            .frame(width: 12, height: 16)
                            .blur(radius: 5)
                            .opacity(0.6)
                    }

                    // Main card shape (small rectangle)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(activeIndex == index ? theme.primary : theme.divider.opacity(0.3))
                        .frame(width: 8, height: 12)
                        .scaleEffect(dotScale[index])
                        .shadow(color: activeIndex == index ? theme.primary.opacity(0.6) : .clear, radius: 3)
                }
                .animation(.easeInOut(duration: 0.3), value: activeIndex)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: dotScale[index])
            }
        }
        .onAppear {
            animateDots()
        }
    }

    private func animateDots() {
        Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
            withAnimation {
                activeIndex = (activeIndex + 1) % 5

                // Create wave effect
                for i in 0..<5 {
                    if i == activeIndex {
                        dotScale[i] = 1.4
                    } else {
                        dotScale[i] = 1.0
                    }
                }
            }
        }
    }
}

// MARK: - Card Generation View Model
class CardGenerationViewModel: ObservableObject {
    @Published var isGenerating = false
    @Published var generatedCard: UIImage? = nil
    @Published var dominantColor: Color? = nil
    @Published var error: String? = nil
    @Published var errorType: AIServiceErrorType? = nil

    // Progress state
    @Published var progress: CGFloat = 0.0
    @Published var currentPhase: String = "INITIALIZING"
    @Published var phaseDetail: String = "Preparing your photo..."
    @Published var percentageValue: Int = 0
    private var progressTimer: Timer?
    private var phaseIndex: Int = 0

    private let playerInfo: PlayerCardInfo
    private let jerseySelection: JerseySelection
    private let imageGenerationService: ImageGenerationService?
    private var hasStartedGeneration = false
    private var generationStartTime: Date?

    // Processing phases with realistic timing for ~100-120 second generation
    private let phases: [(title: String, detail: String, duration: Double, progress: Double)] = [
        ("PREPARING", "Preparing your photo...", 5.0, 0.05),
        ("UPLOADING", "Sending to AI...", 5.0, 0.10),
        ("GENERATING CARD", "AI is creating your card...", 40.0, 0.45),
        ("STILL GENERATING", "This takes a moment...", 30.0, 0.70),
        ("ADDING DETAILS", "Refining your card...", 20.0, 0.85),
        ("FINALIZING", "Almost there...", 15.0, 0.95)
    ]

    init(playerInfo: PlayerCardInfo, jerseySelection: JerseySelection) {
        self.playerInfo = playerInfo
        self.jerseySelection = jerseySelection
        self.imageGenerationService = ImageGenerationService()
    }

    func generateCard() {
        // Prevent duplicate calls
        guard !hasStartedGeneration else { return }
        hasStartedGeneration = true

        guard let service = imageGenerationService else {
            error = "Image generation service unavailable. Please check your API key configuration."
            return
        }

        isGenerating = true
        error = nil
        errorType = nil
        generatedCard = nil
        generationStartTime = Date()
        startProgressAnimation()

        // Track generation started (Step 5)
        HockeyCardAnalytics.trackGenerationStarted()

        service.generateHockeyCard(
            playerInfo: playerInfo,
            jerseySelection: jerseySelection
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isGenerating = false
                self?.stopProgress()

                switch result {
                case .success(let image):
                    self?.completeProgress()

                    // Calculate generation time
                    let generationTime = self?.generationStartTime.map { Date().timeIntervalSince($0) } ?? 0

                    // Delay slightly to show 100%
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self?.generatedCard = image

                        // Track completion (Step 4)
                        HockeyCardAnalytics.trackCompleted(generationTime: generationTime)

                        // Increment generation count
                        MonetizationManager.shared.incrementHockeyCardGenerationCount()

                        // Calculate dominant color
                        if let averageColor = image.averageColor {
                            self?.dominantColor = Color(averageColor)
                        }
                        HapticManager.shared.playNotification(type: .success)

                        // Save to documents for Home Screen display
                        if let data = image.pngData(),
                           let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                            let fileURL = documents.appendingPathComponent("latest_generated_card.png")
                            try? data.write(to: fileURL)
                            UserDefaults.standard.set(fileURL.path, forKey: "latestGeneratedCardPath")
                            NotificationCenter.default.post(name: NSNotification.Name("LatestCardUpdated"), object: nil)
                        }

                        // Persist in local history
                        GeneratedCardsStore.shared.save(image: image)
                    }

                case .failure(let error):
                    self?.error = error.localizedDescription
                    self?.errorType = AIServiceErrorType.from(error)
                    self?.hasStartedGeneration = false
                    HapticManager.shared.playNotification(type: .error)
                }
            }
        }
    }

    func saveCard() {
        guard let card = generatedCard else { return }
        UIImageWriteToSavedPhotosAlbum(card, nil, nil, nil)
        HapticManager.shared.playNotification(type: .success)
    }

    func shareCard() {
        guard let card = generatedCard else { return }
        let activityVC = UIActivityViewController(activityItems: [card], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }

    // MARK: - Progress Animation

    private func startProgressAnimation() {
        progress = 0.0
        percentageValue = 0
        phaseIndex = 0

        // Start phase animation
        animatePhases()

        // Start percentage animation
        animatePercentage()
    }

    private func animatePhases() {
        var accumulatedTime: Double = 0

        for (index, phase) in phases.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + accumulatedTime) { [weak self] in
                guard let self = self, self.isGenerating else { return }

                withAnimation(.easeInOut(duration: 0.4)) {
                    self.currentPhase = phase.title
                    self.phaseDetail = phase.detail
                    self.phaseIndex = index
                }

                // Animate progress to this phase's target
                withAnimation(.linear(duration: phase.duration)) {
                    self.progress = phase.progress
                }
            }
            accumulatedTime += phase.duration
        }
    }

    private func animatePercentage() {
        // Total duration is ~60 seconds
        let totalDuration: Double = 60
        let steps = 95 // Cap at 95% until complete
        let stepDuration = totalDuration / Double(steps)

        for step in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + (stepDuration * Double(step))) { [weak self] in
                guard let self = self, self.isGenerating else { return }

                withAnimation(.linear(duration: 0.1)) {
                    // Non-linear progression - slower at start and end
                    let normalizedProgress = Double(step) / Double(steps)
                    let easedProgress = self.easeInOutProgress(normalizedProgress)
                    self.percentageValue = Int(easedProgress * 95) // Cap at 95
                }
            }
        }
    }

    private func easeInOutProgress(_ t: Double) -> Double {
        // Custom easing function for more realistic progress
        if t < 0.5 {
            return 2 * t * t
        } else {
            return -1 + (4 - 2 * t) * t
        }
    }

    private func completeProgress() {
        progressTimer?.invalidate()
        progressTimer = nil
        withAnimation(.easeOut(duration: 0.3)) {
            progress = 1.0
            percentageValue = 100
            currentPhase = "COMPLETE"
            phaseDetail = "Your card is ready!"
        }
    }

    private func stopProgress() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
}
