import SwiftUI

struct AIFeatureKitSection: View {
    @Environment(\.theme) var theme
    @AppStorage("showRawAnalyzerSections") private var showRawAnalyzerSections = false

    private var aiDebugBinding: Binding<Bool> {
        Binding(
            get: { AIDebugLogger.shared.isEnabled },
            set: { AIDebugLogger.shared.isEnabled = $0 }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "ant.circle.fill")
                        .foregroundColor(.white.opacity(0.85))
                        .frame(width: 24)
                    Text("AI Debug Logging")
                        .foregroundColor(.white)
                    Spacer()
                    Toggle("", isOn: aiDebugBinding)
                        .tint(theme.primary)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.3))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                )

                HStack {
                    Image(systemName: "doc.text.magnifyingglass")
                        .foregroundColor(.white.opacity(0.85))
                        .frame(width: 24)
                    Text("Show Raw Analyzer Sections")
                        .foregroundColor(.white)
                    Spacer()
                    Toggle("", isOn: $showRawAnalyzerSections)
                        .tint(theme.primary)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.3))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                )

                NavigationLink(destination: AIDebugLogsView()) {
                    HStack {
                        Image(systemName: "list.bullet.rectangle")
                            .foregroundColor(.white.opacity(0.85))
                            .frame(width: 24)
                        Text("View AI Logs")
                            .foregroundColor(.white)
                        Spacer()

                        if AIDebugLogger.shared.logs.count > 0 {
                            Text("\(AIDebugLogger.shared.logs.count)")
                                .font(.caption)
                                .foregroundColor(.black)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.white)
                                .cornerRadius(10)
                        }

                        Image(systemName: "chevron.right")
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.3))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                    )
                }
            }
        }
        .padding(.horizontal, 20)
    }
}