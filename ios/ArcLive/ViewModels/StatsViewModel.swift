import Foundation

@MainActor
final class StatsViewModel: ObservableObject {
    @Published var gymStats: GymStats?
    @Published var personalStats: PersonalStats?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let deviceId = DeviceIdentifier.id

    func refresh() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            async let gym     = APIClient.shared.getGymStats()
            async let personal = APIClient.shared.getPersonalStats(deviceId: deviceId)
            let (g, p) = try await (gym, personal)
            gymStats     = g
            personalStats = p
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
