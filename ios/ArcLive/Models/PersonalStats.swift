import Foundation

struct VisitRecord: Decodable, Identifiable {
    let id: UUID
    let checkInTime: Date
    let checkOutTime: Date?
    let exerciseType: ExerciseType?
    let durationMinutes: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case checkInTime     = "check_in_time"
        case checkOutTime    = "check_out_time"
        case exerciseType    = "exercise_type"
        case durationMinutes = "duration_minutes"
    }

    var formattedDuration: String {
        guard let mins = durationMinutes, mins > 0 else { return "—" }
        if mins < 60 { return "\(mins)m" }
        return "\(mins / 60)h \(mins % 60)m"
    }
}

struct PersonalStats: Decodable {
    let totalVisits: Int
    let totalMinutes: Int
    let streak: Int
    let favouriteExercise: ExerciseType?
    let recentVisits: [VisitRecord]

    var formattedTotalTime: String {
        if totalMinutes < 60 { return "\(totalMinutes)m" }
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }
}
