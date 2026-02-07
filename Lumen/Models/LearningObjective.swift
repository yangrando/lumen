//
//  LearningObjective.swift
//  Lumen
//
//  Created by Yan Felipe Grando on 29/12/25.
//

import Foundation

enum LearningObjective: String, CaseIterable, Identifiable {
    case improveSpeaking = "Improve Speaking"
    case understandMovies = "Understand Movies"
    case passExams = "Pass Exams"
    case businessCommunication = "Business Communication"
    case travelConfidence = "Travel Confidence"
    case dailyConversation = "Daily Conversation"
    case expandVocabulary = "Expand Vocabulary"
    case improveAccent = "Improve Accent"
    case readingComprehension = "Reading Comprehension"
    case writingSkills = "Writing Skills"
    
    var id: String { self.rawValue }
    
    // Icon for each objective
        var icon: String {
            switch self {
            case .improveSpeaking:
                return "mic.fill"
            case .understandMovies:
                return "film.fill"
            case .passExams:
                return "checkmark.circle"
            case .businessCommunication:
                return "briefcase.fill"
            case .travelConfidence:
                return "globe"
            case .dailyConversation:
                return "bubble.right.fill"
            case .expandVocabulary:
                return "book.fill"
            case .improveAccent:
                return "waveform"
            case .readingComprehension:
                return "text.book.closed"
            case .writingSkills:
                return "pencil.circle.fill"
            }
        }
}
