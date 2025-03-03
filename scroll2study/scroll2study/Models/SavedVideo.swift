import FirebaseFirestore
import Foundation

struct SavedVideo: Identifiable, Codable {
    var id: String
    var title: String
    var thumbnailURL: String
    var videoURL: String
    var savedAt: Date
    var duration: TimeInterval
    var subject: String
    var complexityLevel: Int?  // Add optional complexity level

    // For Firestore
    var dictionary: [String: Any] {
        var dict =
            [
                "id": id,
                "title": title,
                "thumbnailURL": thumbnailURL,
                "videoURL": videoURL,
                "savedAt": Timestamp(date: savedAt),
                "duration": duration,
                "subject": subject,
            ] as [String: Any]

        if let level = complexityLevel {
            dict["complexityLevel"] = level
        }

        return dict
    }

    // Initialize from Firestore document
    init?(document: QueryDocumentSnapshot) {
        let data = document.data()

        guard let id = data["id"] as? String,
            let title = data["title"] as? String,
            let thumbnailURL = data["thumbnailURL"] as? String,
            let videoURL = data["videoURL"] as? String,
            let savedAtTimestamp = data["savedAt"] as? Timestamp,
            let duration = data["duration"] as? TimeInterval,
            let subject = data["subject"] as? String
        else {
            return nil
        }

        self.id = id
        self.title = title
        self.thumbnailURL = thumbnailURL
        self.videoURL = videoURL
        self.savedAt = savedAtTimestamp.dateValue()
        self.duration = duration
        self.subject = subject
        self.complexityLevel = data["complexityLevel"] as? Int
    }

    // Standard initializer
    init(
        id: String, title: String, thumbnailURL: String, videoURL: String, savedAt: Date,
        duration: TimeInterval, subject: String, complexityLevel: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.thumbnailURL = thumbnailURL
        self.videoURL = videoURL
        self.savedAt = savedAt
        self.duration = duration
        self.subject = subject
        self.complexityLevel = complexityLevel
    }
}
