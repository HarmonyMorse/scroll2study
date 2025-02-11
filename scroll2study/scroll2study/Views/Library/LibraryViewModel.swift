import FirebaseAuth
import FirebaseFirestore
import SwiftUI
import os

private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "scroll2study",
    category: "LibraryView"
)

@MainActor
class LibraryViewModel: ObservableObject {
    @Published var savedVideos: [SavedVideo] = []
    @Published var completedVideos: [Video] = []
    @Published var collections: [Collection] = []
    @Published var studyNotes: [StudyNote] = []
    @Published var error: Error?

    private let userService = UserService.shared
    let gridService = GridService()
    private let studyNoteService = StudyNoteService.shared
    private var savedVideosManager: SavedVideosManager?
    private var collectionsManager: CollectionsManager?
    private var userListener: ListenerRegistration?
    private var progressListener: ListenerRegistration?

    init() {
        setupManagers()
        loadStudyNotes()
        Task {
            await gridService.fetchGridData()
        }
    }

    deinit {
        userListener?.remove()
        progressListener?.remove()
    }

    private func setupManagers() {
        savedVideosManager = SavedVideosManager()
        collectionsManager = CollectionsManager()
        setupUserListener()
        setupProgressListener()

        // Subscribe to savedVideosManager updates
        savedVideosManager?.$savedVideos
            .receive(on: RunLoop.main)
            .assign(to: &$savedVideos)

        // Subscribe to collectionsManager updates
        collectionsManager?.$collections
            .receive(on: RunLoop.main)
            .assign(to: &$collections)
    }

    private func setupUserListener() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        userListener = Firestore.firestore()
            .collection("users")
            .document(userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    self.error = error
                    return
                }
            }
    }

    private func setupProgressListener() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        // First, fetch the grid data
        Task {
            await gridService.fetchGridData()

            // Then set up the listener for completed videos
            progressListener = Firestore.firestore()
                .collection("user_progress")
                .whereField("userId", isEqualTo: userId)
                .whereField("watchedFull", isEqualTo: true)
                .addSnapshotListener { [weak self] snapshot, error in
                    guard let self = self else { return }

                    if let error = error {
                        self.error = error
                        return
                    }

                    let completedVideoIds = Set(
                        snapshot?.documents.compactMap { doc in
                            doc.data()["videoId"] as? String
                        } ?? [])

                    // Update completed videos list
                    self.completedVideos = self.gridService.videos.filter { video in
                        completedVideoIds.contains(video.id)
                    }
                }
        }
    }

    private func loadStudyNotes() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        Task {
            do {
                let notes = try await studyNoteService.getUserStudyNotes(userId: userId)
                await MainActor.run {
                    self.studyNotes = notes
                }
            } catch {
                await MainActor.run {
                    self.error = error
                }
            }
        }
    }

    func getVideosForCollection(_ collection: Collection) -> [Video] {
        return gridService.videos.filter { video in
            collection.videoIds.contains(video.id)
        }
    }

    func createCollection(name: String, description: String) async throws {
        try await collectionsManager?.createCollection(name: name, description: description)
    }

    func addVideoToCollection(_ videoId: String, collectionId: String) async throws {
        try await collectionsManager?.addVideoToCollection(
            collectionId: collectionId, videoId: videoId)
    }

    func removeVideoFromCollection(_ videoId: String, collectionId: String) async throws {
        try await collectionsManager?.removeVideoFromCollection(
            collectionId: collectionId, videoId: videoId)
    }

    func deleteCollection(_ collectionId: String) async throws {
        try await collectionsManager?.deleteCollection(withId: collectionId)
    }

    // Public method to get video by ID
    func getVideo(id: String) -> Video? {
        return gridService.videos.first { $0.id == id }
    }
}
