import SwiftUI

// MARK: - Stick Details Input View
struct StickDetailsInputView: View {
    @Environment(\.theme) var theme
    let flowState: AIFlowState
    @ObservedObject var viewModel: StickAnalyzerViewModel
    
    // Form state
    @State private var unknownSpecs = false
    @State private var brand = ""
    @State private var model = ""
    @State private var flex = ""
    @State private var length = ""
    @State private var curvePattern = ""
    @State private var kickPoint: KickPointType?
    @State private var lie = ""
    
    // Validation
    @State private var showValidationError = false
    @State private var validationMessage = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: theme.spacing.sm) {
                Text("Current Stick Details")
                    .font(theme.fonts.headline)
                    .foregroundColor(theme.text)
                
                Text("Tell us about your current stick")
                    .font(theme.fonts.caption)
                    .foregroundColor(theme.textSecondary)
            }
            .padding(.top, theme.spacing.xl)
            .padding(.bottom, theme.spacing.lg)
            
            ScrollView {
                VStack(spacing: theme.spacing.lg) {
                    // Unknown specs toggle
                    VStack(alignment: .leading, spacing: theme.spacing.md) {
                        Toggle(isOn: $unknownSpecs.animation()) {
                            HStack {
                                Image(systemName: "questionmark.circle")
                                    .foregroundColor(theme.primary)
                                Text("I don't know my stick specifications")
                                    .font(theme.fonts.body)
                                    .foregroundColor(theme.text)
                            }
                        }
                        .tint(theme.primary)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: theme.cornerRadius)
                                .fill(theme.surface)
                        )
                    }
                    
                    if !unknownSpecs {
                        // Brand and Model
                        VStack(alignment: .leading, spacing: theme.spacing.sm) {
                            Label("Brand & Model", systemImage: "tag")
                                .font(theme.fonts.bodyBold)
                                .foregroundColor(theme.text)
                            
                            HStack(spacing: theme.spacing.sm) {
                                AppTextField(placeholder: "Brand", text: $brand)
                                    .textFieldStyle(.filled)
                                
                                AppTextField(placeholder: "Model", text: $model)
                                    .textFieldStyle(.filled)
                            }
                        }
                        
                        // Flex
                        VStack(alignment: .leading, spacing: theme.spacing.sm) {
                            Label("Flex Rating", systemImage: "arrow.up.and.down")
                                .font(theme.fonts.bodyBold)
                                .foregroundColor(theme.text)
                            
                            AppTextField(placeholder: "e.g., 75, 85, 95", text: $flex)
                                .keyboardType(.numberPad)
                        }
                        
                        // Length
                        VStack(alignment: .leading, spacing: theme.spacing.sm) {
                            Label("Length (inches)", systemImage: "ruler")
                                .font(theme.fonts.bodyBold)
                                .foregroundColor(theme.text)
                            
                            AppTextField(placeholder: "e.g., 58, 59, 60", text: $length)
                                .keyboardType(.decimalPad)
                        }
                        
                        // Curve Pattern
                        VStack(alignment: .leading, spacing: theme.spacing.sm) {
                            Label("Curve Pattern", systemImage: "waveform.path")
                                .font(theme.fonts.bodyBold)
                                .foregroundColor(theme.text)
                            
                            AppTextField(placeholder: "e.g., P92, P88, P28", text: $curvePattern)
                                .textFieldStyle(.filled)
                        }
                        
                        // Kick Point
                        VStack(alignment: .leading, spacing: theme.spacing.sm) {
                            Label("Kick Point", systemImage: "point.topleft.down.curvedto.point.filled.bottomright.up")
                                .font(theme.fonts.bodyBold)
                                .foregroundColor(theme.text)
                            
                            HStack(spacing: theme.spacing.sm) {
                                ForEach(KickPointType.allCases, id: \.self) { type in
                                    Button(action: {
                                        kickPoint = type
                                    }) {
                                        VStack(spacing: 4) {
                                            Text(type.rawValue)
                                                .font(theme.fonts.bodyBold)
                                                .foregroundColor(kickPoint == type ? .black : theme.text)
                                            
                                            Text(type.description)
                                                .font(.system(size: 10))
                                                .foregroundColor(kickPoint == type ? .black.opacity(0.8) : theme.textSecondary)
                                                .lineLimit(2)
                                                .multilineTextAlignment(.center)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, theme.spacing.sm)
                                        .padding(.horizontal, theme.spacing.xs)
                                        .background(
                                            RoundedRectangle(cornerRadius: theme.cornerRadius)
                                                .fill(kickPoint == type ? theme.primary : theme.surface)
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        
                        // Lie
                        VStack(alignment: .leading, spacing: theme.spacing.sm) {
                            Label("Lie Angle", systemImage: "angle")
                                .font(theme.fonts.bodyBold)
                                .foregroundColor(theme.text)
                            
                            AppTextField(placeholder: "e.g., 5, 5.5, 6", text: $lie)
                                .keyboardType(.decimalPad)
                        }
                    }
                    
                    // Validation error
                    if showValidationError {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(validationMessage)
                                .font(theme.fonts.caption)
                                .foregroundColor(.orange)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: theme.cornerRadius)
                                .fill(Color.orange.opacity(0.1))
                        )
                    }
                }
                .padding(.horizontal, theme.spacing.lg)
                .padding(.bottom, 100)
            }
            
            // Continue button
            VStack {
                Button(action: proceedToNext) {
                    HStack {
                        Text("Continue")
                            .font(theme.fonts.bodyBold)
                        Image(systemName: "arrow.right")
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, theme.spacing.md)
                    .background(theme.primary)
                    .cornerRadius(theme.cornerRadius)
                }
                .padding(.horizontal, theme.spacing.lg)
                .padding(.vertical, theme.spacing.md)
                .background(
                    theme.background
                        .opacity(0.95)
                        .ignoresSafeArea()
                )
            }
        }
        .background(theme.background)
        .trackScreen("stick_analyzer_input")
    }
    
    private func proceedToNext() {
        // Create stick details
        let details = StickDetails(
            brand: unknownSpecs ? nil : (brand.isEmpty ? nil : brand),
            model: unknownSpecs ? nil : (model.isEmpty ? nil : model),
            flex: unknownSpecs ? nil : Int(flex),
            length: unknownSpecs ? nil : Double(length),
            curvePattern: unknownSpecs ? nil : (curvePattern.isEmpty ? nil : curvePattern),
            kickPoint: unknownSpecs ? nil : kickPoint,
            lie: unknownSpecs ? nil : Int(lie),
            unknownSpecs: unknownSpecs
        )
        
        // Validate
        if !unknownSpecs && brand.isEmpty {
            validationMessage = "Please enter at least the stick brand"
            showValidationError = true
            return
        }
        
        // Store and proceed
        viewModel.setStickDetails(details)
        flowState.setData(details, for: "stickDetails")
        flowState.proceed()
    }
}
