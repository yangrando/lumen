//
//  UserInterest.swift
//  Lumen
//
//  Created by Yan Felipe Grando on 29/12/25.
//

import Foundation


enum UserInterest: String, CaseIterable, Identifiable {
    
    case technology = "Technology"
    case sports = "Sports"
    case entertainment = "Entertainment"
    case business = "Business"
    case science = "Science"
    case travel = "Travel"
    case health = "Health"
    case art = "Art"
    case music = "Music"
    case food = "Food"
    case culture = "Culture"
    case fashion = "Fashion"
    case gaming = "Gaming"
    
    var id: String { self.rawValue }

    var icon: String {
        switch self {
        case .technology:
            return "laptopcomputer"
        case .sports:
            return "figure.soccer"
        case .entertainment:
            return "film"
        case .business:
            return "briefcase"
        case .science:
            return "flask"
        case .travel:
            return "airplane"
        case .health:
            return "heart"
        case .art:
            return "paintpalette"
        case .music:
            return "music.note"
        case .food:
            return "fork.knife"
        case .culture:
            return "globe.europe.africa"
        case .fashion:
            return "tshirt"
        case .gaming:
            return "gamecontroller"
        }
    }

    var displayTitle: String {
        switch self {
        case .entertainment:
            return "Filmes & Séries"
        case .music:
            return "Música"
        case .travel:
            return "Viagens"
        case .food:
            return "Culinária"
        case .technology:
            return "Tecnologia"
        case .science:
            return "Ciência"
        case .sports:
            return "Esportes"
        case .business:
            return "Negócios"
        case .health:
            return "Saúde"
        case .art:
            return "Arte"
        case .culture:
            return "Cultura"
        case .fashion:
            return "Moda"
        case .gaming:
            return "Games"
        }
    }
}
