import Foundation

/// Convenience container exposing the shared monetization manager
final class MonetizationContainer {
    static let shared = MonetizationContainer()

    let monetizationManager: MonetizationManager

    private init() {
        monetizationManager = MonetizationManager.shared
    }
}
