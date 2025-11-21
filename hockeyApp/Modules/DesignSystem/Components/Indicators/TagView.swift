import SwiftUI

struct TagView: View {
    let text: String
    let color: Color
    @Environment(\.theme) var theme
    
    init(_ text: String, color: Color? = nil) {
        self.text = text
        self.color = color ?? Color.blue // Default fallback
    }
    
    var body: some View {
        Text(text)
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(color)
            )
    }
}

// MARK: - Convenience Initializers
extension TagView {
    static func ai() -> TagView {
        TagView("AI", color: .blue)
    }
    
    static func test() -> TagView {
        TagView("TEST", color: .orange)
    }
    
    static func beta() -> TagView {
        TagView("BETA", color: .purple)
    }
    
    static func new() -> TagView {
        TagView("NEW", color: .green)
    }
}

#Preview {
    VStack(spacing: 10) {
        TagView.ai()
        TagView.test()
        TagView.beta()
        TagView.new()
        TagView("CUSTOM", color: .red)
    }
    .padding()
    .environmentObject(ThemeManager.shared)
}