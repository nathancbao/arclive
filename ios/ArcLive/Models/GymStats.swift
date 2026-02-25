import Foundation

struct HourlyCount: Decodable {
    let hour: Int
    let count: Double
}

struct DailyCount: Decodable {
    let date: String
    let count: Int

    /// Short weekday label for chart axes
    var dayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let d = formatter.date(from: date) else { return date }
        formatter.dateFormat = "EEE"
        return formatter.string(from: d)
    }
}

struct GymStats: Decodable {
    let peakHours: [HourlyCount]
    let dailyHeadcount: [DailyCount]
    let exerciseBreakdown: ExerciseBreakdown
}
