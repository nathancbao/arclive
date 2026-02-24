import Foundation

struct ExerciseBreakdown: Decodable {
    let chest: Int
    let back: Int
    let legs: Int
    let arms: Int
    let cardio: Int

    init(chest: Int = 0, back: Int = 0, legs: Int = 0, arms: Int = 0, cardio: Int = 0) {
        self.chest  = chest
        self.back   = back
        self.legs   = legs
        self.arms   = arms
        self.cardio = cardio
    }

    func count(for exercise: ExerciseType) -> Int {
        switch exercise {
        case .chest:  return chest
        case .back:   return back
        case .legs:   return legs
        case .arms:   return arms
        case .cardio: return cardio
        }
    }
}

struct OccupancyResponse: Decodable {
    let count: Int
    let breakdown: ExerciseBreakdown
}
