import Foundation

struct LearningSubtopic: Identifiable, Hashable {
    let id: String
    let displayTitle: String
    let topics: Set<UserInterest>

    static let all: [LearningSubtopic] = [
        .init(id: "meetings", displayTitle: "Reuniões", topics: [.business]),
        .init(id: "presentations", displayTitle: "Apresentações", topics: [.business]),
        .init(id: "interviews", displayTitle: "Entrevistas", topics: [.business]),
        .init(id: "networking", displayTitle: "Networking", topics: [.business]),
        .init(id: "remote_work", displayTitle: "Trabalho remoto", topics: [.business]),
        .init(id: "negotiation", displayTitle: "Negociação", topics: [.business]),
        .init(id: "leadership", displayTitle: "Liderança", topics: [.business]),
        .init(id: "emails", displayTitle: "E-mails", topics: [.business]),
        .init(id: "airport", displayTitle: "Aeroporto", topics: [.travel]),
        .init(id: "hotel", displayTitle: "Hotel", topics: [.travel]),
        .init(id: "transportation", displayTitle: "Transporte", topics: [.travel]),
        .init(id: "directions", displayTitle: "Direções", topics: [.travel]),
        .init(id: "restaurant", displayTitle: "Restaurantes", topics: [.travel, .food]),
        .init(id: "customs", displayTitle: "Imigração e alfândega", topics: [.travel]),
        .init(id: "emergencies", displayTitle: "Emergências", topics: [.travel, .health]),
        .init(id: "tourism", displayTitle: "Turismo", topics: [.travel, .culture]),
        .init(id: "football", displayTitle: "Futebol", topics: [.sports]),
        .init(id: "basketball", displayTitle: "Basquete", topics: [.sports]),
        .init(id: "fitness", displayTitle: "Fitness", topics: [.sports, .health]),
        .init(id: "olympics", displayTitle: "Olimpíadas", topics: [.sports]),
        .init(id: "training", displayTitle: "Treino", topics: [.sports]),
        .init(id: "sports_history", displayTitle: "História do esporte", topics: [.sports, .culture]),
        .init(id: "coaching", displayTitle: "Coaching esportivo", topics: [.sports]),
        .init(id: "software", displayTitle: "Software", topics: [.technology]),
        .init(id: "ai", displayTitle: "Inteligência artificial", topics: [.technology]),
        .init(id: "programming", displayTitle: "Programação", topics: [.technology]),
        .init(id: "gadgets", displayTitle: "Gadgets", topics: [.technology]),
        .init(id: "cybersecurity", displayTitle: "Cibersegurança", topics: [.technology]),
        .init(id: "startups", displayTitle: "Startups", topics: [.technology, .business]),
        .init(id: "movies", displayTitle: "Filmes", topics: [.culture, .entertainment]),
        .init(id: "series", displayTitle: "Séries", topics: [.culture, .entertainment]),
        .init(id: "books", displayTitle: "Livros", topics: [.culture]),
        .init(id: "theater", displayTitle: "Teatro", topics: [.culture, .art]),
        .init(id: "festivals", displayTitle: "Festivais", topics: [.culture, .music]),
        .init(id: "history", displayTitle: "História", topics: [.culture]),
        .init(id: "traditions", displayTitle: "Tradições", topics: [.culture]),
        .init(id: "esports", displayTitle: "E-sports", topics: [.gaming, .sports]),
        .init(id: "online_games", displayTitle: "Jogos online", topics: [.gaming]),
        .init(id: "game_design", displayTitle: "Design de jogos", topics: [.gaming, .art, .technology]),
        .init(id: "streaming", displayTitle: "Streaming", topics: [.gaming, .entertainment]),
        .init(id: "gaming_community", displayTitle: "Comunidade gamer", topics: [.gaming]),
        .init(id: "recipes", displayTitle: "Receitas", topics: [.food]),
        .init(id: "nutrition", displayTitle: "Nutrição", topics: [.food, .health]),
        .init(id: "healthy_habits", displayTitle: "Hábitos saudáveis", topics: [.health]),
        .init(id: "mental_health", displayTitle: "Saúde mental", topics: [.health]),
        .init(id: "painting", displayTitle: "Pintura", topics: [.art]),
        .init(id: "design", displayTitle: "Design", topics: [.art, .fashion]),
        .init(id: "fashion_trends", displayTitle: "Tendências de moda", topics: [.fashion]),
        .init(id: "sustainable_fashion", displayTitle: "Moda sustentável", topics: [.fashion]),
        .init(id: "research", displayTitle: "Pesquisa", topics: [.science]),
        .init(id: "space", displayTitle: "Espaço", topics: [.science]),
        .init(id: "music_history", displayTitle: "História da música", topics: [.music, .culture]),
        .init(id: "instruments", displayTitle: "Instrumentos", topics: [.music])
    ]

    static func options(for interests: Set<UserInterest>) -> [LearningSubtopic] {
        guard !interests.isEmpty else { return [] }
        return all
            .filter { !$0.topics.isDisjoint(with: interests) }
            .sorted { $0.displayTitle.localizedCaseInsensitiveCompare($1.displayTitle) == .orderedAscending }
    }

    static func from(id: String) -> LearningSubtopic? {
        all.first { $0.id == id }
    }
}
