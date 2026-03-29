//
//  EnglishLevel.swift
//  Lumen
//
//  Created by Yan Felipe Grando on 29/12/25.
//

import Foundation

enum EnglishLevel: String, CaseIterable, Identifiable {
    case a1 = "A1"
    case a2 = "A2"
    case b1 = "B1"
    case b2 = "B2"
    case c1 = "C1"
    case c2 = "C2"

    var id: String { self.rawValue }

    init(label: String) {
        let normalized = label
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: " ", with: "")

        switch normalized {
        case "a1", "beginner":
            self = .a1
        case "a2", "elementary", "preintermediate":
            self = .a2
        case "b1", "intermediate":
            self = .b1
        case "b2", "upperintermediate":
            self = .b2
        case "c1", "advanced":
            self = .c1
        case "c2", "proficient", "mastery":
            self = .c2
        default:
            self = .b1
        }
    }

    var description: String {
        switch self {
        case .a1:
            return "Understands familiar words and very simple phrases."
        case .a2:
            return "Handles everyday situations with simple sentence patterns."
        case .b1:
            return "Communicates about routine topics with growing independence."
        case .b2:
            return "Understands and produces more detailed, connected language."
        case .c1:
            return "Uses English flexibly across complex topics and contexts."
        case .c2:
            return "Understands subtle meaning and communicates with near-native ease."
        }
    }

    var shortTitle: String {
        switch self {
        case .a1:
            return "Starter"
        case .a2:
            return "Elementary"
        case .b1:
            return "Independent"
        case .b2:
            return "Upper-Intermediate"
        case .c1:
            return "Advanced"
        case .c2:
            return "Proficient"
        }
    }

    var accentColorSeed: Double {
        switch self {
        case .a1:
            return 0.12
        case .a2:
            return 0.28
        case .b1:
            return 0.44
        case .b2:
            return 0.60
        case .c1:
            return 0.76
        case .c2:
            return 0.92
        }
    }
}
