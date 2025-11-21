import SwiftUI
import RevenueCat

struct MonetizationKitDebugSection: View {
    @Environment(\.theme) private var theme
    @ObservedObject private var monetization = MonetizationManager.shared

    @State private var selectedVariant: String = MonetizationConfig.selectedPaywallVariant
    @State private var selectedSourceOption: String = MonetizationDebugData.defaultSource
    @State private var customSource: String = ""
    @State private var showPreview = false
    @State private var isResettingUser = false
    @State private var statusMessage: String?
    @State private var statusColor: Color = .green
    @State private var statusDismissWorkItem: DispatchWorkItem?

    private var effectiveSource: String {
        if selectedSourceOption == MonetizationDebugData.customOptionToken {
            return customSource.isEmpty ? MonetizationDebugData.fallbackSource : customSource
        }
        return selectedSourceOption
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("MonetizationKit Debug")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal)
                        .padding(.top)

                    variantCard
                        .padding(.horizontal)

                    // Removed config and runtime cards to simplify the debug UI

                    actionsCard
                        .padding(.horizontal)
                }
                .padding(.bottom, 60)
            }

            if let statusMessage {
                Text(statusMessage)
                    .font(theme.fonts.caption)
                    .foregroundColor(.black)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(RoundedRectangle(cornerRadius: 16).fill(statusColor))
                    .padding(.bottom, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut, value: statusMessage)
        .fullScreenCover(isPresented: $showPreview) {
            PaywallPresenter(source: effectiveSource)
                .preferredColorScheme(.dark)
                .onDisappear {
                    handlePreviewDismiss()
                }
        }
        .onAppear {
            selectedVariant = MonetizationConfig.selectedPaywallVariant
            if let match = MonetizationConfig.sourceVariantOverrides.first(where: { $0.value == selectedVariant })?.key {
                selectedSourceOption = match
            } else {
                selectedSourceOption = MonetizationDebugData.defaultSource
            }
        }
        .onChange(of: selectedSourceOption) { newValue in
            guard newValue != MonetizationDebugData.customOptionToken else { return }
            applyVariantForSelectedSource()
            if !isResettingUser, let mapped = MonetizationConfig.mappedVariant(forSource: newValue) {
                showStatus("Variant mapped to \(mapped)", color: .blue)
            }
        }
    }

    // MARK: Variant selection & preview
    private var variantCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(theme.accent)
                    .font(.title3)
                Text("Current Paywall Variant")
                    .font(theme.fonts.headline)
                    .foregroundColor(theme.text)
                Spacer()
            }

            Text(selectedVariant)
                .font(theme.fonts.bodyBold)
                .foregroundColor(theme.accent)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.3)))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))

            VStack(spacing: 10) {
                // Show all registered paywalls dynamically
                ForEach(getAllPaywallVariants(), id: \.key) { variant in
                    variantButton(title: variant.title, key: variant.key)
                }
            }

            Divider().background(Color.white.opacity(0.1))

            VStack(alignment: .leading, spacing: 12) {
                Text("Preview & Analytics Source")
                    .font(theme.fonts.caption)
                    .foregroundColor(theme.textSecondary)

                Picker(selection: $selectedSourceOption) {
                    ForEach(MonetizationDebugData.knownSources, id: \.self) { source in
                        Text(source).tag(source)
                    }
                    Text("Custom…").tag(MonetizationDebugData.customOptionToken)
                } label: {
                    HStack {
                        Text("Source")
                            .font(theme.fonts.caption)
                            .foregroundColor(theme.textSecondary)
                        Spacer()
                        Text(effectiveSource)
                            .font(theme.fonts.body)
                            .foregroundColor(.white)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                }
                .pickerStyle(.menu)

                if selectedSourceOption == MonetizationDebugData.customOptionToken {
                    TextField("Enter custom source", text: $customSource)
                        .textFieldStyle(.roundedBorder)
                        .font(theme.fonts.body)
                }

                Button {
                    // Re-apply the force before preview to ensure it's set
                    PaywallRegistry.clearAssignments()
                    PaywallRegistry.forceVariant(source: effectiveSource, designID: selectedVariant)
                    showStatus("Previewing \(selectedVariant)", color: .blue)
                    showPreview = true
                } label: {
                    HStack {
                        Image(systemName: "play.circle.fill")
                        Text("Preview Paywall")
                            .font(theme.fonts.bodyBold)
                        Spacer()
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(theme.accent))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(white: 0.12)))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }

    private func variantButton(title: String, key: String) -> some View {
        Button {
            withAnimation(theme.animations.quick) {
                selectedVariant = key
                // Clear all previous assignments to ensure clean slate
                PaywallRegistry.clearAssignments()
                // Force this variant for the current source in the registry
                PaywallRegistry.forceVariant(source: effectiveSource, designID: key)
                // Also update UserDefaults for global override
                MonetizationConfig.selectedPaywallVariant = key
                showStatus("Switched to \(key)")
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(theme.fonts.body)
                        .foregroundColor(.white)
                    Text(key)
                        .font(theme.fonts.caption)
                        .foregroundColor(Color.white.opacity(0.6))
                }
                Spacer()
                if selectedVariant == key {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(theme.accent)
                        .font(.title3)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.4)))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.12), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // Config and runtime controls removed

    // MARK: Actions
    private var actionsCard: some View {
        VStack(spacing: 12) {
            Button(action: signOut) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text(isResettingUser ? "Signing Out…" : "Sign Out")
                        .font(theme.fonts.bodyBold)
                    Spacer()
                }
                .foregroundColor(.white)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.red))
            }
            .buttonStyle(.plain)
            .disabled(isResettingUser)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(white: 0.12)))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }

    // MARK: Helpers
    private func getAllPaywallVariants() -> [(title: String, key: String)] {
        let registeredDesigns = PaywallRegistry.listRegisteredDesigns().sorted()
        return registeredDesigns.map { key in
            let title = formatPaywallTitle(from: key)
            return (title: title, key: key)
        }
    }

    private func formatPaywallTitle(from key: String) -> String {
        switch key {
        case "sports_basic": return "Sports Basic"
        case "sports_urgency": return "Sports Urgency"
        case "sports_social": return "Sports Social Proof"
        case "dynamic_basic": return "Dynamic Basic"
        case "dynamic_minimal": return "Dynamic Minimal"
        case "dynamic_comparison": return "Dynamic Comparison"
        case "sports_training": return "Sports Training (Legacy)"
        case "dynamic_motion": return "Dynamic Motion (Legacy)"
        case "hockey_value": return "Hockey Value"
        case "paywall_50yr_trial_5wk": return "Paywall $50/yr Trial + $5/wk"
        case "hockey_premium": return "Hockey Premium"
        case "hockey_deal": return "Hockey Deal"
        case "paywall_5wk_only": return "Paywall $5/wk Only"
        case "default": return "Default Paywall"
        default: return key.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    private func handlePreviewPurchase(productID: String) {
        Task {
            let success = await monetization.purchaseSubscription(productID: productID)
            await MainActor.run {
                showPreview = false
                showStatus(success ? "Purchase succeeded" : "Purchase failed or cancelled", color: success ? .green : .orange)
            }
        }
    }

    private func handlePreviewDismiss() {
        showPreview = false
        showStatus("Preview dismissed", color: .gray)
    }

    private func signOut() {
        guard !isResettingUser else { return }
        isResettingUser = true
        showStatus("Signing out…", color: .orange)

        Task {
            // Sign out - in debug builds this does a complete reset
            try? await AuthenticationManager.shared.signOut()

            // Update UI state (will be reset anyway after sign out)
            await MainActor.run {
                isResettingUser = false
                showStatus("Signed out successfully", color: .green)
            }
        }
    }

    // Force refresh removed with runtime controls

    private func showStatus(_ message: String, color: Color = .green) {
        statusDismissWorkItem?.cancel()
        statusMessage = message
        statusColor = color

        let workItem = DispatchWorkItem { self.statusMessage = nil }
        statusDismissWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: workItem)
    }

    private func applyVariantForSelectedSource() {
        guard selectedSourceOption != MonetizationDebugData.customOptionToken,
              let mapped = MonetizationConfig.mappedVariant(forSource: selectedSourceOption) else { return }
        selectedVariant = mapped
    }

}

#Preview {
    MonetizationKitDebugSection()
        .environment(\.theme, ThemeManager.shared.activeTheme)
        .preferredColorScheme(.dark)
}

private enum MonetizationDebugData {
    static let customOptionToken = "__custom_source__"
    static let fallbackSource = "debug_preview"

    static var defaultSource: String {
        MonetizationConfig.defaultDebugSource.isEmpty ? fallbackSource : MonetizationConfig.defaultDebugSource
    }

    static var knownSources: [String] {
        var ordered: [String] = []
        let mappedSources = Array(MonetizationConfig.sourceVariantOverrides.keys).sorted()

        for source in [defaultSource] + mappedSources where !ordered.contains(source) {
            ordered.append(source)
        }

        if !ordered.contains(fallbackSource) {
            ordered.append(fallbackSource)
        }

        return ordered
    }
}
