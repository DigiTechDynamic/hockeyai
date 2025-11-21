import SwiftUI

// MARK: - Screen Tracking Debug Overlay

/// Debug overlay that shows real-time screen tracking
/// Only visible when debug mode is enabled
public struct ScreenTrackingDebugOverlay: ViewModifier {
    @ObservedObject private var tracker = ScreenTracker.shared
    @State private var isExpanded = false

    public func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            content

            if tracker.isDebugEnabled {
                VStack(spacing: 0) {
                    if isExpanded {
                        debugPanel
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    debugBar
                }
                .animation(.spring(response: 0.3), value: isExpanded)
            }
        }
    }

    // MARK: - Debug Bar (Collapsed)

    private var debugBar: some View {
        HStack {
            Image(systemName: "chart.bar.fill")
                .foregroundColor(.white)

            if let latestEntry = tracker.debugEntries.first {
                Text(latestEntry.screenName)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
                    .lineLimit(1)
            } else {
                Text("No screens tracked")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()

            Text("\(tracker.uniqueScreens.count)")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.2))
                .cornerRadius(8)

            Button(action: { isExpanded.toggle() }) {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                    .foregroundColor(.white)
                    .font(.system(size: 12, weight: .bold))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.85))
        .debugCornerRadius(isExpanded ? 0 : 12, corners: isExpanded ? [] : [.topLeft, .topRight])
        .shadow(color: .black.opacity(0.3), radius: 10, y: -5)
    }

    // MARK: - Debug Panel (Expanded)

    private var debugPanel: some View {
        VStack(spacing: 0) {
            // Stats Header
            HStack(spacing: 16) {
                statItem(
                    title: "Unique",
                    value: "\(tracker.uniqueScreens.count)",
                    icon: "square.grid.2x2"
                )

                Divider()
                    .background(Color.white.opacity(0.3))
                    .frame(height: 30)

                statItem(
                    title: "Total",
                    value: "\(tracker.screenViewCounts.values.reduce(0, +))",
                    icon: "eye"
                )

                Spacer()

                Button(action: { tracker.clearDebugEntries() }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.system(size: 14))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.5))

            Divider()
                .background(Color.white.opacity(0.2))

            // Screen List
            ScrollView {
                LazyVStack(spacing: 1) {
                    ForEach(tracker.debugEntries) { entry in
                        debugEntry(entry)
                    }
                }
            }
            .frame(maxHeight: 300)
        }
        .background(Color.black.opacity(0.9))
    }

    // MARK: - Components

    private func statItem(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.7))
                .font(.system(size: 14))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))

                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
        }
    }

    private func debugEntry(_ entry: ScreenTracker.DebugEntry) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.screenName)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)

                Spacer()

                Text(entry.formattedTime)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
            }

            if let viewCount = tracker.screenViewCounts[entry.screenName] {
                Text("Views: \(viewCount)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.green.opacity(0.8))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.05))
    }
}

// MARK: - View Extension

public extension View {
    /// Add the screen tracking debug overlay
    /// Automatically shows when debug mode is enabled
    func screenTrackingDebug() -> some View {
        modifier(ScreenTrackingDebugOverlay())
    }
}

// MARK: - Helper Extension

private extension View {
    func debugCornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(DebugRoundedCorner(radius: radius, corners: corners))
    }
}

private struct DebugRoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
