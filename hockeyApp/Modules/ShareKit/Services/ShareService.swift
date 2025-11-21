import UIKit
import SwiftUI

// MARK: - Share Service
/// Main service for handling share functionality across the app
/// Handles UIActivityViewController presentation with proper iOS patterns
@MainActor
public final class ShareService {
    // MARK: - Singleton
    public static let shared = ShareService()

    private init() {}

    // MARK: - Share Content
    /// Present share sheet for given content (text-only, no image generation)
    /// - Parameters:
    ///   - content: The share content to present
    ///   - completion: Called when share completes or is cancelled
    public func share(
        content: ShareContent,
        completion: ((ShareResult) -> Void)? = nil
    ) {
        // Track share initiated
        ShareAnalytics.shared.trackShareInitiated(content: content)

        // Create activity items - TEXT ONLY (no image generation)
        let activityItems: [Any] = [content.shareText]

        // Create activity view controller
        let activityVC = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )

        // Exclude certain activities for better UX
        activityVC.excludedActivityTypes = [
            .assignToContact,
            .print,
            .openInIBooks,
            .markupAsPDF
        ]

        // Handle completion
        activityVC.completionWithItemsHandler = { activityType, completed, returnedItems, error in
            let result = ShareResult(
                completed: completed,
                activityType: activityType?.rawValue,
                error: error
            )

            if completed {
                ShareAnalytics.shared.trackShareCompleted(
                    content: content,
                    platform: result.platformName
                )
            } else if error != nil {
                ShareAnalytics.shared.trackShareFailed(
                    content: content,
                    error: error
                )
            } else {
                ShareAnalytics.shared.trackShareCancelled(content: content)
            }

            completion?(result)
        }

        // Present the share sheet
        present(activityVC)
    }

    // MARK: - Presentation Helpers
    /// Present activity view controller from the current top view controller
    private func present(_ activityVC: UIActivityViewController) {
        guard let topVC = findTopViewController() else {
            print("❌ [ShareService] Could not find top view controller")
            return
        }

        // iPad popover configuration
        if let popover = activityVC.popoverPresentationController {
            if let sourceView = topVC.view {
                popover.sourceView = sourceView
                popover.sourceRect = CGRect(
                    x: sourceView.bounds.midX,
                    y: sourceView.bounds.midY,
                    width: 0,
                    height: 0
                )
                popover.permittedArrowDirections = []
            }
        }

        topVC.present(activityVC, animated: true)
        print("✅ [ShareService] Share sheet presented")
    }

    /// Find the topmost view controller in the hierarchy
    private func findTopViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) ?? windowScene.windows.first,
              let rootVC = window.rootViewController else {
            return nil
        }

        return findTopViewController(from: rootVC)
    }

    /// Recursively find the topmost presented view controller
    private func findTopViewController(from viewController: UIViewController) -> UIViewController {
        if let presented = viewController.presentedViewController {
            return findTopViewController(from: presented)
        }

        if let navigationController = viewController as? UINavigationController {
            if let visible = navigationController.visibleViewController {
                return findTopViewController(from: visible)
            }
        }

        if let tabBarController = viewController as? UITabBarController {
            if let selected = tabBarController.selectedViewController {
                return findTopViewController(from: selected)
            }
        }

        return viewController
    }
}

// MARK: - SwiftUI Integration
/// SwiftUI wrapper for triggering shares
public struct ShareAction {
    private let content: ShareContent
    private let completion: ((ShareResult) -> Void)?

    public init(
        content: ShareContent,
        completion: ((ShareResult) -> Void)? = nil
    ) {
        self.content = content
        self.completion = completion
    }

    @MainActor
    public func callAsFunction() {
        ShareService.shared.share(
            content: content,
            completion: completion
        )
    }
}

// MARK: - Convenience Extensions
public extension ShareService {
    /// Quick share for STY Check results
    func shareSTYCheck(
        score: Int,
        archetype: String,
        comment: String? = nil
    ) {
        let content = ShareContent(
            type: .styCheck,
            score: score,
            title: archetype,
            comment: comment
        )
        share(content: content)
    }

    /// Quick share for Skill Check results
    func shareSkillCheck(
        skill: String,
        score: Int,
        analysis: String? = nil
    ) {
        let content = ShareContent(
            type: .skillCheck,
            score: score,
            title: skill,
            comment: analysis
        )
        share(content: content)
    }

    /// Quick share for Stick Analysis results
    func shareStickAnalysis(
        recommendation: String,
        details: String? = nil
    ) {
        let content = ShareContent(
            type: .stickAnalysis,
            title: recommendation,
            comment: details
        )
        share(content: content)
    }

    /// Quick share for Shot Rater results
    func shareShotRating(
        score: Int,
        feedback: String? = nil
    ) {
        let content = ShareContent(
            type: .shotRater,
            score: score,
            comment: feedback
        )
        share(content: content)
    }
}
