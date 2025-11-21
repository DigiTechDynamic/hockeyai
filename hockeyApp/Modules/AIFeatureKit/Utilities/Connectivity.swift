import Foundation
import Network

// MARK: - Connectivity
/// Lightweight network connectivity monitor for detecting cellular vs Wi‑Fi.
/// Start it early (e.g., on first use) and query `isCellular`/`isExpensive`.
final class Connectivity {
    static let shared = Connectivity()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "ConnectivityMonitorQueue")

    private(set) var isCellular: Bool = false
    private(set) var isConstrained: Bool = false
    private(set) var isExpensive: Bool = false
    private(set) var hasFirstUpdate: Bool = false
    private var started = false

    func start() {
        guard !started else { return }
        started = true
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            self.isConstrained = path.isConstrained
            self.isExpensive = path.isExpensive
            // Cellular detection
            var onCellular = false
            if path.usesInterfaceType(.cellular) { onCellular = true }
            self.isCellular = onCellular
            self.hasFirstUpdate = true

            #if DEBUG
            print("[Connectivity] path update -> isCellular=\(self.isCellular) isExpensive=\(self.isExpensive) isConstrained=\(self.isConstrained)")
            #endif

            NotificationCenter.default.post(name: .connectivityDidChange, object: nil)
        }
        monitor.start(queue: queue)
    }

    func stop() {
        monitor.cancel()
    }
}

extension Notification.Name {
    static let connectivityDidChange = Notification.Name("ConnectivityDidChange")
}
