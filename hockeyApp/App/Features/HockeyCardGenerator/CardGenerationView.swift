import SwiftUI

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
            
            // Ambient background glow
            GeometryReader { proxy in
                Circle()
                    .fill(theme.primary.opacity(0.1))
                    .frame(width: proxy.size.width * 1.2)
                    .blur(radius: 60)
                    .offset(x: -proxy.size.width * 0.3, y: proxy.size.height * 0.2)
                
                Circle()
                    .fill(theme.accent.opacity(0.1))
                    .frame(width: proxy.size.width)
                    .blur(radius: 50)
                    .offset(x: proxy.size.width * 0.4, y: -proxy.size.height * 0.3)
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                header

                // Content
                ScrollView {
                    VStack(spacing: 32) {
                        // Status or result
                        if viewModel.isGenerating {
                            generatingView
                        } else if let error = viewModel.error {
                            errorView(error: error)
                        } else if let generatedCard = viewModel.generatedCard {
                            generatedCardView(image: generatedCard)
                        } else {
                            // Initial state - should auto-generate
                            generatingView
                        }

                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
                .scrollIndicators(.hidden)
            }
            
            // Bottom actions
            if !viewModel.isGenerating {
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

            Text(viewModel.isGenerating ? "Generating..." : "Your Card")
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

    // MARK: - Generating View
    private var generatingView: some View {
        VStack(spacing: 40) {
            // Animation
            ZStack {
                // Pulsing circles
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(theme.primary.opacity(0.3), lineWidth: 2)
                        .frame(width: 100 + CGFloat(i * 40), height: 100 + CGFloat(i * 40))
                        .scaleEffect(viewModel.rotationAngle > 0 ? 1.1 : 1.0)
                        .opacity(viewModel.rotationAngle > 0 ? 0 : 1)
                        .animation(
                            Animation.easeOut(duration: 2)
                                .repeatForever(autoreverses: false)
                                .delay(Double(i) * 0.4),
                            value: viewModel.rotationAngle
                        )
                }
                
                // Center icon
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 48))
                    .foregroundColor(theme.primary)
                    .rotationEffect(.degrees(viewModel.rotationAngle))
                    .animation(.linear(duration: 4).repeatForever(autoreverses: false), value: viewModel.rotationAngle)
            }
            .padding(.top, 60)

            VStack(spacing: 16) {
                // Large neon title removed per user feedback

                Text("Our AI is crafting a pro-level hockey card just for you.")
                    .font(theme.fonts.body)
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 20)

            // Tips
            VStack(alignment: .leading, spacing: 16) {
                tipRow(icon: "clock.fill", text: "Processing high-res details...")
                tipRow(icon: "sparkles", text: "Applying pro lighting effects...")
                tipRow(icon: "photo.fill", text: "Finalizing composition...")
            }
            .padding(24)
            .background(theme.surface.opacity(0.3))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(theme.primary.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal, 20)
        }
    }

    private func tipRow(icon: String, text: String) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(theme.primary.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(theme.primary)
            }

            Text(text)
                .font(theme.fonts.callout)
                .foregroundColor(.white)

            Spacer()
        }
    }

    // MARK: - Error View
    private func errorView(error: String) -> some View {
        VStack(spacing: 32) {
            // Error icon
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.red)
            }
            .padding(.top, 60)

            VStack(spacing: 16) {
                Text("Generation Failed")
                    .font(theme.fonts.title)
                    .foregroundColor(.white)

                Text(error)
                    .font(theme.fonts.body)
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 20)

            // Retry button
            Button(action: {
                viewModel.generateCard()
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .bold))
                    Text("Try Again")
                        .font(theme.fonts.button)
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)
                .frame(height: 56)
                .padding(.horizontal, 32)
                .background(theme.primary)
                .cornerRadius(28)
                .shadow(color: theme.primary.opacity(0.4), radius: 10, x: 0, y: 5)
            }
        }
    }

    // MARK: - Generated Card View
    private func generatedCardView(image: UIImage) -> some View {
        VStack(spacing: 32) {
            VStack(spacing: 8) {
                // Large neon title removed per user feedback

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
        VStack(spacing: 16) {
            if let generatedCard = viewModel.generatedCard {
                // Save to Photos button (styled like the old Share button)
                Button(action: {
                    viewModel.saveCard()
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 18, weight: .bold))
                        Text("Save to Photos")
                            .font(theme.fonts.button)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(theme.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(theme.surface.opacity(0.5))
                    .cornerRadius(28)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(theme.primary.opacity(0.5), lineWidth: 1)
                    )
                }

            } else {
                // Close button for error state
                Button(action: onDismiss) {
                    Text("Close")
                        .font(theme.fonts.button)
                        .fontWeight(.bold)
                        .foregroundColor(theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(theme.surface.opacity(0.3))
                        .cornerRadius(28)
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

// MARK: - Card Generation View Model
class CardGenerationViewModel: ObservableObject {
    @Published var isGenerating = false
    @Published var generatedCard: UIImage? = nil
    @Published var dominantColor: Color? = nil
    @Published var error: String? = nil
    @Published var rotationAngle: Double = 0

    private let playerInfo: PlayerCardInfo
    private let jerseySelection: JerseySelection
    private let imageGenerationService: ImageGenerationService?
    private var hasStartedGeneration = false  // Guard to prevent duplicate calls

    init(playerInfo: PlayerCardInfo, jerseySelection: JerseySelection) {
        self.playerInfo = playerInfo
        self.jerseySelection = jerseySelection
        self.imageGenerationService = ImageGenerationService()

        // Start rotation animation
        DispatchQueue.main.async {
            withAnimation {
                self.rotationAngle = 360
            }
        }
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
        generatedCard = nil

        service.generateHockeyCard(
            playerInfo: playerInfo,
            jerseySelection: jerseySelection
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isGenerating = false

                switch result {
                case .success(let image):
                    self?.generatedCard = image
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
                        // Post notification to update Home View
                        NotificationCenter.default.post(name: NSNotification.Name("LatestCardUpdated"), object: nil)
                    }

                    // Persist in local history (fire-and-forget)
                    GeneratedCardsStore.shared.save(image: image)

                case .failure(let error):
                    self?.error = error.localizedDescription
                    self?.hasStartedGeneration = false  // Reset flag on error so user can retry
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

        let activityVC = UIActivityViewController(
            activityItems: [card],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}
