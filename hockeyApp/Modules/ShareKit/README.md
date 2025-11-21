# ShareKit

**Professional sharing module for viral hockey app growth**

ShareKit provides a complete, production-ready system for sharing user-generated content across social platforms. Built for viral growth with analytics, A/B testing support, and optimized share templates.

---

## Table of Contents

1. [Overview](#overview)
2. [Quick Start](#quick-start)
3. [Core Concepts](#core-concepts)
4. [Usage Examples](#usage-examples)
5. [Adding New Templates](#adding-new-templates)
6. [Analytics & Metrics](#analytics--metrics)
7. [A/B Testing](#ab-testing)
8. [Architecture](#architecture)
9. [Best Practices](#best-practices)

---

## Overview

ShareKit extracts and improves the sharing functionality from `RatingResultsView.swift`, making it reusable across all app features:

- **STY Check** - Player beauty ratings
- **Skill Check** - AI skill analysis
- **Stick Analyzer** - Equipment recommendations
- **Shot Rater** - Shot quality ratings
- **AI Coach Flow** - Technique analysis

### Key Features

✅ **Reusable** - One-line integration with `ShareButton`
✅ **Smart** - Auto-generates viral share text based on content
✅ **Analytics** - Tracks shares by platform with K-factor calculation
✅ **Optimized** - Instagram Story size (1080x1920) templates
✅ **Professional** - Clean architecture with proper iOS patterns
✅ **A/B Testing Ready** - Easy to test different templates
✅ **Theme Integrated** - Works with existing `@Environment(\.theme)`

---

## Quick Start

### Basic Usage (SwiftUI)

```swift
import ShareKit

struct MyResultsView: View {
    let userImage: UIImage
    let score: Int
    let archetype: String

    var body: some View {
        VStack {
            // Your content here

            // One-line share button
            ShareButton(
                content: ShareContent(
                    type: .styCheck,
                    image: userImage,
                    score: score,
                    title: archetype,
                    comment: "Great hustle on the ice!"
                ),
                style: .primary
            )
        }
    }
}
```

### Using ShareService Directly

```swift
// For more control, use ShareService directly
let content = ShareContent(
    type: .skillCheck,
    image: videoThumbnail,
    score: 92,
    title: "Wrist Shot",
    comment: "Excellent form and follow-through"
)

ShareService.shared.share(content: content) { result in
    if result.completed {
        print("Shared to: \(result.platformName)")
    }
}
```

---

## Core Concepts

### 1. ShareContent

The main data model containing everything needed for sharing:

```swift
let content = ShareContent(
    type: .styCheck,              // Content type (affects template)
    image: userPhoto,             // User's photo/video thumbnail
    score: 87,                    // Optional score (0-100)
    title: "Grinder",             // Optional title/archetype
    subtitle: "Tier: Elite",      // Optional subtitle
    comment: "Great energy!",     // Optional AI comment
    userId: "user123",            // Optional for analytics
    sessionId: "session456",      // Optional for analytics
    metadata: [:],                // Custom analytics data
    socialProofText: "2,847 players shared today", // Optional
    customShareText: nil          // Override auto-generated text
)
```

### 2. Content Types

ShareKit supports these content types:

```swift
public enum ShareContentType {
    case styCheck        // Player beauty ratings
    case skillCheck      // AI skill analysis
    case stickAnalysis   // Equipment recommendations
    case shotRater       // Shot quality ratings
    case aiCoachFlow     // Technique analysis
    case generic         // Fallback for any content
}
```

Each type:
- Uses a specific template (or falls back to generic)
- Generates smart share text
- Tracks separately in analytics

### 3. Share Button Styles

Four built-in button styles:

```swift
ShareButton(content: content, style: .primary)   // Bold, prominent
ShareButton(content: content, style: .secondary) // Outlined
ShareButton(content: content, style: .icon)      // Icon only
ShareButton(content: content, style: .minimal)   // Subtle text
```

---

## Usage Examples

### Example 1: STY Check (Player Rating)

```swift
// In your results view
if let rating = viewModel.rating, let image = viewModel.uploadedImage {
    ShareButton(
        content: ShareContent(
            type: .styCheck,
            image: image,
            score: rating.overallScore,
            title: rating.archetype,
            comment: rating.aiComment
        ),
        style: .primary
    )
}
```

**Generated Share Text:**
- Score ≥90: "I scored 92/100 on STY Check! 😤 Can you beat it? 🏒"
- Score 75-89: "Just got a 82/100 on STY Check! Not bad 🔥 Get yours!"
- Score <75: "STY Check says I'm a 67/100! What's your rating? 🏒"

---

### Example 2: Skill Check (AI Analysis)

```swift
ShareButton(
    content: ShareContent(
        type: .skillCheck,
        image: videoThumbnail,
        score: 88,
        title: "Wrist Shot",
        comment: "Excellent release speed and accuracy"
    ),
    style: .primary
)
```

**Generated Share Text:**
- "My Wrist Shot is rated 88/100! 🔥 Analyze yours now! 🏒"

---

### Example 3: Stick Analysis

```swift
ShareButton(
    content: ShareContent(
        type: .stickAnalysis,
        image: stickImage,
        title: "CCM Ribcor Trigger 7 Pro",
        comment: "Perfect for quick-release shots"
    ),
    style: .secondary,
    label: "Share My Recommendation"
)
```

**Generated Share Text:**
- "AI says my perfect stick is CCM Ribcor Trigger 7 Pro! 🏒 Find yours!"

---

### Example 4: Programmatic Sharing

```swift
// Without using ShareButton (for custom UI)
Button("Custom Share Button") {
    let content = ShareContent(
        type: .shotRater,
        image: shotImage,
        score: 94,
        comment: "Perfect form!"
    )

    ShareService.shared.share(content: content) { result in
        if result.completed {
            // Track conversion or show confirmation
            print("Shared successfully to \(result.platformName)")
        }
    }
}
```

---

### Example 5: Convenience Methods

```swift
// Quick share for STY Check
ShareService.shared.shareSTYCheck(
    image: userPhoto,
    score: 85,
    archetype: "Sniper",
    comment: "Deadly accurate!"
)

// Quick share for Skill Check
ShareService.shared.shareSkillCheck(
    image: thumbnail,
    skill: "Backhand",
    score: 78,
    analysis: "Good technique, work on power"
)

// Quick share for Stick Analysis
ShareService.shared.shareStickAnalysis(
    image: stickPhoto,
    recommendation: "Bauer Vapor Hyperlite",
    details: "Lightweight, elite level"
)
```

---

## Adding New Templates

### Step 1: Create Template File

Create a new file in `/Templates/` (e.g., `ShotRaterTemplate.swift`):

```swift
import UIKit

struct ShotRaterTemplate {
    static func generateImage(for content: ShareContent) -> UIImage {
        let size = CGSize(width: 1080, height: 1920)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            let ctx = context.cgContext

            // 1. Draw background
            UIColor.black.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))

            // 2. Draw content image
            content.image.draw(in: CGRect(x: 0, y: 200, width: 1080, height: 1080))

            // 3. Draw score badge
            if let score = content.score {
                // ... draw score at top right
            }

            // 4. Draw title/comment
            if let comment = content.comment {
                // ... draw centered below image
            }

            // 5. Draw branding
            // ... "STY HOCKEY" at bottom
        }
    }
}
```

### Step 2: Add to ShareImageGenerator

Update `ShareImageGenerator.swift`:

```swift
public func generateImage(for content: ShareContent) -> UIImage {
    switch content.type {
    case .styCheck:
        return STYCheckTemplate.generateImage(for: content)
    case .skillCheck:
        return SkillCheckTemplate.generateImage(for: content)
    case .shotRater:
        return ShotRaterTemplate.generateImage(for: content)  // ← Add this
    // ... other cases
    }
}
```

### Step 3: Test Your Template

```swift
let testContent = ShareContent(
    type: .shotRater,
    image: testImage,
    score: 92,
    comment: "Perfect form!"
)

let generatedImage = ShareImageGenerator.shared.generateImage(for: testContent)
// Verify image looks good at 1080x1920
```

---

## Analytics & Metrics

ShareKit automatically tracks all share events through `AnalyticsKit`.

### Events Tracked

1. **share_initiated** - User opens share sheet
2. **share_completed** - User completes share
3. **share_cancelled** - User cancels share
4. **share_failed** - Share fails with error
5. **share_to_{platform}** - Platform-specific events

### Properties Tracked

```swift
{
    "content_type": "sty_check",
    "content_type_display": "STY Check",
    "score": 87,
    "has_top_badge": true,
    "top_badge": "TOP 10%",
    "title": "Grinder",
    "platform": "Instagram",
    "user_id": "user123",
    "session_id": "session456"
}
```

### Accessing Metrics

```swift
// Get session metrics
let metrics = ShareAnalytics.shared.getSessionMetrics()
print("Total shares: \(metrics.totalCompleted)")
print("Conversion rate: \(metrics.conversionRate)")
print("Top platform: \(metrics.topPlatform ?? "None")")

// Get conversion rate for specific type
let styConversion = ShareAnalytics.shared.getConversionRate(for: .styCheck)
print("STY Check conversion: \(styConversion * 100)%")

// Get platform distribution
let platforms = ShareAnalytics.shared.getPlatformDistribution()
// {"Instagram": 45, "Messages": 23, "Copy": 12, ...}
```

### K-Factor Calculation

Track viral coefficient for growth optimization:

```swift
// After tracking window (e.g., weekly)
ShareAnalytics.shared.trackViralCoefficient(
    invitesSent: 1000,      // Total shares completed
    conversions: 150        // New users from shares
)

// K-factor = (invites per user) × (conversion rate)
// If K > 1.0, your app is going viral! 🚀
```

---

## A/B Testing

ShareKit is built for easy A/B testing of share templates.

### Test Different Templates

```swift
// Randomly assign users to variants
let variant: TemplateVariant = Bool.random() ? .default : .minimal

let content = ShareContent(
    type: .styCheck,
    image: userPhoto,
    score: 85,
    title: "Sniper"
)

// Generate image with variant
let shareImage = ShareImageGenerator.shared.generateImage(
    for: content,
    variant: variant
)

// Analytics automatically tracks which variant was used
```

### Test Share Button Styles

```swift
// Test primary vs secondary button
let buttonStyle: ShareButtonStyle = experimentGroup == "A" ? .primary : .secondary

ShareButton(content: content, style: buttonStyle)
```

### Test Share Text Variations

```swift
// Override auto-generated text
let customText = experimentGroup == "A"
    ? "I just got rated! Can you beat my score? 🏒"
    : "Check out my STY rating! Get yours now 🏒"

let content = ShareContent(
    type: .styCheck,
    image: userPhoto,
    score: 85,
    customShareText: customText  // ← Override
)
```

### Analyze Results

```swift
// In your analytics dashboard, compare:
// - share_completed events by template_variant
// - Conversion rates by button style
// - Platform distribution by share text variant
```

---

## Architecture

```
ShareKit/
├── Models/
│   └── ShareContent.swift          # Data models
├── Services/
│   ├── ShareService.swift          # Main service (UIActivityViewController)
│   └── ShareImageGenerator.swift   # Template routing
├── Templates/
│   ├── STYCheckTemplate.swift      # STY Check share images
│   ├── SkillCheckTemplate.swift    # Skill Check share images
│   └── GenericTemplate.swift       # Fallback template
├── Views/
│   └── ShareButton.swift           # Reusable SwiftUI button
├── Analytics/
│   └── ShareAnalytics.swift        # Event tracking
└── README.md                       # This file
```

### Design Principles

1. **Separation of Concerns** - Each file has one responsibility
2. **Template Pattern** - Easy to add new share types
3. **Strategy Pattern** - Routing to correct template
4. **Observer Pattern** - Analytics tracking all events
5. **SwiftUI-First** - Modern declarative UI
6. **iOS Best Practices** - Proper popover support, error handling

---

## Best Practices

### 1. Always Provide High-Quality Images

```swift
// ✅ Good - High resolution
let content = ShareContent(
    type: .styCheck,
    image: fullResolutionPhoto,  // Original quality
    score: 85
)

// ❌ Bad - Low resolution
let content = ShareContent(
    type: .styCheck,
    image: thumbnailImage,  // Will look pixelated at 1080x1920
    score: 85
)
```

### 2. Use Appropriate Content Types

```swift
// ✅ Good - Specific type for better template
ShareContent(type: .styCheck, ...)

// ❌ Bad - Generic type when specific exists
ShareContent(type: .generic, ...)  // Misses optimized template
```

### 3. Include Analytics Metadata

```swift
// ✅ Good - Rich analytics data
ShareContent(
    type: .skillCheck,
    image: thumbnail,
    score: 88,
    userId: currentUserId,
    sessionId: analyticsSessionId,
    metadata: [
        "skill_type": "wrist_shot",
        "difficulty": "advanced",
        "attempts": 3
    ]
)
```

### 4. Test on Real Devices

```swift
// Share templates are optimized for:
// - Instagram Stories (1080x1920)
// - TikTok (1080x1920)
// - Twitter/X (1080x1920)
// Always test final output on actual devices
```

### 5. Handle Share Completion

```swift
ShareButton(content: content, style: .primary) { result in
    if result.completed {
        // Show success message
        // Track conversion event
        // Unlock achievement
        print("Shared to \(result.platformName)!")
    }
}
```

### 6. Respect User Privacy

```swift
// ✅ Good - User explicitly triggers share
ShareButton(content: content, style: .primary)

// ❌ Bad - Auto-sharing without permission
ShareService.shared.share(content: content)  // Don't call on view appear!
```

---

## Metrics to Track for Viral Growth

### Core Metrics

1. **Share Initiation Rate**
   - `shares_initiated / total_users`
   - Target: >30% (best-in-class viral apps)

2. **Share Completion Rate**
   - `shares_completed / shares_initiated`
   - Target: >60% (iOS average: 40-50%)

3. **K-Factor (Viral Coefficient)**
   - `(shares per user) × (conversion rate)`
   - Target: >1.0 for viral growth

4. **Platform Distribution**
   - Which platforms drive most shares?
   - Instagram Stories + TikTok should be top 2

5. **Time to Share**
   - How long after result does user share?
   - Faster = better engagement

### Advanced Metrics

6. **Share → Install Rate**
   - Track attribution from shares
   - Use deep links + UTM parameters

7. **Shared User Retention**
   - Do users who share have better D7/D30 retention?

8. **Share Frequency**
   - How many times does avg user share?
   - Power users who share multiple features

---

## Next Steps

### Adding Share to Other Features

1. **Skill Check Results** - Already has template
2. **Stick Analyzer Results** - Use generic template (or create custom)
3. **Shot Rater Results** - Create custom template
4. **AI Coach Flow** - Create custom template

### Example: Add to Skill Check

```swift
// In SkillCheckResultsView.swift
import ShareKit

// Add share button after results
if let thumbnail = viewModel.videoThumbnail {
    ShareButton(
        content: ShareContent(
            type: .skillCheck,
            image: thumbnail,
            score: viewModel.analysisScore,
            title: viewModel.skillName,
            comment: viewModel.aiAnalysis
        ),
        style: .primary
    )
}
```

---

## Support

For questions or issues with ShareKit:

1. Check this README first
2. Review `/Templates/` for template examples
3. Check Analytics dashboard for metrics
4. Review existing usage in `RatingResultsView.swift`

---

## License

Internal use only. Part of STY Hockey app.

---

**Built for viral growth. Optimized for social sharing. Ready for 2.5M TikTok influencer launch.** 🚀🏒
