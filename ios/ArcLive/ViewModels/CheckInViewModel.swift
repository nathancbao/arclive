import SwiftUI

@MainActor
final class CheckInViewModel: ObservableObject {
    @Published var isCheckedIn: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showExercisePicker: Bool = false

    private let deviceId = DeviceIdentifier.id
    private let api = APIClient.shared

    func requestCheckIn() {
        showExercisePicker = true
    }

    func checkIn(exercise: ExerciseType) async {
        showExercisePicker = false
        await perform { [self] in
            _ = try await api.checkIn(deviceId: deviceId, exercise: exercise)
            isCheckedIn = true
        }
    }

    func checkOut() async {
        await perform { [self] in
            _ = try await api.checkOut(deviceId: deviceId)
            isCheckedIn = false
        }
    }

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
