import Foundation

struct Subject: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let order: Int
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date
}

struct ComplexityLevel: Identifiable, Codable {
    let id: String
    let level: Int
    let name: String
    let description: String
    let requirements: String
    let order: Int
    let isActive: Bool
}
