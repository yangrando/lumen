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
        case .fashion:
            return "tshirt"
        case .gaming:
            return "gamecontroller"
        }
    }
}
