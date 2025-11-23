import SwiftUI

// MARK: - Personal Info Section
struct PersonalInfoSection: View {
    @Environment(\.theme) var theme
    @ObservedObject var viewModel: ProfileViewModel
    @State private var showEditNameSheet = false
    @State private var editedName = ""

    var body: some View {
        ProfileSectionCard {
            VStack(alignment: .leading, spacing: 16) {
                // Display Name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name")
                        .font(theme.fonts.caption)
                        .foregroundColor(Color.white.opacity(0.5))

                    Button(action: {
                        editedName = viewModel.displayName
                        showEditNameSheet = true
                    }) {
                        HStack {
                            Image(systemName: "person.text.rectangle")
                                .font(theme.fonts.body)
                                .foregroundColor(Color.white.opacity(0.5))
                                .frame(width: 20)

                            Text(viewModel.displayName.isEmpty ? "Enter your name" : viewModel.displayName)
                                .font(theme.fonts.body)
                                .foregroundColor(viewModel.displayName.isEmpty ? Color.white.opacity(0.5) : .white)

                            Spacer()
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                Divider()
                    .background(Color.white.opacity(0.1))

                // Email (read-only)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(theme.fonts.caption)
                        .foregroundColor(Color.white.opacity(0.5))

                    HStack {
                        Image(systemName: "envelope.fill")
                            .font(theme.fonts.body)
                            .foregroundColor(Color.white.opacity(0.5))
                            .frame(width: 20)

                        Text(viewModel.email.isEmpty ? "No email" : viewModel.email)
                            .font(theme.fonts.body)
                            .foregroundColor(Color.white.opacity(0.7))

                        Spacer()
                    }
                }
            }
        }
        .alert("Edit Name", isPresented: $showEditNameSheet) {
            TextField("Enter your name", text: $editedName)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                let trimmedName = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedName.isEmpty {
                    viewModel.displayName = trimmedName
                    viewModel.saveProfile()  // Explicitly save profile after updating name
                    print("✅ [PersonalInfoSection] Saved name: \(trimmedName)")
                }
            }
        }
    }
}
