import Foundation

// MARK: - AI Network Preflight
enum AINetworkPreflight {
    /// Non-blocking: shows a cellular/expensive network notice via UI hook if needed.
    /// If connectivity status hasn't reported yet, re-check after a short delay.
    static func showCellularNoticeIfNeeded() {
        Connectivity.shared.start()

        func triggerIfNeeded() async {
            let onCellular = Connectivity.shared.isCellular || Connectivity.shared.isExpensive || Connectivity.shared.isConstrained
            #if DEBUG
            print("[AINetworkPreflight] onCellular=\(onCellular), isCellular=\(Connectivity.shared.isCellular), isExpensive=\(Connectivity.shared.isExpensive), isConstrained=\(Connectivity.shared.isConstrained)")
            #endif
            guard onCellular, let hook = AIUXHooks.preflightCellularNotice else { return }
            await hook() // MainActor in hook; non-blocking for caller because we run inside Task
        }

        if Connectivity.shared.hasFirstUpdate {
            #if DEBUG
            print("[AINetworkPreflight] Immediate connectivity status available. Triggering check now.")
            #endif
            Task { await triggerIfNeeded() }
        } else {
            #if DEBUG
            print("[AINetworkPreflight] No initial connectivity status yet. Rechecking after 300ms...")
            #endif
            Task {
                // Give NWPathMonitor a moment to deliver the first path
                try? await Task.sleep(nanoseconds: 300_000_000)
                await triggerIfNeeded()
            }
        }
    }
}
