import SwiftUI

enum ExerciseType: String, CaseIterable, Codable {
    case chest  = "chest"
    case back   = "back"
    case legs   = "legs"
    case arms   = "arms"
    case cardio = "cardio"

    var abbreviation: String {
        switch self {
        case .chest:  return "Ch"
        case .back:   return "B"
        case .legs:   return "L"
        case .arms:   return "A"
        case .cardio: return "Ca"
        }
    }

    var fullName: String {
        switch self {
        case .chest:  return "Chest"
        case .back:   return "Back"
        case .legs:   return "Legs"
        case .arms:   return "Arms"
        case .cardio: return "Cardio"
        }
    }

    var color: Color {
        switch self {
        case .chest:  return Color(red: 1.00, green: 0.35, blue: 0.25) // coral red
        case .back:   return Color(red: 0.20, green: 0.55, blue: 0.95) // ocean blue
        case .legs:   return Color(red: 0.15, green: 0.80, blue: 0.45) // emerald
        case .arms:   return Color(red: 0.65, green: 0.25, blue: 0.95) // violet
        case .cardio: return Color(red: 1.00, green: 0.70, blue: 0.00) // amber
        }
    }
}
