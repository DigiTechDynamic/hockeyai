import SwiftUI

/// A reusable typewriter text effect with optional haptic ticks.
struct TypewriterText: View {
    let text: String
    let characterDelay: Double
    let startDelay: Double
    let hapticsEnabled: Bool
    let hapticEvery: Int
    let onComplete: (() -> Void)?

    @State private var displayed: String = ""
    @State private var isTyping = false

    init(
        _ text: String,
        characterDelay: Double = 0.04,
        startDelay: Double = 0.0,
        hapticsEnabled: Bool = true,
        hapticEvery: Int = 2,
        onComplete: (() -> Void)? = nil
    ) {
        self.text = text
        self.characterDelay = characterDelay
        self.startDelay = startDelay
        self.hapticsEnabled = hapticsEnabled
        self.hapticEvery = max(1, hapticEvery)
        self.onComplete = onComplete
    }

    var body: some View {
        Text(displayed)
            .textSelection(.disabled)
            .onAppear(perform: startTyping)
    }

    private func startTyping() {
        guard !isTyping else { return }
        isTyping = true

        Task { @MainActor in
            if startDelay > 0 {
                try? await Task.sleep(nanoseconds: UInt64(startDelay * 1_000_000_000))
            }

            displayed = ""
            var idx = 0
            for ch in text {
                displayed.append(ch)

                if hapticsEnabled, idx % hapticEvery == 0, !ch.isWhitespace {
                    // Subtle selection tick to avoid overwhelming feedback
                    HapticManager.shared.playSelection()
                }

                idx += 1
                try? await Task.sleep(nanoseconds: UInt64(characterDelay * 1_000_000_000))
            }

            onComplete?()
        }
    }
}

private extension Character {
    var isWhitespace: Bool {
        unicodeScalars.allSatisfy { CharacterSet.whitespacesAndNewlines.contains($0) }
    }
}

