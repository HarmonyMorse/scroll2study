import Foundation

public struct Subject: Identifiable, Codable {
    public let id: String
    public let name: String
    public let description: String
    public let order: Int
    public let isActive: Bool
    public let createdAt: Date
    public let updatedAt: Date

    public init(
        id: String, name: String, description: String, order: Int, isActive: Bool, createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.order = order
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct ComplexityLevel: Identifiable, Codable {
    public let id: String
    public let level: Int
    public let name: String
    public let description: String
    public let requirements: String
    public let order: Int
    public let isActive: Bool

    public init(
        id: String, level: Int, name: String, description: String, requirements: String, order: Int,
        isActive: Bool
    ) {
        self.id = id
        self.level = level
        self.name = name
        self.description = description
        self.requirements = requirements
        self.order = order
        self.isActive = isActive
    }
}
