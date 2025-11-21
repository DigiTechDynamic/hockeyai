import SwiftUI
import Combine

// MARK: - Interactive Card Modifier
struct InteractiveCardModifier: ViewModifier {
    @State private var isPressed = false
    @State private var scale: CGFloat = 1.0
    
    let onTap: (() -> Void)?
    let hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle
    let scaleAmount: CGFloat
    let enableSound: Bool
    
    init(
        onTap: (() -> Void)? = nil,
        hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle = .light,
        scaleAmount: CGFloat = 0.96,
        enableSound: Bool = true
    ) {
        self.onTap = onTap
        self.hapticStyle = hapticStyle
        self.scaleAmount = scaleAmount
        self.enableSound = enableSound
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: scale)
            .contentShape(Rectangle())
            .onTapGesture {
                // Animate press
                withAnimation(.spring(response: 0.1, dampingFraction: 0.9)) {
                    isPressed = true
                    scale = scaleAmount
                }
                
                // Combined haptic and sound feedback
                if enableSound {
                    HapticManager.shared.playFeedback(.selection, haptic: hapticStyle)
                } else {
                    HapticManager.shared.playImpact(style: hapticStyle)
                }
                
                // Execute action
                onTap?()
                
                // Animate release with slight overshoot
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = false
                        scale = 1.0
                    }
                }
            }
    }
}

// MARK: - Sliding Tab Indicator
struct SlidingTabIndicator: View {
    @Environment(\.theme) var theme
    let selectedIndex: Int
    let tabCount: Int
    let tabWidth: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let indicatorWidth = totalWidth / CGFloat(tabCount)
            let xOffset = CGFloat(selectedIndex) * indicatorWidth
            
            Capsule()
                .fill(theme.primary)
                .frame(width: indicatorWidth - 20, height: 3)
                .offset(x: xOffset + 10)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedIndex)
        }
        .frame(height: 3)
    }
}

// MARK: - Cascading List Item Modifier
struct CascadingListItemModifier: ViewModifier {
    @State private var appeared = false
    
    let index: Int
    let totalCount: Int
    let baseDelay: Double
    let animationDuration: Double
    let slideDistance: CGFloat
    // External trigger to re-run the entrance animation without recreating the view
    let trigger: Int
    
    init(
        index: Int,
        totalCount: Int = 10,
        baseDelay: Double = 0.05,
        animationDuration: Double = 0.4,
        slideDistance: CGFloat = 30,
        trigger: Int = 0
    ) {
        self.index = index
        self.totalCount = totalCount
        self.baseDelay = baseDelay
        self.animationDuration = animationDuration
        self.slideDistance = slideDistance
        self.trigger = trigger
    }
    
    private var delay: Double {
        Double(min(index, totalCount)) * baseDelay
    }
    
    private var entranceAnimation: Animation {
        .spring(response: animationDuration, dampingFraction: 0.8).delay(delay)
    }
    
    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : slideDistance)
            .scaleEffect(appeared ? 1 : 0.95)
            .onAppear {
                // Ensure we start hidden, then animate in
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    appeared = false
                }
                withAnimation(entranceAnimation) {
                    appeared = true
                }
            }
            .onChange(of: trigger) { _ in
                // Re-run entrance animation when trigger changes, without animating the reset
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    appeared = false
                }
                withAnimation(entranceAnimation) {
                    appeared = true
                }
            }
    }
}

// MARK: - Dismissal Animation Modifier
struct DismissalAnimationModifier: ViewModifier {
    @Binding var isVisible: Bool
    let onDismiss: (() -> Void)?
    let animationStyle: DismissalStyle
    
    enum DismissalStyle {
        case scale
        case slide
        case fade
        case swipeAway
    }
    
    @State private var offset: CGSize = .zero
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0
    
    func body(content: Content) -> some View {
        if isVisible {
            content
                .offset(offset)
                .scaleEffect(scale)
                .opacity(opacity)
                .transition(dismissalTransition)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isVisible)
                .gesture(
                    animationStyle == .swipeAway ? swipeGesture : nil
                )
        }
    }
    
    private var dismissalTransition: AnyTransition {
        switch animationStyle {
        case .scale:
            return .scale(scale: 0.8).combined(with: .opacity)
        case .slide:
            return .move(edge: .trailing).combined(with: .opacity)
        case .fade:
            return .opacity
        case .swipeAway:
            return .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        }
    }
    
    private var swipeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = value.translation
                let progress = abs(value.translation.width) / 200
                scale = 1.0 - (progress * 0.2)
                opacity = 1.0 - (progress * 0.5)
            }
            .onEnded { value in
                if abs(value.translation.width) > 100 {
                    // Dismiss with animation
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        offset = CGSize(
                            width: value.translation.width > 0 ? 300 : -300,
                            height: value.translation.height
                        )
                        scale = 0.5
                        opacity = 0
                    }
                    
                    // Haptic feedback
                    HapticManager.shared.playImpact(style: .medium)
                    
                    // Update state after animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isVisible = false
                        onDismiss?()
                    }
                } else {
                    // Snap back
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        offset = .zero
                        scale = 1.0
                        opacity = 1.0
                    }
                }
            }
    }
}

// MARK: - Matched Geometry Transition Helper
struct MatchedGeometryTransition: ViewModifier {
    let id: String
    let namespace: Namespace.ID
    let isSource: Bool
    
    func body(content: Content) -> some View {
        content
            .matchedGeometryEffect(
                id: id,
                in: namespace,
                isSource: isSource
            )
    }
}

// MARK: - Tab Icon Animation
struct TabIconAnimationModifier: ViewModifier {
    let isSelected: Bool
    
    @State private var scale: CGFloat = 1.0
    @State private var rotation: Double = 0
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation))
            .onChange(of: isSelected) { newValue in
                if newValue {
                    // Animate selection
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                        scale = 1.2
                    }
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5).delay(0.1)) {
                        scale = 1.0
                    }
                    
                    // Add subtle rotation
                    withAnimation(.easeInOut(duration: 0.3)) {
                        rotation = 5
                    }
                    withAnimation(.easeInOut(duration: 0.3).delay(0.15)) {
                        rotation = 0
                    }
                }
            }
    }
}

// MARK: - Completion Celebration Animation
struct CompletionCelebrationModifier: ViewModifier {
    @Binding var trigger: Bool
    let onComplete: (() -> Void)?
    
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0
    @State private var checkmarkScale: CGFloat = 0.0
    @State private var particleScale: CGFloat = 0.0
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .scaleEffect(scale)
                .opacity(opacity)
            
            if trigger {
                // Checkmark overlay
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                    .scaleEffect(checkmarkScale)
                    .opacity(checkmarkScale > 0 ? 1 : 0)
                
                // Particle effects
                ForEach(0..<8, id: \.self) { index in
                    Circle()
                        .fill(Color.green.opacity(0.6))
                        .frame(width: 10, height: 10)
                        .scaleEffect(particleScale)
                        .offset(
                            x: cos(CGFloat(index) * .pi / 4) * 100 * particleScale,
                            y: sin(CGFloat(index) * .pi / 4) * 100 * particleScale
                        )
                        .opacity(1.0 - particleScale)
                }
            }
        }
        .onChange(of: trigger) { newValue in
            if newValue {
                performCelebration()
            }
        }
    }
    
    private func performCelebration() {
        // Scale up content
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            scale = 1.1
        }
        
        // Show checkmark
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.1)) {
            checkmarkScale = 1.0
        }
        
        // Particle explosion
        withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
            particleScale = 1.0
        }
        
        // Fade out
        withAnimation(.easeInOut(duration: 0.5).delay(0.8)) {
            opacity = 0
            checkmarkScale = 0
        }
        
        // Haptic feedback
        HapticManager.shared.playNotification(type: .success)
        
        // Call completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            trigger = false
            onComplete?()
        }
    }
}

// MARK: - View Extensions
extension View {
    func interactiveCard(
        onTap: (() -> Void)? = nil,
        hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle = .light,
        scaleAmount: CGFloat = 0.96,
        enableSound: Bool = true
    ) -> some View {
        self.modifier(InteractiveCardModifier(
            onTap: onTap,
            hapticStyle: hapticStyle,
            scaleAmount: scaleAmount,
            enableSound: enableSound
        ))
    }
    
    func cascadingListItem(
        index: Int,
        totalCount: Int = 10,
        baseDelay: Double = 0.05,
        animationDuration: Double = 0.4,
        slideDistance: CGFloat = 30,
        trigger: Int = 0
    ) -> some View {
        self.modifier(CascadingListItemModifier(
            index: index,
            totalCount: totalCount,
            baseDelay: baseDelay,
            animationDuration: animationDuration,
            slideDistance: slideDistance,
            trigger: trigger
        ))
    }
    
    func dismissalAnimation(
        isVisible: Binding<Bool>,
        style: DismissalAnimationModifier.DismissalStyle = .scale,
        onDismiss: (() -> Void)? = nil
    ) -> some View {
        self.modifier(DismissalAnimationModifier(
            isVisible: isVisible,
            onDismiss: onDismiss,
            animationStyle: style
        ))
    }
    
    func tabIconAnimation(isSelected: Bool) -> some View {
        self.modifier(TabIconAnimationModifier(isSelected: isSelected))
    }
    
    func completionCelebration(
        trigger: Binding<Bool>,
        onComplete: (() -> Void)? = nil
    ) -> some View {
        self.modifier(CompletionCelebrationModifier(
            trigger: trigger,
            onComplete: onComplete
        ))
    }
    
    func matchedGeometryTransition(
        id: String,
        namespace: Namespace.ID,
        isSource: Bool = true
    ) -> some View {
        self.modifier(MatchedGeometryTransition(
            id: id,
            namespace: namespace,
            isSource: isSource
        ))
    }
}

// MARK: - Entrance Animation Trigger Environment
private struct EntranceAnimationTriggerKey: EnvironmentKey {
    static let defaultValue: Int = 0
}

extension EnvironmentValues {
    var entranceAnimationTrigger: Int {
        get { self[EntranceAnimationTriggerKey.self] }
        set { self[EntranceAnimationTriggerKey.self] = newValue }
    }
}
