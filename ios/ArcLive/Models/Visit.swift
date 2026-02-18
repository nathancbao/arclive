import Foundation

/// Matches the VisitResponse schema returned by the backend.
struct Visit: Decodable {
    let id: UUID
    let deviceId: UUID
    let checkInTime: Date
    let checkOutTime: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case deviceId      = "device_id"
        case checkInTime   = "check_in_time"
        case checkOutTime  = "check_out_time"
    }
}
