import Foundation

// MARK: - AIFeatureKit UX Hooks
/// App layer can assign UI hooks here so the AI layer can remain UI-agnostic.
public enum AIUXHooks {
    /// Called before starting a potentially heavy AI network operation when on cellular/expensive networks.
    /// Should present a brief notice and return when the user dismisses it.
    public static var preflightCellularNotice: (() async -> Void)?
}

