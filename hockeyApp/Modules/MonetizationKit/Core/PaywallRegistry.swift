import Foundation

final class PaywallRegistry {
    private static var designs: [String: PaywallDesign] = [:]
    private static var testGroups: [String: [String]] = [:]
    private static var userAssignments: [String: String] = [:] // source -> assigned design

    // MARK: - Registration

    static func register(_ design: PaywallDesign) {
        designs[design.id] = design
        print("[PaywallRegistry] Registered paywall: \(design.id)")
    }

    static func registerMultiple(_ paywalls: [PaywallDesign]) {
        paywalls.forEach { register($0) }
    }

    // MARK: - A/B Testing Configuration

    static func configureABTest(source: String, designIDs: [String]) {
        testGroups[source] = designIDs
        print("[PaywallRegistry] Configured A/B test for '\(source)' with designs: \(designIDs)")
    }

    static func configureABTests(_ tests: [String: [String]]) {
        testGroups = tests
    }

    // MARK: - Design Selection

    static func getDesign(for source: String) -> PaywallDesign {
        // Special case: Deal recovery always shows hockey_deal
        if MonetizationConfig.isDealRecoverySource(source) {
            print("[PaywallRegistry] 💰 Deal recovery source detected - forcing hockey_deal variant")
            if let design = designs["hockey_deal"] {
                return design
            }
        }

        // Resolve alias for assignment so multiple sources can share a single variant
        let assignmentSource = MonetizationConfig.assignmentSource(for: source)

        // Check if user already has an assigned variant for consistency
        let assignmentKey = "\(assignmentSource)"
        if let existingAssignment = userAssignments[assignmentKey],
           let design = designs[existingAssignment] {
            print("[PaywallRegistry] Returning existing assignment '\(existingAssignment)' for source '\(source)' (alias: '\(assignmentSource)')")
            return design
        }

        // PRIORITY 1: Use Firebase Remote Config if available
        if FirebaseRemoteConfigManager.shared.isAvailable {
            let selectedID = FirebaseRemoteConfigManager.shared.getPaywallVariant(for: assignmentSource)
            userAssignments[assignmentKey] = selectedID

            if let design = designs[selectedID] {
                print("[PaywallRegistry] 🔥 Firebase Remote Config assigned variant '\(selectedID)' for source '\(source)'")
                trackAssignment(source: source, variant: selectedID, method: "firebase_remote_config")
                return design
            } else {
                print("[PaywallRegistry] ⚠️ Firebase returned unknown variant '\(selectedID)', falling back to local A/B test")
            }
        } else {
            print("[PaywallRegistry] Firebase Remote Config not available, using local A/B test")
        }

        // PRIORITY 2: If there's an A/B test configured for this source (local fallback)
        if let testDesigns = testGroups[assignmentSource], !testDesigns.isEmpty {
            // Use consistent hashing based on device ID for assignment
            let selectedID = selectVariant(from: testDesigns, for: assignmentSource)
            userAssignments[assignmentKey] = selectedID

            if let design = designs[selectedID] {
                print("[PaywallRegistry] Assigned variant '\(selectedID)' for source '\(source)' (alias: '\(assignmentSource)') via local A/B test")
                trackAssignment(source: source, variant: selectedID, method: "local_hash")
                return design
            }
        }

        // PRIORITY 3: Check for source-specific override
        if let mappedVariant = MonetizationConfig.mappedVariant(forSource: assignmentSource),
           let design = designs[mappedVariant] {
            print("[PaywallRegistry] Using mapped variant '\(mappedVariant)' for source '\(source)' (alias: '\(assignmentSource)')")
            return design
        }

        // PRIORITY 4: Fall back to default
        let defaultID = MonetizationConfig.selectedPaywallVariant
        print("[PaywallRegistry] Using default paywall '\(defaultID)' for source '\(source)' (alias: '\(assignmentSource)')")
        return designs[defaultID] ?? designs.values.first!
    }

    // MARK: - Variant Selection

    private static func selectVariant(from variants: [String], for source: String) -> String {
        // Use device identifier for consistent assignment
        let deviceID = getDeviceIdentifier()
        let hashInput = "\(deviceID)-\(source)"
        let hash = hashInput.hash

        // Distribute evenly across variants
        let index = abs(hash) % variants.count
        return variants[index]
    }

    private static func getDeviceIdentifier() -> String {
        // Use UserDefaults to persist a unique ID
        let key = "paywall_device_id"
        if let existingID = UserDefaults.standard.string(forKey: key) {
            return existingID
        }

        let newID = UUID().uuidString
        UserDefaults.standard.set(newID, forKey: key)
        return newID
    }

    // MARK: - Analytics

    private static func trackAssignment(source: String, variant: String, method: String = "local_hash") {
        AnalyticsManager.shared.track(
            eventName: "paywall_ab_assignment",
            properties: [
                "source": source,
                "variant": variant,
                "assignment_method": method,
                "test_group": testGroups[source] ?? []
            ]
        )
    }

    // MARK: - Debug

    static func listRegisteredDesigns() -> [String] {
        Array(designs.keys).sorted()
    }

    static func listConfiguredTests() -> [String: [String]] {
        testGroups
    }

    static func clearAssignments() {
        userAssignments.removeAll()
        print("[PaywallRegistry] Cleared all user assignments")
    }

    static func forceVariant(source: String, designID: String) {
        userAssignments[source] = designID
        print("[PaywallRegistry] Forced variant '\(designID)' for source '\(source)'")
    }
}
