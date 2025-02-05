import FirebaseFirestore
import Foundation

public class GridService: ObservableObject {
    private let db = Firestore.firestore()

    @Published public var subjects: [Subject] = []
    @Published public var complexityLevels: [ComplexityLevel] = []
    @Published public var isLoading = false
    @Published public var error: Error?
    @Published private(set) public var videos: [String: [String: Bool]] = [:]  // [subjectId: [levelId: hasVideo]]

    public init() {}

    public func fetchGridData() async {
        isLoading = true
        error = nil

        do {
            // Fetch subjects
            let subjectsSnapshot = try await db.collection("subjects")
                .order(by: "order")
                .whereField("isActive", isEqualTo: true)
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

            // Fetch videos to build availability map
            let videosSnapshot = try await db.collection("videos")
                .whereField("isActive", isEqualTo: true)
                .getDocuments()

            // Build video availability map
            var videoMap: [String: [String: Bool]] = [:]
            for document in videosSnapshot.documents {
                let data = document.data()
                if let subjectId = data["subjectId"] as? String,
                    let levelId = data["complexityLevelId"] as? String
                {
                    if videoMap[subjectId] == nil {
                        videoMap[subjectId] = [:]
                    }
                    videoMap[subjectId]?[levelId] = true
                }
            }
            videos = videoMap

            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }

    public func hasVideo(for subjectId: String, at levelId: String) -> Bool {
        return videos[subjectId]?[levelId] ?? false
    }
}
