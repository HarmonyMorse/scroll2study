import Combine
import FirebaseAuth
import FirebaseFirestore
import Foundation

// Separate class to handle Firebase listener
private class FirebaseListener {
    private(set) var registration: ListenerRegistration?

    func set(_ listener: ListenerRegistration?) {
        registration?.remove()  // Remove existing listener if any
        registration = listener
    }

    func remove() {
        registration?.remove()
        registration = nil
    }

    deinit {
        remove()
    }
}

@MainActor
class SavedVideosManager: ObservableObject {
    @Published var savedVideos: [SavedVideo] = []
    @Published var isLoading = false
    @Published var error: Error?

    private var db = Firestore.firestore()
    // Make listener nonisolated since it's thread-safe
    nonisolated private let listener = FirebaseListener()

    init() {
        setupAuthListener()
    }

    private func setupAuthListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                if user != nil {
                    self?.startListeningToSavedVideos()
                } else {
                    self?.stopListeningToSavedVideos()
                    self?.savedVideos = []
                }
            }
        }
    }

    private func startListeningToSavedVideos() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let registration = db.collection("users")
            .document(userId)
            .collection("savedVideos")
            .order(by: "savedAt", descending: true)
            .addSnapshotListener { [weak self] querySnapshot, error in
                Task { @MainActor in
                    if let error = error {
                        self?.error = error
                        return
                    }

                    guard let documents = querySnapshot?.documents else {
                        self?.savedVideos = []
                        return
                    }

                    self?.savedVideos = documents.compactMap { document in
                        SavedVideo(document: document)
                    }
                }
            }

        listener.set(registration)
    }

    // Make this nonisolated since it only interacts with thread-safe components
    nonisolated private func stopListeningToSavedVideos() {
        listener.remove()
    }

    func saveVideo(_ video: SavedVideo) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(
                domain: "SavedVideosManager", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }

        try await db.collection("users")
            .document(userId)
            .collection("savedVideos")
            .document(video.id)
            .setData(video.dictionary)
    }

    func removeVideo(withId id: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(
                domain: "SavedVideosManager", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }

        try await db.collection("users")
            .document(userId)
            .collection("savedVideos")
            .document(id)
            .delete()
    }

    func isVideoSaved(_ videoId: String) -> Bool {
        savedVideos.contains { $0.id == videoId }
    }

    deinit {
        stopListeningToSavedVideos()
    }
}
