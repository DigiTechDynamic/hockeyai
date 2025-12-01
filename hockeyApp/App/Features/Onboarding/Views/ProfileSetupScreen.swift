import SwiftUI

// MARK: - Profile Setup Screen (Name, Age, Phone)
struct ProfileSetupScreen: View {
    @Environment(\.theme) var theme
    @ObservedObject var viewModel: OnboardingViewModel
    @ObservedObject var coordinator: OnboardingFlowCoordinator

    @State private var appeared = false
    @StateObject private var keyboard = KeyboardObserver()
    @State private var name: String = ""
    @State private var age: String = ""
    @State private var jerseyNumber: String = ""
    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case name, age, jersey
    }

    private var canContinue: Bool {
        // Name is optional, but age is required
        guard let ageInt = Int(age), ageInt >= 5 && ageInt <= 99 else {
            return false
        }
        return true
    }

    var body: some View {
        ZStack {
            // Animated background
            BackgroundAnimationView(type: .energyWaves, isActive: true, intensity: 0.25)
                .ignoresSafeArea()

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Spacer(minLength: 40)

                        // Header
                        VStack(spacing: theme.spacing.sm) {
                            Text("Let's get to know you")
                                .font(.system(size: 32, weight: .black))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 20)
                                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: appeared)

                            Text("This helps us personalize your experience")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(theme.textSecondary)
                                .multilineTextAlignment(.center)
                                .opacity(appeared ? 1 : 0)
                                .animation(.easeOut(duration: 0.4).delay(0.1), value: appeared)
                        }
                        .padding(.horizontal, theme.spacing.lg)
                        .padding(.bottom, theme.spacing.xl)

                    // Form fields
                    VStack(spacing: theme.spacing.lg) {
                        // Name field (optional)
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("What should we call you?")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(theme.text)
                                Text("(optional)")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(theme.textSecondary)
                            }

                            HStack(spacing: 12) {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(theme.primary)
                                    .frame(width: 24)

                                TextField("", text: $name)
                                    .placeholder(when: name.isEmpty) {
                                        Text("Name or nickname")
                                            .foregroundColor(theme.textSecondary.opacity(0.6))
                                    }
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(theme.text)
                                    .textContentType(.name)
                                    .autocapitalization(.words)
                                    .focused($focusedField, equals: .name)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(theme.surface)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(focusedField == .name ? theme.primary : theme.divider, lineWidth: focusedField == .name ? 2 : 1)
                                    )
                            )
                        }
                        .id(Field.name)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.15), value: appeared)

                        // Age field (required)
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("How old are you?")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(theme.text)
                                Text("*")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(theme.primary)
                            }

                            HStack(spacing: 12) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 18))
                                    .foregroundColor(theme.primary)
                                    .frame(width: 24)

                                TextField("", text: $age)
                                    .placeholder(when: age.isEmpty) {
                                        Text("Age")
                                            .foregroundColor(theme.textSecondary.opacity(0.6))
                                    }
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(theme.text)
                                    .keyboardType(.numberPad)
                                    .focused($focusedField, equals: .age)
                                    .onChange(of: age) { newValue in
                                        // Limit to 2 digits
                                        if newValue.count > 2 {
                                            age = String(newValue.prefix(2))
                                        }
                                        // Remove non-numeric characters
                                        age = newValue.filter { $0.isNumber }
                                    }

                                if let ageInt = Int(age), ageInt >= 5 && ageInt <= 99 {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(theme.primary)
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(theme.surface)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(focusedField == .age ? theme.primary : theme.divider, lineWidth: focusedField == .age ? 2 : 1)
                                    )
                            )
                        }
                        .id(Field.age)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.25), value: appeared)

                        // Jersey Number field (optional)
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Jersey number")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(theme.text)
                                Text("(optional)")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(theme.textSecondary)
                            }

                            HStack(spacing: 12) {
                                Text("#")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(theme.primary)
                                    .frame(width: 24)

                                TextField("", text: $jerseyNumber)
                                    .placeholder(when: jerseyNumber.isEmpty) {
                                        Text("00")
                                            .foregroundColor(theme.textSecondary.opacity(0.6))
                                    }
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(theme.text)
                                    .keyboardType(.numberPad)
                                    .focused($focusedField, equals: .jersey)
                                    .onChange(of: jerseyNumber) { newValue in
                                        // Limit to 2 digits (0-99)
                                        if newValue.count > 2 {
                                            jerseyNumber = String(newValue.prefix(2))
                                        }
                                        // Remove non-numeric characters
                                        jerseyNumber = newValue.filter { $0.isNumber }
                                    }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(theme.surface)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(focusedField == .jersey ? theme.primary : theme.divider, lineWidth: focusedField == .jersey ? 2 : 1)
                                    )
                            )
                        }
                        .id(Field.jersey)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.35), value: appeared)
                    }
                    .padding(.horizontal, theme.spacing.lg)

                    Spacer(minLength: 20)
                }
                .scrollDismissesKeyboard(.interactively)
                .keyboardAdaptive()
                .padding(.bottom, keyboard.keyboardHeight > 0 ? 12 : 100) // Space for fixed button when keyboard hidden
                .onChange(of: focusedField) { field in
                    if let field = field {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(field, anchor: .center)
                        }
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            // Fixed bottom CTA - matches welcome screen positioning
            VStack(spacing: theme.spacing.sm) {
                AppButton(title: "Continue", action: {
                    HapticManager.shared.playImpact(style: .medium)
                    saveProfileData()
                    focusedField = nil
                    coordinator.navigateForward()
                })
                .buttonStyle(.primary)
                .withIcon("arrow.right")
                .buttonSize(.large)
                .disabled(!canContinue)
                .padding(.horizontal, theme.spacing.lg)

                // Maintain footer height consistency when keyboard hidden
                Text(" ")
                    .font(theme.fonts.body)
                    .foregroundColor(.clear)
                    .frame(height: keyboard.keyboardHeight > 0 ? 0 : 44)
            }
            .padding(.bottom, keyboard.keyboardHeight > 0 ? 0 : theme.spacing.lg)
            .background(
                LinearGradient(
                    colors: [.clear, theme.background.opacity(0.9), theme.background],
                    startPoint: .top,
                    endPoint: .center
                )
            )
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.4), value: appeared)
        }
        .onAppear {
            appeared = true
            HapticManager.shared.playNotification(type: .success)
            // Auto-focus on name field after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                focusedField = .name
            }
        }
        .onTapGesture {
            focusedField = nil
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
                .fontWeight(.semibold)
            }
        }
    }
    }

    private func saveProfileData() {
        var profile = viewModel.playerProfile ?? PlayerProfile()
        if !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            profile.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let ageInt = Int(age) {
            profile.age = ageInt
        }
        if !jerseyNumber.isEmpty {
            profile.jerseyNumber = jerseyNumber
        }
        viewModel.playerProfile = profile
    }
}

// MARK: - Placeholder Extension
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
