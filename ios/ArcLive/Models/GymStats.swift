import Foundation

struct HourlyCount: Decodable {
    let hour: Int
    let count: Double
}

struct GymStats: Decodable {
    let peakHours: [HourlyCount]
    let exerciseBreakdown: ExerciseBreakdown
}
