import SwiftUI

// MARK: - Body Scan Card
/// Card for Profile page showing body scan status with two states:
/// - Empty: Shows instructions card with "Start Body Scan" button (matches Stick Analyzer flow)
/// - Completed: Shows thumbnail and capture date with "Rescan" option
struct BodyScanCard: View {
    @Environment(\.theme) var theme
    @State private var bodyScanResult: BodyScanResult?
    @State private var showBodyScan = false

    var body: some View {
        Group {
            if let result = bodyScanResult {
                // Completed state - has a scan
                completedStateCard(result: result)
            } else {
                // Empty state - no scan yet (matches Stick Analyzer flow design)
                emptyStateCard
            }
        }
        .onAppear {
            loadBodyScan()
        }
        .fullScreenCover(isPresented: $showBodyScan) {
            BodyScanView(
                onComplete: { result in
                    BodyScanAnalytics.trackCaptured(source: .profilePage)
                    BodyScanStorage.shared.save(result)
                    bodyScanResult = result
                    showBodyScan = false
                },
                onCancel: {
                    BodyScanAnalytics.trackCancelled(source: .profilePage)
                    showBodyScan = false
                },
                analyticsSource: .profilePage
            )
        }
    }

    // MARK: - Empty State Card
    private var emptyStateCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.stand")
                .font(.system(size: 50))
                .foregroundColor(theme.primary)

            Text("Body Scan")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(theme.text)

            Text("Capture your body proportions for better stick recommendations")
                .font(.system(size: 14))
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)

            // Start button inside card
            Button(action: {
                HapticManager.shared.playSelection()
                showBodyScan = true
            }) {
                HStack {
                    Image(systemName: "figure.stand")
                    Text("Start Body Scan")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(theme.primary)
                .cornerRadius(theme.cornerRadius)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.top, 8)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .fill(theme.surface)
        )
    }

    // MARK: - Completed State Card
    private func completedStateCard(result: BodyScanResult) -> some View {
        ProfileSectionCard {
            VStack(spacing: theme.spacing.lg) {
                // Header
                HStack {
                    Image(systemName: "figure.stand")
                        .font(theme.fonts.body)
                        .foregroundColor(theme.primary)
                    Text("Body Scan")
                        .font(theme.fonts.headline)
                        .foregroundColor(.white)
                    Spacer()
                }

                Divider().background(Color.white.opacity(0.1))

                HStack(spacing: 16) {
                    // Thumbnail
                    if let image = result.loadImage() {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(theme.primary.opacity(0.3), lineWidth: 1)
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(theme.surface)
                            .frame(width: 60, height: 80)
                            .overlay(
                                Image(systemName: "figure.stand")
                                    .foregroundColor(theme.textSecondary)
                            )
                    }

                    // Info
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 14))
                            Text("Body scan captured")
                                .font(theme.fonts.body)
                                .foregroundColor(.white)
                        }

                        Text("Captured \(formattedDate(result.scanDate))")
                            .font(theme.fonts.caption)
                            .foregroundColor(theme.textSecondary)
                    }

                    Spacer()
                }

                // Rescan button
                Button(action: {
                    HapticManager.shared.playSelection()
                    showBodyScan = true
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Rescan")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(theme.primary.opacity(0.12))
                    .cornerRadius(theme.cornerRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.cornerRadius)
                            .stroke(theme.primary.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    // MARK: - Helper Views
    private func instructionRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(theme.primary)
                .frame(width: 24)
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(theme.textSecondary)
            Spacer()
        }
    }

    // MARK: - Helper Methods
    private func loadBodyScan() {
        bodyScanResult = BodyScanStorage.shared.load()
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Preview
#if DEBUG
struct BodyScanCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            BodyScanCard()
        }
        .padding()
        .background(Color.black)
    }
}
#endif
