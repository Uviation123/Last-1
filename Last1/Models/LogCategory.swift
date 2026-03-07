import SwiftUI

enum LogCategory: String, Codable, CaseIterable, Identifiable {
    case fitness
    case learning
    case mindfulness
    case nutrition
    case productivity
    case creativity
    case social
    case other

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .fitness: "figure.run"
        case .learning: "book.fill"
        case .mindfulness: "brain.head.profile"
        case .nutrition: "leaf.fill"
        case .productivity: "checkmark.circle.fill"
        case .creativity: "paintbrush.fill"
        case .social: "person.2.fill"
        case .other: "star.fill"
        }
    }

    var color: Color {
        switch self {
        case .fitness: .orange
        case .learning: .blue
        case .mindfulness: .purple
        case .nutrition: .green
        case .productivity: .indigo
        case .creativity: .pink
        case .social: .yellow
        case .other: .gray
        }
    }

}
