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

public struct Caption: Codable {
    public let startTime: Double
    public let endTime: Double
    public let text: String

    public init(startTime: Double, endTime: Double, text: String) {
        self.startTime = startTime
        self.endTime = endTime
        self.text = text
    }
}

public struct VideoMetadata: Codable {
    public let duration: Int
    public let views: Int
    public let thumbnailUrl: String
    public let createdAt: Date
    public let videoUrl: String
    public let storagePath: String
    public let captions: [Caption]?

    public init(
        duration: Int, views: Int, thumbnailUrl: String, createdAt: Date, videoUrl: String,
        storagePath: String, captions: [Caption]? = nil
    ) {
        self.duration = duration
        self.views = views
        self.thumbnailUrl = thumbnailUrl
        self.createdAt = createdAt
        self.videoUrl = videoUrl
        self.storagePath = storagePath
        self.captions = captions
    }
}

public struct Position: Codable {
    public let x: Int
    public let y: Int

    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
}

public struct Video: Identifiable, Codable, Equatable {
    public let id: String
    public let title: String
    public let description: String
    public let subject: String
    public let complexityLevel: Int
    public let metadata: VideoMetadata
    public let position: Position
    public let isActive: Bool

    public init(
        id: String,
        title: String,
        description: String,
        subject: String,
        complexityLevel: Int,
        metadata: VideoMetadata,
        position: Position,
        isActive: Bool
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.subject = subject
        self.complexityLevel = complexityLevel
        self.metadata = metadata
        self.position = position
        self.isActive = isActive
    }

    public static func == (lhs: Video, rhs: Video) -> Bool {
        return lhs.id == rhs.id
    }
}
