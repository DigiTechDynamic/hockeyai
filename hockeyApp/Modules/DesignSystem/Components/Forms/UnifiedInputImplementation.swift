import SwiftUI

// MARK: - Implementation Examples for Unified Design System
// This file demonstrates how to use the unified input components across different contexts

// MARK: - Example 1: Onboarding Flow Implementation
struct UnifiedOnboardingProfileView: View {
    @Environment(\.theme) var theme
    @State private var profile = UnifiedPlayerProfile()
    @State private var isMetric = false
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: InputDesignTokens.sectionSpacing) {
                // Header with progress
                OnboardingHeader(
                    title: "Build Your Profile",
                    subtitle: "Let's personalize your hockey experience",
                    progress: 0.5
                )
                
                // Physical Attributes Section
                SectionContainer(title: "Physical Attributes") {
                    VStack(spacing: InputDesignTokens.itemSpacing) {
                        UnifiedMetricToggle(isMetric: $isMetric)
                        UnifiedHeightInput(heightInInches: $profile.heightInInches, isMetric: $isMetric)
                        UnifiedWeightInput(weightInPounds: $profile.weightInPounds, isMetric: $isMetric)
                        UnifiedAgeInput(age: $profile.age)
                    }
                }
                
                // Demographics Section
                SectionContainer(title: "Demographics") {
                    UnifiedGenderSelection(gender: $profile.gender)
                }
                
                // Hockey Profile Section
                SectionContainer(title: "Hockey Profile") {
                    VStack(spacing: InputDesignTokens.sectionSpacing) {
                        UnifiedPositionSelection(position: $profile.position)
                        UnifiedHandednessSelection(handedness: $profile.handedness)
                    }
                }
                
                // Continue Button
                ContinueButton(action: continueToNextStep)
                    .padding(.top)
            }
            .padding()
        }
        .background(theme.background)
    }
    
    func continueToNextStep() {
        // Navigate to next onboarding step
    }
}

// MARK: - Example 2: Profile Settings Implementation (removed - using UnifiedProfileSettingsView.swift instead)

// MARK: - Example 3: AI Coach Profile Stage Implementation
struct UnifiedAICoachProfileView: View {
    @Environment(\.theme) var theme
    @State private var profile = UnifiedPlayerProfile()
    @State private var isMetric = false
    @State private var analysisComplete = false
    
    var body: some View {
        VStack(spacing: 0) {
            // AI Coach Header
            AICoachHeader(
                title: "Player Analysis",
                subtitle: "Help me understand your playing style",
                icon: "brain"
            )
            
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: InputDesignTokens.sectionSpacing) {
                    // Quick Setup Card
                    QuickSetupCard {
                        VStack(spacing: InputDesignTokens.itemSpacing) {
                            UnifiedMetricToggle(isMetric: $isMetric)
                            UnifiedHeightInput(heightInInches: $profile.heightInInches, isMetric: $isMetric)
                            UnifiedWeightInput(weightInPounds: $profile.weightInPounds, isMetric: $isMetric)
                        }
                    }
                    
                    // Playing Style Card
                    PlayingStyleCard {
                        VStack(spacing: InputDesignTokens.sectionSpacing) {
                            UnifiedPositionSelection(position: $profile.position)
                            UnifiedHandednessSelection(handedness: $profile.handedness)
                        }
                    }
                    
                    // AI Analysis Button
                    AnalyzeButton(action: startAnalysis)
                        .padding(.top)
                }
                .padding()
            }
            
            // Analysis Results (shown after completion)
            if analysisComplete {
                AnalysisResultsCard(profile: profile)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(theme.background)
    }
    
    func startAnalysis() {
        withAnimation(.spring()) {
            analysisComplete = true
        }
        HapticManager.shared.playNotification(type: .success)
    }
}

// MARK: - Supporting Components

// Player Profile Model for Design System Examples
struct UnifiedPlayerProfile {
    var heightInInches: Int = 70
    var weightInPounds: Int = 180
    var age: Int = 25
    var gender: String = "Male"
    var position: String = "C"
    var handedness: String = "Right"
}

// Section Container for Onboarding
struct SectionContainer<Content: View>: View {
    @Environment(\.theme) var theme
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title3.bold())
                .foregroundColor(theme.text)
            
            content
        }
        .padding()
        .background(theme.surface)
        .cornerRadius(InputDesignTokens.cardRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
    }
}

// Settings Section Header
struct SettingsSection<Content: View>: View {
    @Environment(\.theme) var theme
    let header: String
    let content: Content
    
    init(header: String, @ViewBuilder content: () -> Content) {
        self.header = header
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(header.uppercased())
                .font(.caption)
                .foregroundColor(theme.textSecondary)
                .padding(.horizontal)
                .padding(.vertical, 8)
            
            content
        }
    }
}

// Settings Row Container
struct SettingsRow<Content: View>: View {
    @Environment(\.theme) var theme
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .background(theme.surface)
    }
}

// Onboarding Header
struct OnboardingHeader: View {
    @Environment(\.theme) var theme
    let title: String
    let subtitle: String
    let progress: Double
    
    var body: some View {
        VStack(spacing: 12) {
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.divider)
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [theme.primary, theme.accent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 4)
                        .animation(.spring(), value: progress)
                }
            }
            .frame(height: 4)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.largeTitle.bold())
                    .foregroundColor(theme.text)
                
                Text(subtitle)
                    .font(.callout)
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical)
    }
}

// Profile Header Card
struct ProfileHeaderCard: View {
    @Environment(\.theme) var theme
    let profile: UnifiedPlayerProfile
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [theme.primary, theme.accent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Player Profile")
                    .font(.headline)
                    .foregroundColor(theme.text)
                
                HStack(spacing: 12) {
                    Label(profile.position, systemImage: "sportscourt.fill")
                    Label("\(profile.handedness) Shot", systemImage: "hockey.puck.fill")
                }
                .font(.caption)
                .foregroundColor(theme.textSecondary)
            }
            
            Spacer()
        }
        .padding()
        .background(
            LinearGradient(
                colors: [theme.surface, theme.surface.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(InputDesignTokens.cardRadius)
        .shadow(color: Color.black.opacity(0.08), radius: 6, y: 3)
    }
}

// AI Coach Header
struct AICoachHeader: View {
    @Environment(\.theme) var theme
    let title: String
    let subtitle: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 12) {
            // Animated AI Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [theme.primary.opacity(0.2), theme.accent.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: icon)
                    .font(.largeTitle)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [theme.primary, theme.accent],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2.bold())
                    .foregroundColor(theme.text)
                
                Text(subtitle)
                    .font(.callout)
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
}

// Quick Setup Card
struct QuickSetupCard<Content: View>: View {
    @Environment(\.theme) var theme
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(theme.warning)
                Text("Quick Setup")
                    .font(.headline)
                    .foregroundColor(theme.text)
            }
            
            content
        }
        .padding()
        .background(theme.surface)
        .cornerRadius(InputDesignTokens.cardRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
    }
}

// Playing Style Card
struct PlayingStyleCard<Content: View>: View {
    @Environment(\.theme) var theme
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sportscourt.fill")
                    .foregroundColor(theme.primary)
                Text("Playing Style")
                    .font(.headline)
                    .foregroundColor(theme.text)
            }
            
            content
        }
        .padding()
        .background(theme.surface)
        .cornerRadius(InputDesignTokens.cardRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
    }
}

// Analysis Results Card
struct AnalysisResultsCard: View {
    @Environment(\.theme) var theme
    let profile: UnifiedPlayerProfile
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title)
                    .foregroundColor(theme.success)
                
                Text("Analysis Complete")
                    .font(.headline)
                    .foregroundColor(theme.text)
                
                Spacer()
            }
            
            Text("Based on your profile, I've identified key areas to focus on for improving your game.")
                .font(.callout)
                .foregroundColor(theme.textSecondary)
            
            // Sample insights
            VStack(spacing: 12) {
                InsightRow(icon: "arrow.up.circle.fill", text: "Optimize shooting angle for \(profile.handedness) shot", color: theme.primary)
                InsightRow(icon: "speedometer", text: "Focus on agility drills for \(profile.position) position", color: theme.accent)
                InsightRow(icon: "target", text: "Recommended training intensity based on your metrics", color: theme.success)
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [theme.surface, theme.surface.opacity(0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(InputDesignTokens.cardRadius)
        .shadow(color: theme.success.opacity(0.2), radius: 8, y: 4)
        .padding()
    }
}

// Insight Row
struct InsightRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
            
            Text(text)
                .font(.callout)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

// Action Buttons

struct ContinueButton: View {
    @Environment(\.theme) var theme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text("Continue")
                    .font(.headline)
                Image(systemName: "arrow.right")
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: InputDesignTokens.inputHeight)
            .background(
                LinearGradient(
                    colors: [theme.primary, theme.primary.darker()],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(InputDesignTokens.inputRadius)
            .shadow(color: theme.primary.opacity(0.3), radius: 8, y: 4)
        }
        .buttonStyle(UnifiedScaleButtonStyle())
    }
}

struct SaveButton: View {
    @Environment(\.theme) var theme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Save Changes")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: InputDesignTokens.inputHeight)
            .background(
                LinearGradient(
                    colors: [theme.success, theme.success.darker()],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(InputDesignTokens.inputRadius)
            .shadow(color: theme.success.opacity(0.3), radius: 8, y: 4)
        }
        .buttonStyle(UnifiedScaleButtonStyle())
    }
}

struct AnalyzeButton: View {
    @Environment(\.theme) var theme
    let action: () -> Void
    @State private var isAnalyzing = false
    
    var body: some View {
        Button(action: {
            isAnalyzing = true
            action()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                isAnalyzing = false
            }
        }) {
            HStack {
                if isAnalyzing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "wand.and.stars")
                }
                Text(isAnalyzing ? "Analyzing..." : "Start AI Analysis")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: InputDesignTokens.inputHeight)
            .background(
                LinearGradient(
                    colors: [theme.accent, theme.primary],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(InputDesignTokens.inputRadius)
            .shadow(color: theme.accent.opacity(0.3), radius: 8, y: 4)
        }
        .disabled(isAnalyzing)
        .buttonStyle(UnifiedScaleButtonStyle())
    }
}

// Note: UnifiedScaleButtonStyle is imported from UnifiedInputComponents.swift

// Color extension for darker shades
extension Color {
    func darker(by percentage: CGFloat = 20.0) -> Color {
        return self.opacity(1 - percentage/100)
    }
}