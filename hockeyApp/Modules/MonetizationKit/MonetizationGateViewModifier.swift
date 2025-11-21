import SwiftUI

struct MonetizationGateViewModifier: ViewModifier {
    let featureIdentifier: String
    let source: String
    @Binding var activatedProgrammatically: Bool
    let triggerId: String
    let consumeAccess: Bool
    let onAccessGranted: () -> Void
    let onDismissOrCancel: (String?) -> Void

    @State private var showPaywall = false
    @StateObject private var monetization = MonetizationManager.shared

    func body(content: Content) -> some View {
        content
            .onChange(of: activatedProgrammatically) { newValue in
                if newValue {
                    checkAccessAndShow()
                }
            }
            .onChange(of: triggerId) { _ in
                if activatedProgrammatically {
                    checkAccessAndShow()
                }
            }
            .fullScreenCover(isPresented: $showPaywall) {
                PaywallPresenter(source: source)
                    .onDisappear {
                        // Check if purchase was successful after dismissal
                        if monetization.isPremium {
                            onAccessGranted()
                        } else {
                            onDismissOrCancel(nil)
                        }
                        activatedProgrammatically = false
                    }
            }
    }

    private func checkAccessAndShow() {
        AnalyticsManager.shared.track(
            eventName: MonetizationConfig.aiAnalysisGatedEvent,
            properties: ["source": source]
        )

        if monetization.checkAccess(featureIdentifier: featureIdentifier, consumeAccess: consumeAccess) {
            onAccessGranted()
            activatedProgrammatically = false
        } else {
            showPaywall = true
        }
    }
}

extension View {
    func monetizationGate(
        featureIdentifier: String,
        source: String,
        activatedProgrammatically: Binding<Bool>,
        triggerId: String = UUID().uuidString,
        consumeAccess: Bool = true,
        onAccessGranted: @escaping () -> Void,
        onDismissOrCancel: @escaping (String?) -> Void
    ) -> some View {
        modifier(
            MonetizationGateViewModifier(
                featureIdentifier: featureIdentifier,
                source: source,
                activatedProgrammatically: activatedProgrammatically,
                triggerId: triggerId,
                consumeAccess: consumeAccess,
                onAccessGranted: onAccessGranted,
                onDismissOrCancel: onDismissOrCancel
            )
        )
    }
}
