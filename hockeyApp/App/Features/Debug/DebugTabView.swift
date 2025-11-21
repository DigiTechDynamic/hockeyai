import SwiftUI

struct DebugTabView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.theme) var theme
    @State private var selectedTab: DebugTab = .notification

    private enum DebugTab: String, CaseIterable, Identifiable {
        case notification = "NotificationKit"
        case monetization = "MonetizationKit"
        case ai = "AIFeatureKit"
        case analytics = "AnalyticsKit"

        var id: String { rawValue }
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Dark background
                Color.black
                    .ignoresSafeArea()
                VStack(spacing: 20) {
                    Picker("Debug Tab", selection: $selectedTab) {
                        ForEach(DebugTab.allCases) { tab in
                            Text(tab.rawValue)
                                .tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)

                    Group {
                        switch selectedTab {
                        case .notification:
                            NotificationKitSection()
                        case .monetization:
                            MonetizationKitDebugSection()
                        case .ai:
                            AIFeatureKitSection()
                        case .analytics:
                            AnalyticsKitSection()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
                .padding(.top, 20)
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(theme.primary)
                }
            }
        }
        .preferredColorScheme(.dark)
        // Deep link presentation is centralized in ContentView.
    }
}

private extension DebugTabView {
    var navigationTitle: String {
        switch selectedTab {
        case .notification: return "🔔 NotificationKit"
        case .monetization: return "💰 MonetizationKit"
        case .ai: return "🤖 AIFeatureKit"
        case .analytics: return "📈 AnalyticsKit"
        }
    }
}

#Preview {
    DebugTabView()
        .preferredColorScheme(.dark)
}
