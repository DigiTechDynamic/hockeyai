import SwiftUI

// MARK: - Shooting Questionnaire View
struct ShootingQuestionnaireView: View {
    @Environment(\.theme) var theme
    let flowState: AIFlowState
    @ObservedObject var viewModel: StickAnalyzerViewModel
    
    // Question responses
    @State private var priorityFocus: PriorityFocus?
    @State private var primaryShot: PrimaryShotType?
    @State private var shootingZone: ShootingZone?
    
    // UI state
    @State private var showValidationError = false
    @State private var currentQuestion = 1
    
    var body: some View {
        VStack(spacing: 0) {
            // Header section with back navigation when not on first question
            HStack {
                if currentQuestion > 1 {
                    Button(action: previousQuestion) {
                        Image(systemName: "chevron.left")
                            .font(theme.fonts.headline)
                            .foregroundColor(theme.primary)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                } else {
                    Color.clear
                        .frame(width: 44, height: 44)
                }
                
                Spacer()
                
                // Empty space for symmetry
                Color.clear
                    .frame(width: 44, height: 44)
            }
            .padding(.horizontal, theme.spacing.md)
            .padding(.top, theme.spacing.md)
            
            // Question header - matching AI Coach style
            VStack(spacing: theme.spacing.md) {
                Image(systemName: "questionmark.bubble.fill")
                    .font(.system(size: 56))
                    .foregroundColor(theme.primary)
                
                Text("Shooting Preferences")
                    .font(theme.fonts.title)
                    .foregroundColor(theme.text)
                
                Text("Question \(currentQuestion) of 3")
                    .font(theme.fonts.caption)
                    .foregroundColor(theme.textSecondary)
            }
            .padding(.bottom, theme.spacing.xl)
            
            ScrollView {
                VStack(spacing: theme.spacing.md) {
                    // Question content area
                    Group {
                        if currentQuestion == 1 {
                            questionOne
                        } else if currentQuestion == 2 {
                            questionTwo
                        } else if currentQuestion == 3 {
                            questionThree
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    
                    // Validation error
                    if showValidationError {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Please select an option to continue")
                                .font(theme.fonts.caption)
                                .foregroundColor(.orange)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: theme.cornerRadius)
                                .fill(Color.orange.opacity(0.1))
                        )
                        .padding(.horizontal, theme.spacing.lg)
                    }
                }
                .padding(.bottom, 100) // Make room for bottom button
            }
            
            Spacer(minLength: 0)
            
            // Bottom action button only - no Back button in footer
            VStack {
                Button(action: nextQuestion) {
                    HStack(spacing: theme.spacing.sm) {
                        Text(currentQuestion == 3 ? "Analyze" : "Next")
                        Image(systemName: currentQuestion == 3 ? "wand.and.stars" : "arrow.right")
                    }
                    .font(theme.fonts.button)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: theme.cornerRadius)
                            .fill(theme.primary)
                    )
                }
                .padding(.horizontal, theme.spacing.lg)
                .padding(.vertical, theme.spacing.md)
            }
            .background(
                Color.clear
                    .ignoresSafeArea(edges: .bottom)
            )
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: currentQuestion)
    }
    
    // MARK: - Question 1: Priority Focus
    private var questionOne: some View {
        VStack(alignment: .leading, spacing: theme.spacing.lg) {
            Text("What's most important to you in your shots?")
                .font(theme.fonts.headline)
                .foregroundColor(theme.text)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, theme.spacing.lg)
            
            VStack(spacing: theme.spacing.md) {
                ForEach(PriorityFocus.allCases, id: \.self) { focus in
                    Button(action: {
                        priorityFocus = focus
                        showValidationError = false
                    }) {
                        HStack(spacing: theme.spacing.md) {
                            Image(systemName: focus.icon)
                                .font(theme.fonts.title)
                                .foregroundColor(theme.primary)
                                .frame(width: 32)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(focus.rawValue)
                                    .font(theme.fonts.bodyBold)
                                    .foregroundColor(theme.text)
                                
                                Text(getDescription(for: focus))
                                    .font(theme.fonts.caption)
                                    .foregroundColor(theme.textSecondary)
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                            
                            Circle()
                                .stroke(priorityFocus == focus ? theme.primary : theme.divider, lineWidth: 2)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Circle()
                                        .fill(theme.primary)
                                        .frame(width: 16, height: 16)
                                        .opacity(priorityFocus == focus ? 1 : 0)
                                )
                        }
                        .padding(theme.spacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: theme.cornerRadius)
                                .fill(priorityFocus == focus ? theme.primary.opacity(0.1) : theme.surface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: theme.cornerRadius)
                                .stroke(priorityFocus == focus ? theme.primary : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, theme.spacing.lg)
        }
    }
    
    // MARK: - Question 2: Primary Shot
    private var questionTwo: some View {
        VStack(alignment: .leading, spacing: theme.spacing.lg) {
            Text("Which shot do you use most often?")
                .font(theme.fonts.headline)
                .foregroundColor(theme.text)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, theme.spacing.lg)
            
            VStack(spacing: theme.spacing.md) {
                ForEach(PrimaryShotType.allCases, id: \.self) { shot in
                    Button(action: {
                        primaryShot = shot
                        showValidationError = false
                    }) {
                        HStack(spacing: theme.spacing.md) {
                            Image(systemName: shot.icon)
                                .font(theme.fonts.title)
                                .foregroundColor(theme.primary)
                                .frame(width: 32)
                            
                            Text(shot.rawValue)
                                .font(theme.fonts.bodyBold)
                                .foregroundColor(theme.text)
                            
                            Spacer()
                            
                            Circle()
                                .stroke(primaryShot == shot ? theme.primary : theme.divider, lineWidth: 2)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Circle()
                                        .fill(theme.primary)
                                        .frame(width: 16, height: 16)
                                        .opacity(primaryShot == shot ? 1 : 0)
                                )
                        }
                        .padding(theme.spacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: theme.cornerRadius)
                                .fill(primaryShot == shot ? theme.primary.opacity(0.1) : theme.surface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: theme.cornerRadius)
                                .stroke(primaryShot == shot ? theme.primary : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, theme.spacing.lg)
        }
    }
    
    // MARK: - Question 3: Shooting Zone
    private var questionThree: some View {
        VStack(alignment: .leading, spacing: theme.spacing.lg) {
            Text("Where do you typically shoot from?")
                .font(theme.fonts.headline)
                .foregroundColor(theme.text)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, theme.spacing.lg)
            
            VStack(spacing: theme.spacing.md) {
                ForEach(ShootingZone.allCases, id: \.self) { zone in
                    Button(action: {
                        shootingZone = zone
                        showValidationError = false
                    }) {
                        HStack(spacing: theme.spacing.md) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(zone.rawValue)
                                    .font(theme.fonts.bodyBold)
                                    .foregroundColor(theme.text)
                                
                                Text(zone.description)
                                    .font(theme.fonts.caption)
                                    .foregroundColor(theme.textSecondary)
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                            
                            Circle()
                                .stroke(shootingZone == zone ? theme.primary : theme.divider, lineWidth: 2)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Circle()
                                        .fill(theme.primary)
                                        .frame(width: 16, height: 16)
                                        .opacity(shootingZone == zone ? 1 : 0)
                                )
                        }
                        .padding(theme.spacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: theme.cornerRadius)
                                .fill(shootingZone == zone ? theme.primary.opacity(0.1) : theme.surface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: theme.cornerRadius)
                                .stroke(shootingZone == zone ? theme.primary : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, theme.spacing.lg)
        }
    }
    
    // MARK: - Navigation
    private func previousQuestion() {
        withAnimation {
            currentQuestion -= 1
            showValidationError = false
        }
    }
    
    private func nextQuestion() {
        // Validate current question
        switch currentQuestion {
        case 1:
            guard priorityFocus != nil else {
                showValidationError = true
                return
            }
        case 2:
            guard primaryShot != nil else {
                showValidationError = true
                return
            }
        case 3:
            guard shootingZone != nil else {
                showValidationError = true
                return
            }
        default:
            break
        }
        
        showValidationError = false
        
        if currentQuestion < 3 {
            withAnimation {
                currentQuestion += 1
            }
        } else {
            // Complete questionnaire and proceed
            completeQuestionnaire()
        }
    }
    
    private func completeQuestionnaire() {
        guard let priority = priorityFocus,
              let shot = primaryShot,
              let zone = shootingZone else {
            return
        }
        
        let questionnaire = ShootingQuestionnaire(
            priorityFocus: priority,
            primaryShot: shot,
            shootingZone: zone
        )
        
        viewModel.setQuestionnaire(questionnaire)
        flowState.setData(questionnaire, for: "questionnaire")
        flowState.proceed()
    }
    
    private func getDescription(for focus: PriorityFocus) -> String {
        switch focus {
        case .power:
            return "Maximum shot velocity and distance"
        case .accuracy:
            return "Precise shot placement and control"
        case .balance:
            return "Equal emphasis on power and accuracy"
        }
    }
}