import SwiftUI

// MARK: - Privacy Policy Sheet View
struct PrivacyPolicySheet: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        Text("Privacy Policy")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Last Updated: \(Date().formatted(date: .long, time: .omitted))")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        // Introduction
                        SectionView(
                            title: "Introduction",
                            content: "Hockey AI (\"we,\" \"our,\" or \"us\") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application."
                        )

                        // Information We Collect
                        SectionView(
                            title: "Information We Collect",
                            content: "We may collect the following types of information:\n\n• **Usage Data**: Information about how you interact with our app, including shot analysis sessions, training progress, and feature usage.\n\n• **Device Information**: Device type, operating system version, unique device identifiers.\n\n• **Analytics Data**: App performance metrics and crash reports to improve our service.\n\n• **Purchase Information**: Subscription status and transaction records (processed securely through Apple's payment system)."
                        )

                        // How We Use Your Information
                        SectionView(
                            title: "How We Use Your Information",
                            content: "We use your information to:\n\n• Provide and maintain our services\n• Track your hockey training progress\n• Improve our AI analysis algorithms\n• Send you notifications about your training\n• Process your subscription payments\n• Respond to your support requests\n• Comply with legal obligations"
                        )
                    }

                    Group {
                        // Data Storage and Security
                        SectionView(
                            title: "Data Storage and Security",
                            content: "We implement appropriate technical and organizational security measures to protect your personal information. Your data is stored securely using industry-standard encryption methods. Training data and progress are stored locally on your device and optionally backed up to your iCloud account."
                        )

                        // AI Analysis and Third-Party Processing
                        SectionView(
                            title: "AI Analysis and Third-Party Processing",
                            content: "When you use our AI-powered features (STY Check, Shot Rater, Skill Check, Stick Analyzer, AI Coach), your photos and videos are processed by third-party artificial intelligence providers:\n\n• **OpenAI**: For image and video analysis using GPT-4 Vision technology\n• **Google Gemini**: For advanced video analysis and coaching feedback\n\nYour media is sent to these services solely for analysis purposes and is not used for training their AI models. We do not share your personal information (name, email, etc.) with these AI providers. You will be asked for explicit consent before using any AI feature for the first time."
                        )

                        // Other Third-Party Services
                        SectionView(
                            title: "Other Third-Party Services",
                            content: "We also use the following third-party services:\n\n• **RevenueCat**: For subscription management and payment processing\n• **Apple Analytics**: For app performance monitoring\n• **CloudKit**: For optional data backup and sync\n• **Mixpanel**: For product analytics and user behavior insights\n\nThese services have their own privacy policies and we encourage you to review them."
                        )

                        // Your Rights
                        SectionView(
                            title: "Your Rights",
                            content: "You have the right to:\n\n• Access your personal data\n• Correct inaccurate data\n• Request deletion of your data\n• Opt-out of analytics tracking\n• Export your training data\n\nTo exercise these rights, please contact us at support@hockeyapp.com"
                        )

                        // Children's Privacy
                        SectionView(
                            title: "Children's Privacy",
                            content: "Our app is not intended for children under 13. We do not knowingly collect personal information from children under 13. If you are a parent or guardian and believe your child has provided us with personal information, please contact us."
                        )

                        // Contact Us
                        SectionView(
                            title: "Contact Us",
                            content: "If you have questions about this Privacy Policy, please contact us at:\n\nEmail: support@hockeyapp.com\nWebsite: www.hockeyapp.com/support"
                        )
                    }
                }
                .padding()
            }
            .background(Color(UIColor.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Terms of Service URL Handler
struct TermsOfServiceLink: View {
    var body: some View {
        Link("Terms of Service",
             destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
    }
}

// MARK: - Section Component
private struct SectionView: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)

            Text(.init(content)) // Using .init to support markdown
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Subscription Terms Disclosure (Apple Required - Minimal Version)
struct SubscriptionTermsDisclosure: View {
    var body: some View {
        // Empty view - legal text moved to Terms link (Apple compliant)
        EmptyView()
    }
}

// MARK: - Trial Terms Disclosure (For products with trials - Minimal Version)
struct TrialTermsDisclosure: View {
    let trialDays: Int
    let price: String
    let period: String

    var body: some View {
        // Empty view - legal text moved to Terms link (Apple compliant)
        EmptyView()
    }
}

// MARK: - Legal Links Component (Reusable for all paywalls)
struct PaywallLegalLinks: View {
    var body: some View {
        HStack(spacing: 20) {
            // Terms - Opens Apple's standard EULA
            Link("Terms",
                 destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.7))

            // Privacy - Opens public privacy policy URL (required by Apple)
            Link("Privacy",
                 destination: URL(string: "https://docs.google.com/document/d/1sVyqytQLQfAE1dFUzZvXx5H7wZQ7W-Nc3K9d0bIUM08/edit?tab=t.0#heading=h.57lx0vttzc7l")!)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

// MARK: - Preview
#Preview("Privacy Policy") {
    PrivacyPolicySheet()
}

#Preview("Legal Links") {
    PaywallLegalLinks()
        .padding()
        .background(Color.black)
}
