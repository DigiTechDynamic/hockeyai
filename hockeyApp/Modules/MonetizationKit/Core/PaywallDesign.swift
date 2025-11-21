import SwiftUI
import RevenueCat

// MARK: - Core Protocol
protocol PaywallDesign {
    var id: String { get }
    func build(products: LoadedProducts, actions: PaywallActions) -> AnyView
}

// MARK: - Product Container
struct LoadedProducts {
    let monthly: Package?
    let yearly: Package?
    let weekly: Package?
    let threeMonth: Package?
    let sixMonth: Package?
    let lifetime: Package?

    var monthlyPrice: String {
        monthly?.storeProduct.localizedPriceString ?? "$12.99"
    }

    var yearlyPrice: String {
        yearly?.storeProduct.localizedPriceString ?? "$49.99"
    }

    var weeklyPrice: String {
        weekly?.storeProduct.localizedPriceString ?? "$4.99"
    }

    var threeMonthPrice: String {
        threeMonth?.storeProduct.localizedPriceString ?? "$24.99"
    }

    var sixMonthPrice: String {
        sixMonth?.storeProduct.localizedPriceString ?? "$39.99"
    }

    var lifetimePrice: String {
        lifetime?.storeProduct.localizedPriceString ?? "$149.99"
    }

    func priceFor(productId: String) -> String {
        switch productId {
        case MonetizationConfig.monthlySubscriptionID:
            return monthlyPrice
        case MonetizationConfig.yearlySubscriptionID:
            return yearlyPrice
        case "weekly":
            return weeklyPrice
        case "three_month":
            return threeMonthPrice
        case "six_month":
            return sixMonthPrice
        case "lifetime":
            return lifetimePrice
        default:
            return "$--"
        }
    }

    func packageFor(productId: String) -> Package? {
        switch productId {
        case MonetizationConfig.monthlySubscriptionID:
            return monthly
        case MonetizationConfig.yearlySubscriptionID:
            return yearly
        case "weekly":
            return weekly
        case "three_month":
            return threeMonth
        case "six_month":
            return sixMonth
        case "lifetime":
            return lifetime
        default:
            return nil
        }
    }
}

// MARK: - Action Handlers
struct PaywallActions {
    let purchase: (String) async -> Bool
    let restore: () async -> Bool
    let dismiss: () -> Void
    let toggleTrial: ((Bool) -> Void)?  // Optional trial toggle handler
    let canShowTrialToggle: Bool  // Whether to show trial toggle

    // Tracking helpers
    let trackEvent: (String, [String: Any]) -> Void
    let trackPurchaseStart: (String) -> Void
    let trackPurchaseComplete: (String) -> Void
    let trackDismiss: () -> Void
}