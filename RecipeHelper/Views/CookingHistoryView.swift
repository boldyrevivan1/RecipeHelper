import SwiftUI

enum HistoryRange: String, CaseIterable, Identifiable {
    case week   = "Week"
    case month  = "Month"
    case year   = "Year"
    case all    = "All"
    case custom = "Custom"

    var id: String { rawValue }

    func interval(now: Date = Date()) -> DateInterval? {
        let cal = Calendar.current
        let end = now
        switch self {
        case .week:   return DateInterval(start: cal.date(byAdding: .day,   value: -7,  to: end)!, end: end)
        case .month:  return DateInterval(start: cal.date(byAdding: .month, value: -1,  to: end)!, end: end)
        case .year:   return DateInterval(start: cal.date(byAdding: .year,  value: -1,  to: end)!, end: end)
        case .all, .custom: return nil
        }
    }
}

struct CookingHistoryView: View {
    @ObservedObject private var fs = FirestoreService.shared

    @State private var range: HistoryRange = .all
    @State private var customStart = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
    @State private var customEnd   = Date()
    @State private var showCustomSheet = false

    private var filteredHistory: [FSCookingHistory] {
        let items = fs.history.sorted { $0.cookedAt > $1.cookedAt }
        let interval: DateInterval?
        switch range {
        case .custom:

            let endOfDay = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: customEnd) ?? customEnd
            interval = DateInterval(start: Calendar.current.startOfDay(for: customStart), end: endOfDay)
        default:
            interval = range.interval()
        }
        guard let iv = interval else { return items }
        return items.filter { iv.contains($0.cookedAt) }
    }

    private var groupedByDay: [(date: Date, items: [FSCookingHistory])] {
        let cal = Calendar.current
        let groups = Dictionary(grouping: filteredHistory) { cal.startOfDay(for: $0.cookedAt) }
        return groups
            .map { (date: $0.key, items: $0.value) }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        List {
            Section {
                rangePicker
                if range == .custom { customDateRow }
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))

            if filteredHistory.isEmpty {
                Section {
                    ContentUnavailableView(
                        "No cooking sessions",
                        systemImage: "fork.knife",
                        description: Text(range == .all
                            ? "Start cooking recipes to see your history here"
                            : "Nothing cooked in this period. Try a wider range.")
                    )
                    .listRowBackground(Color.clear)
                }
            } else {
                Section {
                    StatsHeader(history: filteredHistory, rangeLabel: rangeLabel)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16))
                }

                ForEach(groupedByDay, id: \.date) { day in
                    Section(header: Text(dayLabel(day.date))) {
                        ForEach(day.items) { entry in
                            HistoryRow(entry: entry)
                        }
                        .onDelete { offsets in
                            deleteItems(day: day, offsets: offsets)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Cooking History")
        .navigationBarTitleDisplayMode(.large)
    }

    private var rangePicker: some View {
        Picker("Range", selection: $range) {
            ForEach(HistoryRange.allCases) { r in
                Text(r.rawValue).tag(r)
            }
        }
        .pickerStyle(.segmented)
    }

    private var customDateRow: some View {
        VStack(spacing: 8) {
            DatePicker("From", selection: $customStart, in: ...customEnd, displayedComponents: .date)
            DatePicker("To",   selection: $customEnd,   in: customStart...Date(), displayedComponents: .date)
        }
        .font(.subheadline)
    }

    private var rangeLabel: String {
        switch range {
        case .week:   return "Last 7 days"
        case .month:  return "Last 30 days"
        case .year:   return "Last year"
        case .all:    return "All time"
        case .custom:
            let f = DateFormatter(); f.dateStyle = .medium
            return "\(f.string(from: customStart)) – \(f.string(from: customEnd))"
        }
    }

    private func dayLabel(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date)     { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        let f = DateFormatter()
        f.dateFormat = cal.isDate(date, equalTo: Date(), toGranularity: .year) ? "MMMM d" : "MMMM d, yyyy"
        return f.string(from: date)
    }

    private func deleteItems(day: (date: Date, items: [FSCookingHistory]), offsets: IndexSet) {
        Task {
            for i in offsets {
                if let id = day.items[i].id {
                    try? await fs.deleteHistory(id: id)
                }
            }
        }
    }
}

private struct StatsHeader: View {
    let history: [FSCookingHistory]
    let rangeLabel: String

    private var total: Int { history.count }

    private var uniqueDays: [Date] {
        let cal = Calendar.current
        return Array(Set(history.map { cal.startOfDay(for: $0.cookedAt) })).sorted(by: >)
    }

    private var currentStreak: Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
        let days = Set(uniqueDays)

        var cursor: Date
        if days.contains(today)          { cursor = today }
        else if days.contains(yesterday) { cursor = yesterday }
        else { return 0 }

        var streak = 0
        while days.contains(cursor) {
            streak += 1
            cursor = cal.date(byAdding: .day, value: -1, to: cursor)!
        }
        return streak
    }

    private var topCuisines: [(name: String, count: Int)] {
        let pairs = history.compactMap { $0.cuisineType }
        let grouped = Dictionary(grouping: pairs, by: { $0 }).mapValues { $0.count }
        return grouped
            .map { (name: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    private var topRecipe: (title: String, count: Int)? {
        let grouped = Dictionary(grouping: history.map { $0.recipeTitle }, by: { $0 }).mapValues { $0.count }
        guard let best = grouped.max(by: { $0.value < $1.value }) else { return nil }
        return (title: best.key, count: best.value)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                StatCard(icon: "fork.knife",
                         value: "\(total)",
                         label: total == 1 ? "recipe" : "recipes",
                         tint: .orange)
                StatCard(icon: "flame.fill",
                         value: "\(currentStreak)",
                         label: currentStreak == 1 ? "day streak" : "day streak",
                         tint: .red)
            }

            if let top = topRecipe, top.count >= 2 {
                InfoRow(icon: "star.fill", tint: .yellow,
                        title: "Favorite",
                        detail: "\(top.title) • \(top.count)×")
            }

            if !topCuisines.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Top cuisines", systemImage: "globe")
                        .font(.caption).fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    VStack(spacing: 4) {
                        ForEach(topCuisines.prefix(3), id: \.name) { c in
                            CuisineBar(name: c.name, count: c.count, max: topCuisines.first!.count)
                        }
                    }
                }
            }

            Text(rangeLabel)
                .font(.caption2).foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: icon).font(.caption).foregroundStyle(tint)
            Text(value).font(.title2).fontWeight(.bold)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(tint.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct InfoRow: View {
    let icon: String
    let tint: Color
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon).foregroundStyle(tint).font(.caption)
            Text(title).font(.caption).fontWeight(.semibold).foregroundStyle(.secondary)
            Text(detail).font(.caption).foregroundStyle(.primary).lineLimit(1)
            Spacer()
        }
    }
}

private struct CuisineBar: View {
    let name: String
    let count: Int
    let max: Int

    var body: some View {
        HStack(spacing: 8) {
            Text(name).font(.caption).frame(width: 80, alignment: .leading).lineLimit(1)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.tertiarySystemFill))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.blue)
                        .frame(width: geo.size.width * CGFloat(count) / CGFloat(Swift.max(max, 1)),
                               height: 6)
                }
            }
            .frame(height: 6)
            Text("\(count)").font(.caption2).foregroundStyle(.secondary)
                .frame(width: 24, alignment: .trailing)
        }
    }
}

private struct HistoryRow: View {
    let entry: FSCookingHistory

    var body: some View {
        HStack(spacing: 12) {
            CachedAsyncImage(url: entry.recipeImageURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.15)
                    .overlay(Image(systemName: "fork.knife").foregroundStyle(.gray))
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.recipeTitle).font(.subheadline).fontWeight(.medium)
                HStack(spacing: 6) {
                    if let cuisine = entry.cuisineType {
                        Text(cuisine).font(.caption).foregroundStyle(.blue)
                        Text("·").foregroundStyle(.secondary)
                    }
                    Text(timeLabel(entry.cookedAt)).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green).font(.title3)
        }
        .padding(.vertical, 2)
    }

    private func timeLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }
}

#Preview {
    NavigationStack {
        CookingHistoryView()
    }
}
