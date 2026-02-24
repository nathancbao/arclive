import SwiftUI

struct RingSegment: Identifiable, Equatable {
    let id = UUID()
    let exercise: ExerciseType
    let start: Double   // 0...1 arc fraction
    let end: Double     // 0...1 arc fraction

    var fraction: Double { end - start }

    // Angle in radians from the top of the ring, used to position labels
    var midAngleRadians: Double {
        ((start + end) / 2) * 2 * .pi - .pi / 2
    }

    static func == (lhs: RingSegment, rhs: RingSegment) -> Bool {
        lhs.exercise == rhs.exercise && lhs.start == rhs.start && lhs.end == rhs.end
    }
}

@MainActor
final class OccupancyViewModel: ObservableObject {
    @Published var count: Int = 0
    @Published var breakdown: ExerciseBreakdown = ExerciseBreakdown()
    @Published var segments: [RingSegment] = []
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
            breakdown = response.breakdown
            segments = buildSegments(breakdown: response.breakdown, total: response.count)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func buildSegments(breakdown: ExerciseBreakdown, total: Int) -> [RingSegment] {
        guard total > 0 else { return [] }

        let gapFraction = 0.012
        var result: [RingSegment] = []
        var cursor = 0.0

        let active = ExerciseType.allCases.filter { breakdown.count(for: $0) > 0 }

        for exercise in active {
            let fraction = Double(breakdown.count(for: exercise)) / Double(total)
            let gap = active.count > 1 ? gapFraction : 0.0
            let arcEnd = cursor + fraction - gap

            result.append(RingSegment(
                exercise: exercise,
                start: cursor,
                end: max(arcEnd, cursor + 0.01)
            ))
            cursor += fraction
        }

        return result
    }
}
