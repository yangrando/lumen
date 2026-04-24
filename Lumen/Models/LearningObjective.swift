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
    case understandPodcasts = "Understand Podcasts"
    case passExams = "Pass Exams"
    case businessCommunication = "Business Communication"
    case professionalPresentations = "Professional Presentations"
    case jobInterviews = "Job Interviews"
    case travelConfidence = "Travel Confidence"
    case airportConversations = "Airport Conversations"
    case hotelInteractions = "Hotel Interactions"
    case dailyConversation = "Daily Conversation"
    case makingFriends = "Making Friends"
    case expandVocabulary = "Expand Vocabulary"
    case improvePronunciation = "Improve Pronunciation"
    case improveAccent = "Improve Accent"
    case writingEmails = "Writing Emails"
    case writingMessages = "Writing Messages"
    case academicEnglish = "Academic English"
    case storytelling = "Storytelling"
    case debating = "Debating"
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
            case .understandPodcasts:
                return "headphones"
            case .passExams:
                return "checkmark.circle"
            case .businessCommunication:
                return "briefcase.fill"
            case .professionalPresentations:
                return "display"
            case .jobInterviews:
                return "person.text.rectangle"
            case .travelConfidence:
                return "globe"
            case .airportConversations:
                return "airplane.departure"
            case .hotelInteractions:
                return "building.2.fill"
            case .dailyConversation:
                return "bubble.right.fill"
            case .makingFriends:
                return "person.2.fill"
            case .expandVocabulary:
                return "book.fill"
            case .improvePronunciation:
                return "mouth.fill"
            case .improveAccent:
                return "waveform"
            case .writingEmails:
                return "envelope.fill"
            case .writingMessages:
                return "message.fill"
            case .academicEnglish:
                return "graduationcap.fill"
            case .storytelling:
                return "text.quote"
            case .debating:
                return "person.2.wave.2.fill"
            case .readingComprehension:
                return "text.book.closed"
            case .writingSkills:
                return "pencil.circle.fill"
            }
        }

    static var onboardingCases: [LearningObjective] {
        [
            .improveSpeaking,
            .dailyConversation,
            .businessCommunication,
            .travelConfidence,
            .understandMovies,
            .understandPodcasts,
            .expandVocabulary,
            .makingFriends,
            .professionalPresentations,
            .jobInterviews,
            .airportConversations,
            .hotelInteractions,
            .improvePronunciation,
            .improveAccent,
            .writingEmails,
            .writingMessages,
            .passExams,
            .academicEnglish,
            .storytelling,
            .debating,
            .readingComprehension,
            .writingSkills
        ]
    }

    var displayTitle: String {
        switch self {
        case .businessCommunication:
            return LocalizedStrings.objectiveBusinessCommunication
        case .travelConfidence:
            return LocalizedStrings.objectiveTravelConfidence
        case .professionalPresentations:
            return LocalizedStrings.objectiveProfessionalPresentations
        case .jobInterviews:
            return LocalizedStrings.objectiveJobInterviews
        case .airportConversations:
            return LocalizedStrings.objectiveAirportConversations
        case .hotelInteractions:
            return LocalizedStrings.objectiveHotelInteractions
        case .understandMovies:
            return LocalizedStrings.objectiveUnderstandMovies
        case .understandPodcasts:
            return LocalizedStrings.objectiveUnderstandPodcasts
        case .expandVocabulary:
            return LocalizedStrings.objectiveExpandVocabulary
        case .passExams:
            return LocalizedStrings.objectivePassExams
        case .improveSpeaking:
            return LocalizedStrings.objectiveImproveSpeaking
        case .dailyConversation:
            return LocalizedStrings.objectiveDailyConversation
        case .makingFriends:
            return LocalizedStrings.objectiveMakingFriends
        case .improvePronunciation:
            return LocalizedStrings.objectiveImprovePronunciation
        case .improveAccent:
            return LocalizedStrings.objectiveImproveAccent
        case .writingEmails:
            return LocalizedStrings.objectiveWritingEmails
        case .writingMessages:
            return LocalizedStrings.objectiveWritingMessages
        case .academicEnglish:
            return LocalizedStrings.objectiveAcademicEnglish
        case .storytelling:
            return LocalizedStrings.objectiveStorytelling
        case .debating:
            return LocalizedStrings.objectiveDebating
        case .readingComprehension:
            return LocalizedStrings.objectiveReadingComprehension
        case .writingSkills:
            return LocalizedStrings.objectiveWritingSkills
        }
    }
}
