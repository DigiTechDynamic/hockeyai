import SwiftUI

// MARK: - Loading View Style
enum LoadingViewStyle {
    case simple
    case detailed(tips: [LoadingTip])
    case ai
    
    struct LoadingTip {
        let text: String
        let category: String
        let icon: String?
        
        init(_ text: String, category: String, icon: String? = nil) {
            self.text = text
            self.category = category
            self.icon = icon
        }
    }
}

// MARK: - Unified Loading View
struct UnifiedLoadingView: View {
    @Environment(\.theme) var theme
    @State private var isAnimating = false
    @State private var currentTipIndex = 0
    @State private var tipOpacity = 1.0
    
    let message: String
    let style: LoadingViewStyle
    let showOverlay: Bool
    
    // Timer for cycling tips
    @State private var tipTimer: Timer?
    
    init(
        message: String = "Loading...",
        style: LoadingViewStyle = .simple,
        showOverlay: Bool = true
    ) {
        self.message = message
        self.style = style
        self.showOverlay = showOverlay
    }
    
    var body: some View {
        ZStack {
            if showOverlay {
                theme.background.opacity(AppSettings.Constants.Opacity.heavy)
                    .ignoresSafeArea()
            }
            
            VStack(spacing: theme.spacing.xxl) {
                // Loading animation
                loadingAnimation
                
                // Message
                Text(message)
                    .font(theme.fonts.headline)
                    .foregroundColor(theme.text)
                    .multilineTextAlignment(.center)
                
                // Additional content based on style
                additionalContent
            }
            .padding(theme.spacing.xxl)
            .background(backgroundView)
        }
        .onAppear {
            startAnimations()
        }
        .onDisappear {
            stopAnimations()
        }
    }
    
    // MARK: - Loading Animation
    @ViewBuilder
    private var loadingAnimation: some View {
        switch style {
        case .simple:
            simpleLoadingAnimation
        case .detailed:
            detailedLoadingAnimation
        case .ai:
            aiLoadingAnimation
        }
    }
    
    private var simpleLoadingAnimation: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: theme.primary))
            .scaleEffect(1.5)
    }
    
    private var detailedLoadingAnimation: some View {
        ZStack {
            Circle()
                .stroke(theme.divider, lineWidth: 3)
                .frame(width: AppSettings.Constants.Sizing.buttonMedium, height: AppSettings.Constants.Sizing.buttonMedium)
            
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(theme.primary, lineWidth: 3)
                .frame(width: AppSettings.Constants.Sizing.buttonMedium, height: AppSettings.Constants.Sizing.buttonMedium)
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(.linear(duration: AppSettings.Constants.Animation.slow).repeatForever(autoreverses: false), value: isAnimating)
        }
    }
    
    private var aiLoadingAnimation: some View {
        ZStack {
            // Animated rings
            ForEach(0..<3) { index in
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [theme.primary, theme.secondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(
                        width: AppSettings.Constants.Sizing.buttonMedium + CGFloat(index * 30),
                        height: AppSettings.Constants.Sizing.buttonMedium + CGFloat(index * 30)
                    )
                    .opacity(isAnimating ? AppSettings.Constants.Opacity.light : AppSettings.Constants.Opacity.heavy)
                    .scaleEffect(isAnimating ? 1.2 : 0.8)
                    .animation(
                        Animation.easeInOut(duration: AppSettings.Constants.Animation.glacial)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                        value: isAnimating
                    )
            }
            
            // Center icon
            Image(systemName: "wand.and.stars")
                .font(.system(size: AppSettings.Constants.Typography.display))
                .foregroundColor(theme.primary)
                .symbolEffect(.pulse.wholeSymbol, options: .repeating, value: isAnimating)
        }
    }
    
    // MARK: - Additional Content
    @ViewBuilder
    private var additionalContent: some View {
        switch style {
        case .simple:
            EmptyView()
            
        case .detailed(let tips):
            if !tips.isEmpty {
                VStack(spacing: theme.spacing.sm) {
                    if let currentTip = tips[safe: currentTipIndex] {
                        HStack(spacing: theme.spacing.xs) {
                            if let icon = currentTip.icon {
                                Text(icon)
                                    .font(.system(size: AppSettings.Constants.Typography.small))
                            }
                            Text(currentTip.category)
                                .font(theme.fonts.caption)
                                .foregroundColor(theme.primary)
                        }
                        
                        Text(currentTip.text)
                            .font(theme.fonts.body)
                            .foregroundColor(theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .opacity(tipOpacity)
                .animation(.easeInOut(duration: AppSettings.Constants.Animation.medium), value: tipOpacity)
            }
            
        case .ai:
            VStack(spacing: theme.spacing.xs) {
                Text("AI PROCESSING")
                    .font(.system(size: AppSettings.Constants.Typography.tiny, weight: .bold))
                    .foregroundColor(theme.primary)
                    .tracking(2)
                
                Text("This may take a moment...")
                    .font(theme.fonts.caption)
                    .foregroundColor(theme.textSecondary)
            }
        }
    }
    
    // MARK: - Background View
    @ViewBuilder
    private var backgroundView: some View {
        if showOverlay {
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .fill(theme.cardBackground)
                .shadow(
                    color: theme.background.opacity(AppSettings.Constants.Opacity.light),
                    radius: AppSettings.Constants.Layout.shadowRadiusLarge
                )
        } else {
            EmptyView()
        }
    }
    
    // MARK: - Animation Control
    private func startAnimations() {
        isAnimating = true
        
        // Start tip cycling for detailed style
        if case .detailed(let tips) = style, !tips.isEmpty {
            tipTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
                withAnimation(.easeOut(duration: AppSettings.Constants.Animation.quick)) {
                    tipOpacity = 0
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + AppSettings.Constants.Animation.quick) {
                    currentTipIndex = (currentTipIndex + 1) % tips.count
                    withAnimation(.easeIn(duration: AppSettings.Constants.Animation.quick)) {
                        tipOpacity = 1
                    }
                }
            }
        }
    }
    
    private func stopAnimations() {
        isAnimating = false
        tipTimer?.invalidate()
        tipTimer = nil
    }
}

// MARK: - Convenience Initializers
extension UnifiedLoadingView {
    /// Simple loading indicator
    static func simple(_ message: String = "Loading...") -> UnifiedLoadingView {
        UnifiedLoadingView(message: message, style: .simple)
    }
    
    /// AI processing indicator
    static func ai(_ message: String = "Processing with AI...") -> UnifiedLoadingView {
        UnifiedLoadingView(message: message, style: .ai)
    }
    
    /// Detailed loading with tips
    static func detailed(_ message: String, tips: [LoadingViewStyle.LoadingTip]) -> UnifiedLoadingView {
        UnifiedLoadingView(message: message, style: .detailed(tips: tips))
    }
}

// MARK: - Hockey Tips
extension LoadingViewStyle.LoadingTip {
    static let hockeyTips = [
        LoadingViewStyle.LoadingTip("Keep your top hand away from your body for better puck control", category: "Pro Tip", icon: "💡"),
        LoadingViewStyle.LoadingTip("Flex your stick 1-2 inches when shooting for maximum power", category: "Technique", icon: "🏒"),
        LoadingViewStyle.LoadingTip("Keep your knees bent and head up when skating backwards", category: "Skating", icon: "⛸️"),
        LoadingViewStyle.LoadingTip("Use the heel of your blade for better backhand control", category: "Stickhandling", icon: "🎯"),
        LoadingViewStyle.LoadingTip("Roll your wrists at the end of your shot for accuracy", category: "Shooting", icon: "🎯")
    ]
}

// MARK: - Safe Array Access
private extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}

// MARK: - Preview
#if DEBUG
struct UnifiedLoadingView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            // Simple
            UnifiedLoadingView.simple("Loading data...")
                .frame(height: 200)
            
            // AI
            UnifiedLoadingView.ai("Analyzing your performance...")
                .frame(height: 300)
            
            // Detailed with tips
            UnifiedLoadingView.detailed(
                "Preparing your analysis...",
                tips: LoadingViewStyle.LoadingTip.hockeyTips
            )
            .frame(height: 300)
        }
        .padding()
    }
}
#endif