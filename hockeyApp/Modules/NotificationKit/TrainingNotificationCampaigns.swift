import Foundation
import UserNotifications
import UIKit

/// Centralized training-only notification campaigns.
/// - Two cohorts: Free (aggressive) vs Premium (light)
/// - No deep links, no offers — training nudges only
/// - School-day aware (no sends 08:30–15:30 Mon–Fri)
/// - Quiet hours respected (never after ~20:30)
/// - Rolling scheduling to stay under iOS 64-pending limit
final class TrainingNotificationCampaigns {

    static let shared = TrainingNotificationCampaigns()
    private init() {}

    // MARK: - Config
    private enum Cfg {
        // Windows are local time and will be jittered slightly
        // Weekday: 17:30, 20:30 (>= 3h spacing)
        static let weekdayBaseTimes: [(hour: Int, minute: Int)] = [
            (17, 30), (20, 30)
        ]
        // Optional morning to reach 3/day on weekdays (disabled by default)
        static let weekdayMorningTime: (hour: Int, minute: Int) = (7, 30)
        static let weekdayMorningEnabled = false

        // Weekend: 10:30, 14:00, 17:30, 20:30 (>= 3h spacing)
        static let weekendBaseTimes: [(hour: Int, minute: Int)] = [
            (10, 30), (14, 0), (17, 30), (20, 30)
        ]

        // Randomization within window (minutes)
        static let jitterMinutes: Int = 5

        // Spacing and quiet hours
        static let minSpacingHours: Int = 3
        static let schoolBlockStart: (hour: Int, minute: Int) = (8, 30)
        static let schoolBlockEnd: (hour: Int, minute: Int) = (15, 30)

        // Cadence and caps
        static let freeDailyWeekdayCount = 2 // (3 if morning enabled)
        static let freeDailyWeekendCount = 3 // (4 during burst)
        static let freeDailyWeekendBurstCount = 4
        static let freeWeeklyCap = 15

        static let premiumWeeklyDays: Set<Int> = [2, 4, 6, 1] // Mon(2), Wed(4), Fri(6), Sun(1 as per ISO?) We'll handle with Calendar
        static let premiumWeeklyCap = 4

        // Inactivity burst
        static let inactivityDaysForBurst: Int = 3
        static let burstLengthDaysRange: ClosedRange<Int> = 7...14

        // Scheduling horizon (try to approach 60 pending)
        static let horizonDays: Int = 21
        static let maxPendingToUse: Int = 60 // leave headroom for other notifications

        // Storage keys
        static let kLastOpenAt = "tnc_lastOpenAt"
        static let kLastScheduledIds = "tnc_ids"
        static let kRecentTitles = "tnc_titlesRecent"
        static let kBurstUntil = "tnc_burstUntil"
    }

    // MARK: - Public API
    func bootstrap() {
        // Recompute and reschedule on app launch
        scheduleRollingHorizon()
    }

    func onOnboardingComplete() {
        // Treat the completion screen as an app session
        setLastOpen(date: Date())
        scheduleRollingHorizon()
    }

    func onAppOpen() {
        setLastOpen(date: Date())
        scheduleRollingHorizon()
    }

    func onSubscriptionChanged(isPremium: Bool) {
        // Flip cohort and rebuild schedule
        scheduleRollingHorizon()
    }

    func cancelAll() {
        removePreviouslyScheduled()
        saveScheduledIds([])
    }

    // MARK: - Scheduling
    private func scheduleRollingHorizon() {
        Task { @MainActor in
            // Remove our previous pending to avoid duplicates
            removePreviouslyScheduled()

            let now = Date()
            let calendar = Calendar.current
            var scheduledIds: [String] = []

            // Weekly cap tracking by week key
            var weekCounts: [String: Int] = [:]

            // Determine if user is premium
            let isPremium = MonetizationManager.shared.isPremium

            // Burst window (Free only)
            let burstUntil = computeBurstUntil(from: lastOpen())

            dayLoop: for offset in 0..<Cfg.horizonDays {
                guard scheduledIds.count < Cfg.maxPendingToUse else { break }

                guard let date = calendar.date(byAdding: .day, value: offset, to: now) else { continue }
                let isWeekend = calendar.isDateInWeekend(date)

                // Determine desired sends for this day and cohort
                let desiredCount: Int = {
                    if isPremium {
                        // Light cadence: ~4 evenly spaced days per week (Mon, Wed, Fri, Sun)
                        let dow = calendar.component(.weekday, from: date) // 1=Sun..7=Sat
                        // Send on Sun, Mon, Wed, Fri ⇒ approx 4/wk
                        let sendDays: Set<Int> = [1, 2, 4, 6]
                        return sendDays.contains(dow) ? 1 : 0
                    } else {
                        if let burstUntil, date <= burstUntil {
                            // Burst period
                            return isWeekend ? Cfg.freeDailyWeekendBurstCount : (Cfg.weekdayMorningEnabled ? 3 : 2)
                        } else {
                            // Baseline
                            return isWeekend ? Cfg.freeDailyWeekendCount : (Cfg.weekdayMorningEnabled ? 3 : 2)
                        }
                    }
                }()

                if desiredCount == 0 { continue }

                // Weekly cap handling
                let weekKey = weekIdentifier(for: date)
                let cap = isPremium ? Cfg.premiumWeeklyCap : Cfg.freeWeeklyCap
                let used = weekCounts[weekKey] ?? 0
                var remainingThisWeek = max(0, cap - used)
                if remainingThisWeek == 0 { continue }

                let targetForDay = min(desiredCount, remainingThisWeek)

                // Build candidate times for the date
                let candidateTimes = buildTimes(for: date, count: targetForDay, isPremium: isPremium)

                // Per-day spacing and suppression adjustments
                var accepted: [Date] = []
                for t in candidateTimes {
                    if !isAllowedTime(t) { continue }
                    if let lastOpen = lastOpen(), isWithinHours(t, of: lastOpen, hours: 4) {
                        // Session suppression (skip if within 4h of last open)
                        continue
                    }
                    if let last = accepted.last, isWithinHours(t, of: last, hours: Cfg.minSpacingHours) {
                        continue
                    }
                    accepted.append(t)
                    if accepted.count == targetForDay { break }
                }

                if accepted.isEmpty { continue }

                // Schedule messages for these times
                for time in accepted {
                    guard scheduledIds.count < Cfg.maxPendingToUse else { break dayLoop }
                    let pair = nextMessagePair()
                    let id = makeId(for: time)
                    await NotificationKit.scheduleLocalNotification(
                        title: pair.title,
                        body: pair.body,
                        id: id,
                        at: time,
                        categoryId: "TRAINING_REMINDER",
                        threadId: "training",
                        userInfo: ["campaign": "training"]
                    )
                    scheduledIds.append(id)
                    weekCounts[weekKey] = (weekCounts[weekKey] ?? 0) + 1
                }
            }

            saveScheduledIds(scheduledIds)
        }
    }

    // MARK: - Helpers
    private func buildTimes(for date: Date, count: Int, isPremium: Bool) -> [Date] {
        let calendar = Calendar.current
        let isWeekend = calendar.isDateInWeekend(date)

        var baseTimes: [(Int, Int)]
        if isPremium {
            // Single evening slot for premium
            baseTimes = [(18, 30)]
        } else {
            if isWeekend {
                baseTimes = Cfg.weekendBaseTimes
            } else {
                baseTimes = Cfg.weekdayBaseTimes
                if Cfg.weekdayMorningEnabled { baseTimes.insert(Cfg.weekdayMorningTime, at: 0) }
            }
        }

        // Build actual Date values and jitter by ±Cfg.jitterMinutes within same hour
        var results: [Date] = []
        for (h, m) in baseTimes.prefix(count) {
            var comps = calendar.dateComponents([.year, .month, .day], from: date)
            comps.hour = h
            comps.minute = m
            comps.second = 0
            if let base = calendar.date(from: comps) {
                let jitter = Int.random(in: -Cfg.jitterMinutes...Cfg.jitterMinutes)
                if let jittered = calendar.date(byAdding: .minute, value: jitter, to: base) {
                    results.append(jittered)
                } else {
                    results.append(base)
                }
            }
        }
        return results.sorted()
    }

    private func isAllowedTime(_ date: Date) -> Bool {
        let cal = Calendar.current
        let dow = cal.component(.weekday, from: date) // 1=Sun..7=Sat
        if (2...6).contains(dow) { // Mon-Fri school block
            let comps = cal.dateComponents([.hour, .minute], from: date)
            guard let h = comps.hour, let m = comps.minute else { return true }
            let afterStart = (h > Cfg.schoolBlockStart.hour) || (h == Cfg.schoolBlockStart.hour && m >= Cfg.schoolBlockStart.minute)
            let beforeEnd = (h < Cfg.schoolBlockEnd.hour) || (h == Cfg.schoolBlockEnd.hour && m <= Cfg.schoolBlockEnd.minute)
            // Disallow times strictly inside the block
            if afterStart && beforeEnd { return false }
        }
        // End-of-day hard stop ~20:30
        let hm = cal.dateComponents([.hour, .minute], from: date)
        if let h = hm.hour, let m = hm.minute {
            if h > 20 || (h == 20 && m > 30) { return false }
        }
        return true
    }

    private func isWithinHours(_ a: Date, of b: Date, hours: Int) -> Bool {
        abs(a.timeIntervalSince1970 - b.timeIntervalSince1970) < Double(hours) * 3600.0
    }

    private func makeId(for date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyyMMdd-HHmmss"
        fmt.timeZone = .current
        return "tnc-" + fmt.string(from: date)
    }

    private func weekIdentifier(for date: Date) -> String {
        let cal = Calendar.current
        let week = cal.component(.weekOfYear, from: date)
        let year = cal.component(.yearForWeekOfYear, from: date)
        return "\(year)-W\(week)"
    }

    private func computeBurstUntil(from lastOpen: Date?) -> Date? {
        guard let lastOpen else { return nil }
        let cal = Calendar.current
        let since = Date().timeIntervalSince(lastOpen)
        let days = since / 86_400
        guard days >= Double(Cfg.inactivityDaysForBurst) else { return nil }
        // Randomize burst length between 7–14 days from today
        let len = Int.random(in: Cfg.burstLengthDaysRange)
        return cal.date(byAdding: .day, value: len, to: Date())
    }

    // MARK: - Copy rotation
    private struct Pair { let title: String; let body: String }

    private func nextMessagePair() -> Pair {
        // Rotate across a blended pool: training + commitment + competitive
        let pool: [Pair] = trainingPairs + guiltPairs + competitivePairs
        var recent = recentTitles()
        // Pick a title not used in the recent window
        let candidates = pool.filter { !recent.contains($0.title) }
        let chosen = (candidates.randomElement() ?? pool.randomElement()) ?? Pair(title: "Training session", body: "Start now — 3 minutes.")
        // Update recent ring buffer (keep last ~12)
        recent.append(chosen.title)
        if recent.count > 12 { recent.removeFirst(recent.count - 12) }
        saveRecentTitles(recent)
        return chosen
    }

    private let trainingPairs: [Pair] = [
        .init(title: "Quick hockey drill", body: "Start now — 3 minutes."),
        .init(title: "3‑minute warm‑up", body: "Loosen up and move."),
        .init(title: "Stickhandling session", body: "Clean touches now."),
        .init(title: "Shooting practice tonight", body: "A few reps — make it count."),
        .init(title: "Wrist shot practice", body: "Smooth release, quick reps."),
        .init(title: "Slap shot reps", body: "Power + form, short set."),
        .init(title: "Accuracy booster", body: "Aim small, miss small."),
        .init(title: "Speed & control", body: "Short tempo set."),
        .init(title: "Balance + edges", body: "Tight turns tonight."),
        .init(title: "Short skills session", body: "Make it count — start now."),
    ]

    private let guiltPairs: [Pair] = [
        .init(title: "Don’t skip today", body: "Start a quick set."),
        .init(title: "Today can’t be zero", body: "3 minutes now."),
        .init(title: "Momentum fades fast", body: "Keep it alive tonight."),
        .init(title: "Small work > no work", body: "Hit a short drill."),
        .init(title: "Show up small", body: "Tap in and train."),
        .init(title: "One set beats excuses", body: "Start a set."),
        .init(title: "Your stick misses you", body: "3 minutes — let’s go."),
        .init(title: "Make today count", body: "Quick reps before it ends."),
    ]

    private let competitivePairs: [Pair] = [
        .init(title: "Beat your last self", body: "Quick set now."),
        .init(title: "Train like the best", body: "3 minutes tonight."),
        .init(title: "Teammates are grinding", body: "Are you?"),
        .init(title: "Win puck battles", body: "Short power drill."),
        .init(title: "Out‑work your rivals", body: "3 minutes now."),
        .init(title: "Own the slot", body: "Accuracy drill tonight."),
        .init(title: "First to the puck", body: "Footwork set now."),
        .init(title: "Champions train off‑days", body: "This is one."),
    ]

    // MARK: - Persistence
    private func lastOpen() -> Date? {
        if let ts = UserDefaults.standard.object(forKey: Cfg.kLastOpenAt) as? TimeInterval { return Date(timeIntervalSince1970: ts) }
        return nil
    }

    private func setLastOpen(date: Date) {
        UserDefaults.standard.set(date.timeIntervalSince1970, forKey: Cfg.kLastOpenAt)
    }

    private func recentTitles() -> [String] {
        UserDefaults.standard.stringArray(forKey: Cfg.kRecentTitles) ?? []
    }

    private func saveRecentTitles(_ titles: [String]) {
        UserDefaults.standard.set(titles, forKey: Cfg.kRecentTitles)
    }

    private func previouslyScheduledIds() -> [String] {
        UserDefaults.standard.stringArray(forKey: Cfg.kLastScheduledIds) ?? []
    }

    private func saveScheduledIds(_ ids: [String]) {
        UserDefaults.standard.set(ids, forKey: Cfg.kLastScheduledIds)
    }

    private func removePreviouslyScheduled() {
        let ids = previouslyScheduledIds()
        guard !ids.isEmpty else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }
}
