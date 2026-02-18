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

    /// Change this to your deployed server URL before shipping.
    /// During local development, use http://localhost:8000
    private let baseURL: URL = {
        let raw = ProcessInfo.processInfo.environment["arclive-production.up.railway.app"] ?? "http://localhost:8000"
        return URL(string: raw)!
    }()

    private let session = URLSession.shared

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    // MARK: - Helpers

    private struct DeviceBody: Encodable {
        // swiftlint:disable:next identifier_name
        let device_id: UUID
    }

    private func devicePayload(for id: UUID) throws -> Data {
        try JSONEncoder().encode(DeviceBody(device_id: id))
    }

    private func post(path: String, body: Data) async throws -> (Data, HTTPURLResponse) {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        let (data, response) = try await session.data(for: request)
        return (data, response as! HTTPURLResponse)
    }

    private func get(path: String) async throws -> (Data, HTTPURLResponse) {
        let request = URLRequest(url: baseURL.appendingPathComponent(path))
        let (data, response) = try await session.data(for: request)
        return (data, response as! HTTPURLResponse)
    }

    // MARK: - Endpoints

    func checkIn(deviceId: UUID) async throws -> Visit {
        let body = try devicePayload(for: deviceId)
        let (data, response) = try await post(path: "checkin", body: body)
        if response.statusCode == 409 { throw APIError.alreadyCheckedIn }
        if response.statusCode >= 400 { throw APIError.serverError(response.statusCode) }
        do { return try decoder.decode(Visit.self, from: data) }
        catch { throw APIError.decodingError(error) }
    }

    func checkOut(deviceId: UUID) async throws -> Visit {
        let body = try devicePayload(for: deviceId)
        let (data, response) = try await post(path: "checkout", body: body)
        if response.statusCode == 404 { throw APIError.notCheckedIn }
        if response.statusCode >= 400 { throw APIError.serverError(response.statusCode) }
        do { return try decoder.decode(Visit.self, from: data) }
        catch { throw APIError.decodingError(error) }
    }

    func getOccupancy() async throws -> OccupancyResponse {
        let (data, response) = try await get(path: "occupancy")
        if response.statusCode >= 400 { throw APIError.serverError(response.statusCode) }
        do { return try decoder.decode(OccupancyResponse.self, from: data) }
        catch { throw APIError.decodingError(error) }
    }
}
