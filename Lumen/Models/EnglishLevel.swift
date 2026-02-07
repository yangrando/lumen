//
//  EnglishLevel.swift
//  Lumen
//
//  Created by Yan Felipe Grando on 29/12/25.
//

import Foundation

enum EnglishLevel: String, CaseIterable, Identifiable {
    
    case beginner = "Beginner"
    case elementary = "Elementary"
    case intermediate = "Intermediate"
    case upperIntermediate = "Upper-Intermediate"
    case advanced = "Advanced"
    
    var id: String { self.rawValue }
    
    var description: String {
        switch self {
        case .beginner:
            return "Just starting out"
        case .elementary:
            return "Basic understanding"
        case .intermediate:
            return "Conversational level"
        case .upperIntermediate:
            return "Advanced understanding"
        case .advanced:
            return "Fluent and confident"
        }
    }
    
    var emoji: String {
        switch self {
        case .beginner:
            return "🌱"
        case .elementary:
            return "📚"
        case .intermediate:
            return "🎯"
        case .upperIntermediate:
            return "🚀"
        case .advanced:
            return "⭐"
        }
    }
}
