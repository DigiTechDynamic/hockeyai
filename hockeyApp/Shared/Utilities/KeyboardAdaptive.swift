import SwiftUI
import Combine

// MARK: - Keyboard Observer
final class KeyboardObserver: ObservableObject {
    @Published var keyboardHeight: CGFloat = 0
    private var cancellables = Set<AnyCancellable>()

    init() {
        let willShow = NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect }
            .map { $0.height }

        let willHide = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ in CGFloat(0) }

        Publishers.Merge(willShow, willHide)
            .receive(on: RunLoop.main)
            .assign(to: &$keyboardHeight)
    }
}

// MARK: - Keyboard Adaptive Modifier
struct KeyboardAdaptive: ViewModifier {
    @StateObject private var keyboard = KeyboardObserver()
    var extraPadding: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(.bottom, bottomPadding())
            .animation(.easeInOut(duration: 0.25), value: keyboard.keyboardHeight)
    }

    private func bottomPadding() -> CGFloat {
        guard keyboard.keyboardHeight > 0 else { return 0 }
        // Small extra to ensure target view clears the keyboard reliably
        return keyboard.keyboardHeight + extraPadding
    }
}

extension View {
    func keyboardAdaptive(extraPadding: CGFloat = AppSettings.Constants.Spacing.keyboardOffset) -> some View {
        modifier(KeyboardAdaptive(extraPadding: extraPadding))
    }
}

