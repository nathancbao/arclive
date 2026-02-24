import Foundation

struct Visit: Decodable {
    let id: UUID
    let deviceId: UUID
    let checkInTime: Date
    let checkOutTime: Date?
    let exerciseType: ExerciseType?

    enum CodingKeys: String, CodingKey {
        case id
        case deviceId     = "device_id"
        case checkInTime  = "check_in_time"
        case checkOutTime = "check_out_time"
        case exerciseType = "exercise_type"
    }
}
