import Foundation
import SwiftUI

// MARK: - NoticeCenter
@MainActor
final class NoticeCenter: ObservableObject {
    static let shared = NoticeCenter()

    // Presentation state
    @Published var showCellularNotice: Bool = false

    // Continuations to resume when user dismisses (handles concurrent callers)
    private var dismissalContinuations: [CheckedContinuation<Void, Never>] = []

    func presentCellularNotice() async {
        #if DEBUG
        print("[NoticeCenter] presentCellularNotice() called")
        #endif
        // Show if not already visible
        if showCellularNotice == false {
            showCellularNotice = true
            #if DEBUG
            print("[NoticeCenter] showCellularNotice = true")
            #endif
        }
        // Wait until dismissed
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            dismissalContinuations.append(cont)
        }
    }

    func dismissCellularNotice() {
        #if DEBUG
        print("[NoticeCenter] dismissCellularNotice() called")
        #endif
        showCellularNotice = false
        // Resume all waiters
        let continuations = dismissalContinuations
        dismissalContinuations.removeAll()
        continuations.forEach { $0.resume() }
    }
}
