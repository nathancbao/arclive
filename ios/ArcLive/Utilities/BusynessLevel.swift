import SwiftUI

enum BusynessLevel {
    case quiet, moderate, busy

    static let maxCapacity = 2500

    init(count: Int) {
        let ratio = Double(count) / Double(BusynessLevel.maxCapacity)
        if ratio < 0.20      { self = .quiet }
        else if ratio < 0.60 { self = .moderate }
        else                 { self = .busy }
    }

    var label: String {
        switch self {
        case .quiet:    return "Quiet"
        case .moderate: return "Moderate"
        case .busy:     return "Busy"
        }
    }

    var color: Color {
        switch self {
        case .quiet:    return .green
        case .moderate: return Color(red: 1, green: 0.75, blue: 0)
        case .busy:     return .red
        }
    }

    var systemImage: String {
        switch self {
        case .quiet:    return "figure.walk"
        case .moderate: return "figure.run"
        case .busy:     return "person.3.fill"
        }
    }
}
