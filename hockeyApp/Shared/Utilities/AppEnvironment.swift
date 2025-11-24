import Foundation
#if canImport(RevenueCat)
import RevenueCat
#endif

/// Centralized environment detection for analytics, API keys, and feature flags
enum AppEnvironment {
    case debug          // Xcode debugging (Simulator or Device)
    case testFlight     // TestFlight builds
    case appStore       // Production App Store builds

    /// Current app environment
    static var current: AppEnvironment {
        #if DEBUG
        return .debug
        #else
        // Check if running from TestFlight
        if isTestFlight {
            return .testFlight
        } else {
            return .appStore
        }
        #endif
    }

    /// Check if app is running from TestFlight
    private static var isTestFlight: Bool {
        guard let appStoreReceiptURL = Bundle.main.appStoreReceiptURL else {
            return false
        }
        return appStoreReceiptURL.lastPathComponent == "sandboxReceipt"
    }

    /// Human-readable environment name
    var displayName: String {
        switch self {
        case .debug: return "Debug"
        case .testFlight: return "TestFlight"
        case .appStore: return "Production"
        }
    }

    /// Environment indicator emoji
    var emoji: String {
        switch self {
        case .debug: return "🛠️"
        case .testFlight: return "✈️"
        case .appStore: return "🚀"
        }
    }

    /// Should use production analytics
    var useProductionAnalytics: Bool {
        return self == .appStore
    }

    /// Should show debug UI elements
    var showDebugUI: Bool {
        return self == .debug
    }

    /// Analytics project suffix for separation
    var analyticsProject: String {
        switch self {
        case .debug: return "dev"
        case .testFlight: return "staging"
        case .appStore: return "prod"
        }
    }
}

// MARK: - Environment Banner (for testing visibility)
import SwiftUI

struct EnvironmentBanner: View {
    let environment = AppEnvironment.current
    @State private var isExpanded = true

    var body: some View {
        if environment != .appStore {
            VStack(spacing: 0) {
                HStack {
                    Text("\(environment.emoji) \(environment.displayName)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(bannerColor)
                        .cornerRadius(8)

                    Spacer()

                    Button(action: { isExpanded.toggle() }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(bannerColor.opacity(0.9))

                if isExpanded {
                    VStack(alignment: .leading, spacing: 4) {
                        infoRow(label: "Analytics", value: environment.analyticsProject.uppercased())
                        infoRow(label: "User ID", value: getUserIDPreview())
                    }
                    .padding(12)
                    .background(bannerColor.opacity(0.7))
                }
            }
            .transition(.move(edge: .top))
        }
    }

    private var bannerColor: Color {
        switch environment {
        case .debug: return .orange
        case .testFlight: return .blue
        case .appStore: return .green
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label + ":")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.7))
            Text(value)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
        }
    }

    private func getUserIDPreview() -> String {
        #if canImport(RevenueCat)
        let userID = Purchases.shared.appUserID
        return String(userID.prefix(12)) + "..."
        #else
        return "N/A"
        #endif
    }
}
