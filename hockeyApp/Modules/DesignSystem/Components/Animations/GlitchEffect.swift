import SwiftUI

struct GlitchEffect: ViewModifier {
    @State private var offset1: CGFloat = 0
    @State private var offset2: CGFloat = 0
    @State private var offset3: CGFloat = 0
    @State private var colorShift: Double = 0
    
    let intensity: CGFloat
    let isActive: Bool
    
    func body(content: Content) -> some View {
        ZStack {
            if isActive {
                // Red Channel
                content
                    .foregroundColor(.red)
                    .offset(x: offset1, y: offset3)
                    .opacity(0.5)
                    .blendMode(.screen)
                
                // Blue Channel
                content
                    .foregroundColor(.blue)
                    .offset(x: offset2, y: -offset3)
                    .opacity(0.5)
                    .blendMode(.screen)
                
                // Green Channel (Main)
                content
                    .foregroundColor(.green)
                    .offset(x: -offset1, y: -offset2)
                    .opacity(0.5)
                    .blendMode(.screen)
            }
            
            // Original Content
            content
        }
        .onAppear {
            if isActive {
                startGlitch()
            }
        }
    }
    
    private func startGlitch() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if Double.random(in: 0...1) > 0.8 {
                withAnimation(.easeInOut(duration: 0.05)) {
                    offset1 = CGFloat.random(in: -intensity...intensity)
                    offset2 = CGFloat.random(in: -intensity...intensity)
                    offset3 = CGFloat.random(in: -intensity...intensity)
                }
                
                // Reset quickly
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    offset1 = 0
                    offset2 = 0
                    offset3 = 0
                }
            }
        }
    }
}

extension View {
    func glitchEffect(isActive: Bool = true, intensity: CGFloat = 5.0) -> some View {
        modifier(GlitchEffect(intensity: intensity, isActive: isActive))
    }
}
