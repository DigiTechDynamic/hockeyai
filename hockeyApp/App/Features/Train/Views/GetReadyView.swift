import SwiftUI
import AVFoundation

/// Research-based Get Ready countdown screen
/// Design based on comprehensive fitness app UX research and sports psychology
struct GetReadyView: View {
    @Environment(\.theme) var theme

    let exercise: Exercise
    let timeRemaining: TimeInterval
    let totalDuration: TimeInterval
    let elapsedTime: TimeInterval
    let currentExercise: Int
    let totalExercises: Int
    let isPaused: Bool
    let onPauseToggle: () -> Void
    let onClose: () -> Void

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var pulseAnimation = false
    @State private var previousTime: Int = 11

    var body: some View {
        VStack(spacing: 0) {
            // Top Bar (matching other workout screens)
            WorkoutTopBar(
                elapsedTime: elapsedTime,
                currentExercise: currentExercise + 1,
                totalExercises: totalExercises,
                isPaused: isPaused,
                onPauseToggle: onPauseToggle,
                onClose: onClose,
                showExerciseCounter: false  // Hide counter during GetReady
            )

            ZStack {
                // Pure black background (athletic/focused)
                theme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer(minLength: 36)

                    // Check → Arrow animation to signal next page
                    CheckToArrowAnimation()
                        .frame(height: 180)
                        .opacity(opacity)

                    // Main title (uppercase, gradient, tracking)
                    Text("GET READY")
                        .font(.system(size: 38, weight: .black))
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
                        .shadow(color: Color.white.opacity(0.5), radius: 0)
                        .shadow(color: Color.white.opacity(0.3), radius: 4)
                        .shadow(color: theme.primary.opacity(0.4), radius: 10)
                        .tracking(3)
                        .padding(.top, 8)
                        .opacity(opacity)

                    // Subtitle (exercise name, uppercase, subtle gray)
                    Text(exercise.name.uppercased())
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundColor(theme.textSecondary)
                        .tracking(3)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 24)
                        .padding(.top, 6)
                        .opacity(0.9 * opacity)

                    // Countdown Number - bold, gradient (TimerCard style)
                    Text("\(Int(timeRemaining))")
                        .font(.system(size: 80, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.white, Color.white.opacity(0.85)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: theme.primary.opacity(0.5), radius: 20)
                        .monospacedDigit()
                        .scaleEffect(scale)
                        .contentTransition(.numericText())
                        .padding(.top, 18)
                        .opacity(opacity)

                    // Dots indicator (visual balance)
                    ValidationDotsIndicator(theme: theme)
                        .padding(.top, 18)
                        .opacity(opacity)

                    Spacer(minLength: 40)
                }
            }
        }
        .background(theme.background)
        .onAppear {
            // Entrance animation
            withAnimation(.spring(duration: 0.6, bounce: 0.4)) {
                opacity = 1.0
                scale = 1.0
            }

            // Start pulse animation
            pulseAnimation = true

            // Simple haptic on entrance
            HapticManager.shared.playImpact(style: .light)
        }
        .onChange(of: Int(timeRemaining)) { oldValue, newValue in
            // Animate number change with bounce
            animateNumberChange(for: newValue)
        }
        .trackScreen("workout_get_ready")
    }

    // MARK: - Computed Properties

    /// Next exercise in workout (for preview)
    private var nextExercise: Exercise? {
        let nextIndex = currentExercise + 1
        guard nextIndex < totalExercises else { return nil }
        // We don't have access to the workout here, so we'll skip this for now
        return nil
    }

    /// Single color for countdown
    private var countdownColor: Color {
        return theme.primary // Just use theme green
    }

    // MARK: - Animations

    private func animateNumberChange(for number: Int) {
        guard number != previousTime else { return }
        previousTime = number

        // Bounce animation (research-recommended: 0.4s duration, 0.6 bounce)
        withAnimation(.spring(duration: 0.4, bounce: 0.6)) {
            scale = 1.2  // Overshoot
        }

        // Settle back to normal
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(duration: 0.25, bounce: 0.3)) {
                scale = 1.0  // Settle
            }
        }

        // Play sound for this number
        playCountdownSound(for: number)

        // Haptic feedback (heavier as countdown progresses)
        triggerHaptic(for: number)
    }

    // MARK: - Sound Effects

    private func playCountdownSound(for number: Int) {
        // Route through unified SoundManager for consistency
        SoundManager.shared.playSound(.workoutTick)
    }

    // MARK: - Haptic Feedback

    private func triggerHaptic(for number: Int) {
        // Simple light haptic on each tick
        HapticManager.shared.playImpact(style: .light)
    }
}

// MARK: - Check → Arrow Animation
private struct CheckToArrowAnimation: View {
    @Environment(\.theme) var theme

    @State private var isArrow = false
    @State private var rotation: Double = 0
    @State private var arrowOffset: CGFloat = 0
    @State private var pulse = false

    var body: some View {
        ZStack {
            // Soft background glow
            Circle()
                .fill(theme.primary)
                .frame(width: 160, height: 160)
                .blur(radius: 40)
                .opacity(pulse ? 0.35 : 0.18)
                .scaleEffect(pulse ? 1.12 : 0.95)
                .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: pulse)

            // Icon layer
            Group {
                if !isArrow {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 72, weight: .bold))
                        .foregroundColor(theme.primary)
                        .rotationEffect(.degrees(rotation))
                        .shadow(color: theme.primary.opacity(0.7), radius: 4)
                        .shadow(color: theme.primary.opacity(0.4), radius: 10)
                } else {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 72, weight: .bold))
                        .foregroundColor(theme.primary)
                        .offset(x: arrowOffset)
                        .shadow(color: theme.primary.opacity(0.7), radius: 4)
                        .shadow(color: theme.primary.opacity(0.4), radius: 10)
                        .transition(.opacity.combined(with: .scale))
                }
            }
        }
        .onAppear {
            pulse = true
            startSequence()
        }
    }

    private func startSequence() {
        // 1) Spin the checkmark
        withAnimation(.easeInOut(duration: 0.6)) {
            rotation = 360
        }

        // 2) Swap to arrow and slide it right
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            rotation = 0
            withAnimation(.easeInOut(duration: 0.35)) {
                isArrow = true
            }
            withAnimation(.easeInOut(duration: 0.8)) {
                arrowOffset = 20
            }

            // 3) Return arrow, then reset to check and repeat
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeInOut(duration: 0.35)) {
                    arrowOffset = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        isArrow = false
                    }
                    rotation = 0
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        startSequence()
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    GetReadyView(
        exercise: Exercise(
            name: "Slap Shot from Behind",
            description: "Practice slap shots from the blue line",
            category: .shooting,
            config: .repsSets(reps: 10, sets: 3),
            equipment: [.stick, .pucks, .net]
        ),
        timeRemaining: 8,
        totalDuration: 10,
        elapsedTime: 0,
        currentExercise: 0,
        totalExercises: 6,
        isPaused: false,
        onPauseToggle: {},
        onClose: {}
    )
}
