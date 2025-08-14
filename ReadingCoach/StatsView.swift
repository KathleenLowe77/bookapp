import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query private var books: [Book]
    @State private var range: RangeType = .week

    enum RangeType: String, CaseIterable, Identifiable {
        case week = "Week"
        case month = "Month"
        var id: String { rawValue }
        var days: Int { self == .week ? 7 : 30 }
    }

    struct DayStat: Identifiable {
        let id = UUID()
        let date: Date
        let pages: Int
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Picker("Range", selection: $range) {
                    ForEach(RangeType.allCases) { r in
                        Text(r.rawValue).tag(r)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                let data = makeStats(days: range.days)

                if data.isEmpty {
                    ContentUnavailableView("No data yet", systemImage: "chart.bar",
                                           description: Text("Log your reading to see charts."))
                } else {
                    Chart(data) { item in
                        BarMark(
                            x: .value("Date", item.date, unit: .day),
                            y: .value("Pages", item.pages)
                        )
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day, count: range == .week ? 1 : 5)) { value in
                            AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer(minLength: 0)
            }
            .navigationTitle("Stats")
        }
    }

    private func makeStats(days: Int) -> [DayStat] {
        let cal = Calendar.current
        let end = cal.startOfDay(for: Date())
        let start = cal.date(byAdding: .day, value: -days + 1, to: end)!
        // Collect sessions
        let sessions = books.flatMap { $0.sessions }
            .filter { $0.date >= start && $0.date < cal.date(byAdding: .day, value: 1, to: end)! }

        // Sum per day
        var buckets: [Date: Int] = [:]
        for i in 0..<days {
            if let d = cal.date(byAdding: .day, value: i, to: start) {
                buckets[cal.startOfDay(for: d)] = 0
            }
        }
        for s in sessions {
            let d = cal.startOfDay(for: s.date)
            buckets[d, default: 0] += s.pagesRead
        }
        return buckets.keys.sorted().map { DayStat(date: $0, pages: buckets[$0] ?? 0) }
    }
}
