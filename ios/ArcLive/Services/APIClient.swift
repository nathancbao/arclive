import Foundation

// MARK: - Errors

enum APIError: LocalizedError {
    case alreadyCheckedIn
    case notCheckedIn
    case serverError(Int)
    case decodingError(Error)
    case unknown

    var errorDescription: String? {
        switch self {
        case .alreadyCheckedIn:        return "You're already checked in."
        case .notCheckedIn:            return "You're not currently checked in."
        case .serverError(let code):  return "Server error (HTTP \(code))."
        case .decodingError(let err): return "Could not read server response: \(err.localizedDescription)"
        case .unknown:                return "An unknown error occurred."
        }
    }
}

// MARK: - APIClient

final class APIClient {
    static let shared = APIClient()

    private let baseURL: URL = {
        let raw = ProcessInfo.processInfo.environment["API_BASE_URL"] ?? "https://arclive-production.up.railway.app"
        return URL(string: raw)!
    }()

    private let session = URLSession.shared

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    // MARK: - Request bodies

    private struct CheckInBody: Encodable {
        let device_id: UUID
        let exercise_type: String
    }

    private struct CheckOutBody: Encodable {
        let device_id: UUID
    }

    // MARK: - Helpers

    private func post(path: String, body: some Encodable) async throws -> (Data, HTTPURLResponse) {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await session.data(for: request)
        return (data, response as! HTTPURLResponse)
    }

    private func get(path: String, queryItems: [URLQueryItem] = []) async throws -> (Data, HTTPURLResponse) {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        if !queryItems.isEmpty { components.queryItems = queryItems }
        let request = URLRequest(url: components.url!)
        let (data, response) = try await session.data(for: request)
        return (data, response as! HTTPURLResponse)
    }

    private func decoded<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do { return try decoder.decode(type, from: data) }
        catch { throw APIError.decodingError(error) }
    }

    // MARK: - Endpoints

    func checkIn(deviceId: UUID, exercise: ExerciseType) async throws -> Visit {
        let body = CheckInBody(device_id: deviceId, exercise_type: exercise.rawValue)
        let (data, response) = try await post(path: "checkin", body: body)
        if response.statusCode == 409 { throw APIError.alreadyCheckedIn }
        if response.statusCode >= 400 { throw APIError.serverError(response.statusCode) }
        return try decoded(Visit.self, from: data)
    }

    func checkOut(deviceId: UUID) async throws -> Visit {
        let body = CheckOutBody(device_id: deviceId)
        let (data, response) = try await post(path: "checkout", body: body)
        if response.statusCode == 404 { throw APIError.notCheckedIn }
        if response.statusCode >= 400 { throw APIError.serverError(response.statusCode) }
        return try decoded(Visit.self, from: data)
    }

    func getOccupancy() async throws -> OccupancyResponse {
        let (data, response) = try await get(path: "occupancy")
        if response.statusCode >= 400 { throw APIError.serverError(response.statusCode) }
        return try decoded(OccupancyResponse.self, from: data)
    }

    func getGymStats() async throws -> GymStats {
        let (data, response) = try await get(path: "stats/gym")
        if response.statusCode >= 400 { throw APIError.serverError(response.statusCode) }
        return try decoded(GymStats.self, from: data)
    }

    func getPersonalStats(deviceId: UUID) async throws -> PersonalStats {
        let (data, response) = try await get(
            path: "stats/me",
            queryItems: [URLQueryItem(name: "device_id", value: deviceId.uuidString.lowercased())]
        )
        if response.statusCode >= 400 { throw APIError.serverError(response.statusCode) }
        return try decoded(PersonalStats.self, from: data)
    }
}
