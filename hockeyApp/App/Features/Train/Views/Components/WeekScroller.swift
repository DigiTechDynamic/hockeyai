import SwiftUI

struct WeekScroller: View {
    @Environment(\.theme) var theme
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedDate: Date = Date()
    @State private var anchorDate: Date = Date()

    var onSelect: ((Date) -> Void)? = nil

    private let calendar = Calendar.current
    private let cardSpacing: CGFloat = 8 // Space between cards

    private var weeksToShow: [[Date]] {
        // Show 5 weeks (current week + 2 before + 2 after)
        let currentWeekStart = startOfWeek(for: anchorDate)

        return (-2...2).map { weekOffset in
            let weekStart = calendar.date(byAdding: .day, value: weekOffset * 7, to: currentWeekStart) ?? currentWeekStart
            return (0..<7).compactMap { dayOffset in
                calendar.date(byAdding: .day, value: dayOffset, to: weekStart)
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("THIS WEEK")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(theme.textSecondary.opacity(0.7))
                    .tracking(0.5)

                Spacer()

                // Week navigation arrows
                HStack(spacing: 8) {
                    navButton(system: "chevron.left") {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            anchorDate = calendar.date(byAdding: .day, value: -7, to: anchorDate) ?? anchorDate
                        }
                        HapticManager.shared.playImpact(style: .light)
                    }
                    navButton(system: "chevron.right") {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            anchorDate = calendar.date(byAdding: .day, value: 7, to: anchorDate) ?? anchorDate
                        }
                        HapticManager.shared.playImpact(style: .light)
                    }
                }
            }
            .padding(.horizontal, 4) // Add horizontal padding to header

            // Week view (arrow navigation only - no scrolling)
            GeometryReader { geometry in
                // Show only current week (no ScrollView)
                weekView(week: weeksToShow[2], screenWidth: geometry.size.width) // Index 2 = current week
                    .padding(.vertical, 12) // Vertical padding for shadows
            }
            .frame(height: 86)
            .padding(.horizontal, 4) // Add horizontal padding to align with header
        }
        .onAppear {
            // Always reset to today when view appears
            resetToToday()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            // Reset to today when app becomes active
            if newPhase == .active {
                resetToToday()
            }
        }
    }

    private func weekView(week: [Date], screenWidth: CGFloat) -> some View {
        HStack(spacing: cardSpacing) {
            ForEach(week, id: \.self) { day in
                dayChip(for: day, width: calculateCardWidth(screenWidth: screenWidth))
            }
        }
        .frame(width: screenWidth) // Each week takes full screen width
    }

    private func dayChip(for date: Date, width: CGFloat) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(date)

        return Button {
            withAnimation(.spring(response: 0.25)) { selectedDate = date }
            HapticManager.shared.playSelectionFeedback()
            onSelect?(date)
        } label: {
            VStack(spacing: 6) {
                Text(weekdayAbbrev(for: date))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(isSelected ? .black : theme.textSecondary)

                Text(dayNumber(for: date))
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundColor(isSelected ? .black : .white)
            }
            .frame(width: width)
            .padding(.vertical, 10)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(colors: [theme.primary, theme.primary.opacity(0.9)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    } else if isToday {
                        theme.surface.opacity(0.6)
                    } else {
                        theme.surface.opacity(0.35)
                    }
                }
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? theme.primary : theme.primary.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: isSelected ? theme.primary.opacity(0.45) : .clear, radius: 10, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func navButton(system: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(theme.textSecondary)
                .frame(width: 28, height: 28)
                .background(Circle().fill(theme.surface.opacity(0.5)))
                .overlay(Circle().stroke(theme.primary.opacity(0.25), lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Helper Functions

    private func calculateCardWidth(screenWidth: CGFloat) -> CGFloat {
        // Calculate width: (screen width - total spacing) / 7 cards
        let totalSpacing = cardSpacing * 6 // 6 spaces between 7 cards
        return (screenWidth - totalSpacing) / 7
    }

    private func resetToToday() {
        let today = Date()
        selectedDate = today
        anchorDate = today
    }

    private func weekdayAbbrev(for date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale.current
        f.dateFormat = "EEE"
        return f.string(from: date).uppercased()
    }

    private func dayNumber(for date: Date) -> String {
        let day = calendar.component(.day, from: date)
        return "\(day)"
    }

    private func startOfWeek(for date: Date) -> Date {
        let comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: comps) ?? date
    }
}

#Preview {
    WeekScroller()
        .padding()
        .background(Color.black)
}
