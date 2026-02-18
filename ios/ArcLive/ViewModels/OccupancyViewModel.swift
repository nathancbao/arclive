import SwiftUI

@MainActor
final class OccupancyViewModel: ObservableObject {
    @Published var count: Int = 0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let api = APIClient.shared

    func refresh() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let response = try await api.getOccupancy()
            count = response.count
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
