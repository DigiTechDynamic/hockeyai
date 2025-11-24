import SwiftUI

// MARK: - SnapHockey Typography System
/// Unified typography system following iOS HIG and best practices
/// Using 1 font family (SF Pro) with limited weight variations
public struct TypographySystem {

    // MARK: - Display & Branding (Used sparingly)
    /// 48pt Black - ONLY for SNAPHOCKEY logo/brand
    public static let display = Font.system(size: 48, weight: .black, design: .default)

    // MARK: - Headers (Navigation & Sections)
    /// 34pt Bold - Major section headers, page titles
    public static let largeTitle = Font.system(size: 34, weight: .bold, design: .default)

    /// 28pt Bold - Screen titles, modal headers
    public static let title = Font.system(size: 28, weight: .bold, design: .default)

    /// 22pt Semibold - Section headers, card titles
    public static let headline = Font.system(size: 22, weight: .semibold, design: .default)

    // MARK: - Body Text (Content)
    /// 17pt Regular - Main body text, descriptions (iOS minimum recommended)
    public static let body = Font.system(size: 17, weight: .regular, design: .default)

    /// 17pt Semibold - Emphasized body text, important info
    public static let bodyBold = Font.system(size: 17, weight: .semibold, design: .default)

    /// 16pt Regular - Secondary descriptions, supporting text
    public static let callout = Font.system(size: 16, weight: .regular, design: .default)

    /// 14pt Regular - Captions, labels, hints
    public static let caption = Font.system(size: 14, weight: .regular, design: .default)

    /// 12pt Regular - Small labels, metadata (use sparingly)
    public static let caption2 = Font.system(size: 12, weight: .regular, design: .default)

    // MARK: - Controls & Actions
    /// 17pt Semibold - Primary buttons, CTAs
    public static let button = Font.system(size: 17, weight: .semibold, design: .default)

    /// 16pt Medium - Secondary buttons, links
    public static let buttonSecondary = Font.system(size: 16, weight: .medium, design: .default)

    /// 11pt Regular - Tab bar items (iOS minimum)
    public static let tabBar = Font.system(size: 11, weight: .regular, design: .default)
}

// MARK: - Typography Usage Guidelines
public struct TypographyGuidelines {

    /// Component-specific font assignments
    public static let usage = """
    TYPOGRAPHY USAGE GUIDE:

    🎯 HEADERS & NAVIGATION:
    • Navigation Bar Title: headline (22pt semibold)
    • Page Headers: largeTitle (34pt bold)
    • Section Headers: title (28pt bold)
    • Card Titles: headline (22pt semibold)

    📝 CONTENT:
    • Main Text: body (17pt regular)
    • Important Text: bodyBold (17pt semibold)
    • Descriptions: callout (16pt regular)
    • Helper Text: caption (14pt regular)
    • Timestamps/Meta: caption2 (12pt regular)

    🎮 INTERACTIVE:
    • Primary Buttons: button (17pt semibold)
    • Secondary Buttons: buttonSecondary (16pt medium)
    • Links: bodyBold (17pt semibold) with color
    • Tab Bar: tabBar (11pt regular)

    🏒 SPECIAL CASES:
    • SNAPHOCKEY Logo: display (48pt black)
    • Score Display: largeTitle (34pt bold)
    • Stats Numbers: title (28pt bold)

    ⚠️ RULES:
    1. Never go below 11pt (iOS minimum)
    2. Body text minimum 16-17pt for readability
    3. Use only 3-4 font weights maximum
    4. Maintain consistent hierarchy
    """
}

// MARK: - Updated ThemeFonts Implementation
public struct ThemeFontsV2 {
    // Display
    public let display: Font = TypographySystem.display

    // Headers
    public let largeTitle: Font = TypographySystem.largeTitle
    public let title: Font = TypographySystem.title
    public let headline: Font = TypographySystem.headline

    // Body
    public let body: Font = TypographySystem.body
    public let bodyBold: Font = TypographySystem.bodyBold
    public let callout: Font = TypographySystem.callout
    public let caption: Font = TypographySystem.caption
    public let caption2: Font = TypographySystem.caption2

    // Controls
    public let button: Font = TypographySystem.button
    public let buttonSecondary: Font = TypographySystem.buttonSecondary
    public let tabBar: Font = TypographySystem.tabBar

    public init() {}
}

// MARK: - Text Style Modifiers
extension Text {
    // Headers
    public func displayStyle() -> some View {
        self.font(TypographySystem.display)
    }

    public func largeTitleStyle() -> some View {
        self.font(TypographySystem.largeTitle)
    }

    public func titleStyle() -> some View {
        self.font(TypographySystem.title)
    }

    public func headlineStyle() -> some View {
        self.font(TypographySystem.headline)
    }

    // Body
    public func bodyStyle() -> some View {
        self.font(TypographySystem.body)
    }

    public func bodyBoldStyle() -> some View {
        self.font(TypographySystem.bodyBold)
    }

    public func calloutStyle() -> some View {
        self.font(TypographySystem.callout)
    }

    public func captionStyle() -> some View {
        self.font(TypographySystem.caption)
    }

    // Controls
    public func buttonStyle() -> some View {
        self.font(TypographySystem.button)
    }
}