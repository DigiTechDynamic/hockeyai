import SwiftUI

// MARK: - Background Animation Types
enum BackgroundAnimationType: String, CaseIterable {
    case particles = "particles"
    case fireGradient = "fireGradient" 
    case energyWaves = "energyWaves"
    case none = "none"
    
    var displayName: String {
        switch self {
        case .particles: return "Fire Particles"
        case .fireGradient: return "Animated Gradient"
        case .energyWaves: return "Energy Waves"
        case .none: return "None"
        }
    }
}

// MARK: - Main Background Animation View
struct BackgroundAnimationView: View {
    @Environment(\.theme) var theme
    
    let animationType: BackgroundAnimationType
    let isActive: Bool
    let intensity: Double // 0.0 to 1.0
    
    init(
        type: BackgroundAnimationType = .particles,
        isActive: Bool = true,
        intensity: Double = 0.6
    ) {
        self.animationType = type
        self.isActive = isActive
        self.intensity = intensity
    }
    
    var body: some View {
        Group {
            if isActive {
                switch animationType {
                case .particles:
                    FireParticleEffect(theme: theme, intensity: intensity)
                case .fireGradient:
                    AnimatedGradientEffect(theme: theme, intensity: intensity)
                case .energyWaves:
                    EnergyWaveEffect(theme: theme, intensity: intensity)
                case .none:
                    EmptyView()
                }
            }
        }
        .allowsHitTesting(false)
        .clipped()
    }
}

// MARK: - Fire Particle Effect (Primary "Fire" Animation)
struct FireParticleEffect: View {
    let theme: AppTheme
    let intensity: Double
    
    @State private var particles: [FireParticle] = []
    @State private var animationPhase: Double = 0
    
    private let particleCount: Int
    private let baseColors: [Color]
    
    init(theme: AppTheme, intensity: Double) {
        self.theme = theme
        self.intensity = intensity
        self.particleCount = Int(40 * intensity) + 20 // 20-60 particles for visibility
        
        // High contrast fire colors that show against green background
        self.baseColors = [
            .orange,
            .red,
            .yellow,
            .white.opacity(0.9),
            theme.primary,
            .pink.opacity(0.8)
        ]
    }
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                ParticleView(particle: particle, phase: animationPhase)
            }
        }
        .onAppear {
            generateParticles()
            startAnimation()
        }
        .onChange(of: intensity) { _ in
            generateParticles()
        }
    }
    
    private func generateParticles() {
        particles = (0..<particleCount).map { index in
            FireParticle(
                id: index,
                startX: CGFloat.random(in: -50...50),
                startY: CGFloat.random(in: 100...300),
                color: baseColors.randomElement() ?? theme.primary,
                scale: CGFloat.random(in: 0.3...0.8) * intensity,
                speed: Double.random(in: 0.5...1.2) * intensity,
                wobble: Double.random(in: 0.8...1.5)
            )
        }
    }
    
    private func startAnimation() {
        withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
            animationPhase = 360
        }
    }
}

// MARK: - Fire Particle Model
struct FireParticle: Identifiable {
    let id: Int
    let startX: CGFloat
    let startY: CGFloat  
    let color: Color
    let scale: CGFloat
    let speed: Double
    let wobble: Double
}

// MARK: - Individual Particle View
struct ParticleView: View {
    let particle: FireParticle
    let phase: Double
    
    @State private var opacity: Double = 0
    
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        particle.color,
                        particle.color.opacity(0.6),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 10
                )
            )
            .frame(width: 16 * particle.scale, height: 16 * particle.scale)
            .scaleEffect(
                1.0 + sin(phase * particle.wobble * .pi / 180) * 0.3
            )
            .offset(
                x: particle.startX + sin(phase * 0.02) * 20,
                y: particle.startY - (phase * particle.speed * 2)
            )
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: 0.5)) {
                    opacity = 1.0
                }
                
                // Fade particles that move too far
                withAnimation(.easeOut(duration: 1.0).delay(2.0)) {
                    if phase > 180 {
                        opacity = 0.0
                    }
                }
            }
    }
}

// MARK: - Animated Gradient Effect (Fallback)
struct AnimatedGradientEffect: View {
    let theme: AppTheme
    let intensity: Double
    
    @State private var gradientPhase: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    theme.primary.opacity(0.3 * intensity),
                    theme.accent.opacity(0.2 * intensity),
                    theme.primary.opacity(0.1 * intensity),
                    Color.clear
                ],
                startPoint: .bottom,
                endPoint: .top
            )
            .hueRotation(.degrees(gradientPhase))
            
            // Pulsing overlay
            RadialGradient(
                colors: [
                    theme.primary.opacity(0.1 * intensity),
                    Color.clear
                ],
                center: .center,
                startRadius: 50,
                endRadius: 200
            )
            .scaleEffect(pulseScale)
        }
        .onAppear {
            withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false)) {
                gradientPhase = 360
            }
            
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                pulseScale = 1.5
            }
        }
    }
}

// MARK: - Energy Wave Effect
struct EnergyWaveEffect: View {
    let theme: AppTheme
    let intensity: Double
    
    @State private var wavePhase: Double = 0
    @State private var waveAmplitude: CGFloat = 0
    
    var body: some View {
        ZStack {
            ForEach(0..<3) { index in
                BackgroundWaveShape(
                    phase: wavePhase + Double(index) * 120,
                    amplitude: waveAmplitude * intensity
                )
                .stroke(
                    LinearGradient(
                        colors: [
                            theme.primary.opacity(0.6 * intensity),
                            theme.accent.opacity(0.3 * intensity),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 2
                )
                .opacity(0.8 - Double(index) * 0.2)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
                wavePhase = 360
            }
            
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                waveAmplitude = 50
            }
        }
    }
}

// MARK: - Background Wave Shape
struct BackgroundWaveShape: Shape {
    let phase: Double
    let amplitude: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midHeight = height / 2
        
        path.move(to: CGPoint(x: 0, y: midHeight))
        
        for x in stride(from: 0, through: width, by: 2) {
            let relativeX = x / width
            let sine = sin((relativeX * 4 * .pi) + (phase * .pi / 180))
            let y = midHeight + sine * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        return path
    }
}

// MARK: - Convenience Extensions
extension View {
    func withFireBackground(
        type: BackgroundAnimationType = .particles,
        isActive: Bool = true,
        intensity: Double = 0.6
    ) -> some View {
        ZStack {
            BackgroundAnimationView(
                type: type,
                isActive: isActive,
                intensity: intensity
            )
            
            self
        }
    }
}