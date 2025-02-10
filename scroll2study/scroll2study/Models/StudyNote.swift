import FirebaseFirestore
import Foundation

struct StudyNote: Identifiable, Codable {
    let id: String
    let userId: String
    let videoId: String
    let originalText: String
    let summary: String?
    let createdAt: Date
    let updatedAt: Date

    // Initialize from Firestore document
    init?(document: DocumentSnapshot) {
        let data = document.data() ?? [:]

        guard
            let userId = data["userId"] as? String,
            let videoId = data["videoId"] as? String,
            let originalText = data["originalText"] as? String,
            let createdAtTimestamp = data["createdAt"] as? Timestamp,
            let updatedAtTimestamp = data["updatedAt"] as? Timestamp
        else { return nil }

        self.id = document.documentID
        self.userId = userId
        self.videoId = videoId
        self.originalText = originalText
        self.summary = data["summary"] as? String
        self.createdAt = createdAtTimestamp.dateValue()
        self.updatedAt = updatedAtTimestamp.dateValue()
    }

    // Standard initializer
    init(
        id: String = UUID().uuidString,
        userId: String,
        videoId: String,
        originalText: String,
        summary: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.videoId = videoId
        self.originalText = originalText
        self.summary = summary
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // Convert to Firestore dictionary
    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "userId": userId,
            "videoId": videoId,
            "originalText": originalText,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt),
        ]

        if let summary = summary {
            dict["summary"] = summary
        }

        return dict
    }
}
