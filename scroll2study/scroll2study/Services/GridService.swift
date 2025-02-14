import FirebaseFirestore
import Foundation

public class GridService: ObservableObject {
    private let db = Firestore.firestore()

    @Published public var subjects: [Subject] = []
    @Published public var complexityLevels: [ComplexityLevel] = []
    @Published public var isLoading = false
    @Published public var error: Error?
    @Published public var videos: [Video] = []
    @Published public var videoMap: [String: [Int: Video]] = [:]  // [subjectId: [complexityLevel: Video]]

    public init() {}

    public func fetchGridData() async {
        isLoading = true
        error = nil

        do {
            // Fetch subjects
            let subjectsSnapshot = try await db.collection("subjects")
                .order(by: "order")
                .getDocuments()

            subjects = try subjectsSnapshot.documents.map { document in
                let data = document.data()
                let timestamp = data["createdAt"] as? Timestamp ?? Timestamp()
                let updatedTimestamp = data["updatedAt"] as? Timestamp ?? Timestamp()

                return Subject(
                    id: document.documentID,
                    name: data["name"] as? String ?? "",
                    description: data["description"] as? String ?? "",
                    order: data["order"] as? Int ?? 0,
                    isActive: data["isActive"] as? Bool ?? true,
                    createdAt: timestamp.dateValue(),
                    updatedAt: updatedTimestamp.dateValue()
                )
            }

            // Fetch complexity levels
            let levelsSnapshot = try await db.collection("complexity_levels")
                .order(by: "order")
                .whereField("isActive", isEqualTo: true)
                .getDocuments()

            complexityLevels = try levelsSnapshot.documents.map { document in
                let data = document.data()
                return ComplexityLevel(
                    id: document.documentID,
                    level: data["level"] as? Int ?? 0,
                    name: data["name"] as? String ?? "",
                    description: data["description"] as? String ?? "",
                    requirements: data["requirements"] as? String ?? "",
                    order: data["order"] as? Int ?? 0,
                    isActive: data["isActive"] as? Bool ?? true
                )
            }

            // Fetch videos
            let videosSnapshot = try await db.collection("videos")
                .whereField("isActive", isEqualTo: true)
                .getDocuments()

            // Parse videos and build video map
            videos = try videosSnapshot.documents.map { document in
                let data = document.data()
                let metadataData = data["metadata"] as? [String: Any] ?? [:]
                let positionData = data["position"] as? [String: Any] ?? [:]

                let metadata = VideoMetadata(
                    duration: metadataData["duration"] as? Int ?? 0,
                    views: metadataData["views"] as? Int ?? 0,
                    thumbnailUrl: metadataData["thumbnailUrl"] as? String ?? "",
                    createdAt: (metadataData["createdAt"] as? Timestamp ?? Timestamp()).dateValue(),
                    videoUrl: metadataData["videoUrl"] as? String ?? "",
                    storagePath: metadataData["storagePath"] as? String ?? "",
                    captions: parseCaptions(from: metadataData["captions"] as? [[String: Any]] ?? [])
                )

                let position = Position(
                    x: positionData["x"] as? Int ?? 0,
                    y: positionData["y"] as? Int ?? 0
                )

                return Video(
                    id: document.documentID,
                    title: data["title"] as? String ?? "",
                    description: data["description"] as? String ?? "",
                    subject: data["subject"] as? String ?? "",
                    complexityLevel: data["complexityLevel"] as? Int ?? 0,
                    metadata: metadata,
                    position: position,
                    isActive: data["isActive"] as? Bool ?? true
                )
            }

            // Build video map for easy access
            var newVideoMap: [String: [Int: Video]] = [:]
            for video in videos {
                if newVideoMap[video.subject] == nil {
                    newVideoMap[video.subject] = [:]
                }
                newVideoMap[video.subject]?[video.complexityLevel] = video
            }
            videoMap = newVideoMap

            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }

    public func getVideo(for subject: String, at complexityLevel: Int) -> Video? {
        return videoMap[subject]?[complexityLevel]
    }

    public func hasVideo(for subject: String, at complexityLevel: Int) -> Bool {
        return getVideo(for: subject, at: complexityLevel) != nil
    }

    private func parseCaptions(from data: [[String: Any]]) -> [Caption]? {
        guard !data.isEmpty else { return nil }
        
        return data.compactMap { captionData in
            guard let startTime = captionData["startTime"] as? Double,
                  let endTime = captionData["endTime"] as? Double,
                  let text = captionData["text"] as? String
            else { return nil }
            
            return Caption(startTime: startTime, endTime: endTime, text: text)
        }
    }
}
