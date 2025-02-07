import FirebaseFirestore
import Foundation

struct Collection: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let thumbnailUrl: String
    let createdAt: Date
    let updatedAt: Date
    let videoIds: [String]

    init(document: DocumentSnapshot) {
        let data = document.data() ?? [:]

        self.id = document.documentID
        self.name = data["name"] as? String ?? ""
        self.description = data["description"] as? String ?? ""
        self.thumbnailUrl = data["thumbnailUrl"] as? String ?? ""
        self.videoIds = data["videoIds"] as? [String] ?? []
        self.createdAt = (data["createdAt"] as? Timestamp ?? Timestamp()).dateValue()
        self.updatedAt = (data["updatedAt"] as? Timestamp ?? Timestamp()).dateValue()
    }

    init(
        id: String, name: String, description: String, thumbnailUrl: String, videoIds: [String],
        createdAt: Date = Date(), updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.thumbnailUrl = thumbnailUrl
        self.videoIds = videoIds
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var dictionary: [String: Any] {
        return [
            "name": name,
            "description": description,
            "thumbnailUrl": thumbnailUrl,
            "videoIds": videoIds,
            "createdAt": createdAt,
            "updatedAt": updatedAt,
        ]
    }
}
