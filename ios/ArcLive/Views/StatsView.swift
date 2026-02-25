import SwiftUI
import Charts

struct StatsView: View {
    @StateObject private var vm = StatsViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                if vm.isLoading && vm.gymStats == nil {
                    ProgressView()
                        .padding(.top, 80)
                        .frame(maxWidth: .infinity)
                } else {
                    VStack(spacing: 28) {
                        if let personal = vm.personalStats {
                            personalSection(personal)
                        }

                        if let gym = vm.gymStats {
                            peakHoursSection(gym)
                            dailyHeadcountSection(gym)
                            exerciseBreakdownSection(gym)
                        }

                        if let error = vm.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Stats")
            .refreshable { await vm.refresh() }
            .task { await vm.refresh() }
        }
    }

    // MARK: - Personal Stats

    private func personalSection(_ stats: PersonalStats) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("My Stats")

            HStack(spacing: 12) {
                statCard(value: "\(stats.totalVisits)", label: "Visits")
                statCard(value: stats.formattedTotalTime, label: "Time")
                statCard(value: "\(stats.streak)", label: "Streak 🔥")
            }

            if let fav = stats.favouriteExercise {
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .font(.footnote)
                    Text("Favourite: ")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    + Text(fav.fullName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(fav.color)
                }
            }

            if !stats.recentVisits.isEmpty {
                recentVisits(stats.recentVisits)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func statCard(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.weight(.bold))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 14))
    }

    private func recentVisits(_ visits: [VisitRecord]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Visits")
                .font(.subheadline.weight(.semibold))

            ForEach(visits.prefix(5)) { visit in
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(visit.checkInTime.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                        if let ex = visit.exerciseType {
                            Text(ex.fullName)
                                .font(.caption2)
                                .foregroundStyle(ex.color)
                        }
                    }
                    Spacer()
                    Text(visit.formattedDuration)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
                Divider()
            }
        }
    }

    // MARK: - Peak Hours

    private func peakHoursSection(_ stats: GymStats) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Peak Hours")
            Text("Avg daily check-ins per hour · last 30 days")
                .font(.caption)
                .foregroundStyle(.secondary)

            Chart(stats.peakHours, id: \.hour) { item in
                BarMark(
                    x: .value("Hour", item.hour),
                    y: .value("Avg", item.count)
                )
                .foregroundStyle(Color.blue.gradient)
                .cornerRadius(3)
            }
            .chartXScale(domain: 0...23)
            .chartXAxis {
                AxisMarks(values: [0, 6, 12, 18, 23]) { val in
                    AxisValueLabel {
                        if let h = val.as(Int.self) {
                            Text(hourLabel(h))
                                .font(.caption2)
                        }
                    }
                    AxisGridLine()
                }
            }
            .frame(height: 160)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func hourLabel(_ h: Int) -> String {
        switch h {
        case 0:  return "12am"
        case 12: return "12pm"
        default: return h < 12 ? "\(h)am" : "\(h - 12)pm"
        }
    }

    // MARK: - Daily Headcount

    private func dailyHeadcountSection(_ stats: GymStats) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Daily Headcount")
            Text("Unique visitors per day · last 7 days")
                .font(.caption)
                .foregroundStyle(.secondary)

            Chart(stats.dailyHeadcount, id: \.date) { item in
                BarMark(
                    x: .value("Day", item.dayLabel),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(Color.indigo.gradient)
                .cornerRadius(3)
            }
            .frame(height: 140)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Exercise Breakdown

    private func exerciseBreakdownSection(_ stats: GymStats) -> some View {
        let points = ExerciseType.allCases.map { ex in
            (exercise: ex, count: stats.exerciseBreakdown.count(for: ex))
        }
        let total = points.map(\.count).reduce(0, +)

        return VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Exercise Breakdown")
            Text("Check-ins by type · last 30 days")
                .font(.caption)
                .foregroundStyle(.secondary)

            Chart {
                ForEach(points, id: \.exercise) { point in
                    BarMark(
                        x: .value("Type", point.exercise.abbreviation),
                        y: .value("Count", point.count)
                    )
                    .foregroundStyle(point.exercise.color.gradient)
                    .cornerRadius(3)
                    .annotation(position: .top, alignment: .center) {
                        if total > 0 && point.count > 0 {
                            Text("\(Int(Double(point.count) / Double(total) * 100))%")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .frame(height: 150)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 16)
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
    }
}
