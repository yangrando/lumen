import Foundation

enum ProfessionOption: String, CaseIterable, Identifiable {
    case softwareDeveloper = "Software Developer"
    case designer = "Designer"
    case manager = "Manager"
    case marketer = "Marketer"
    case salesperson = "Salesperson"
    case teacher = "Teacher"
    case doctor = "Doctor"
    case student = "Student"
    case entrepreneur = "Entrepreneur"
    case other = "Other"

    var id: String { rawValue }

    var displayTitle: String {
        switch self {
        case .softwareDeveloper:
            return "Desenvolvedor(a)"
        case .designer:
            return "Designer"
        case .manager:
            return "Gerente"
        case .marketer:
            return "Marketing"
        case .salesperson:
            return "Vendas"
        case .teacher:
            return "Professor(a)"
        case .doctor:
            return "Médico(a)"
        case .student:
            return "Estudante"
        case .entrepreneur:
            return "Empreendedor(a)"
        case .other:
            return "Outro"
        }
    }
}
