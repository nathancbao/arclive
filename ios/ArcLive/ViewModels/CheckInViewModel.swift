import SwiftUI

@MainActor
final class CheckInViewModel: ObservableObject {
    @Published var isCheckedIn: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let deviceId = DeviceIdentifier.id
    private let api = APIClient.shared

    func checkIn() async {
        await perform { [self] in
            _ = try await api.checkIn(deviceId: deviceId)
            isCheckedIn = true
        }
    }

    func checkOut() async {
        await perform { [self] in
            _ = try await api.checkOut(deviceId: deviceId)
            isCheckedIn = false
        }
    }

    // MARK: - Private

    private func perform(_ action: () async throws -> Void) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await action()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
