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
class CollectionsManager: ObservableObject {
    @Published var collections: [Collection] = []
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
                    self?.startListeningToCollections()
                } else {
                    self?.stopListeningToCollections()
                    self?.collections = []
                }
            }
        }
    }

    private func startListeningToCollections() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let registration = db.collection("users")
            .document(userId)
            .collection("collections")
            .order(by: "updatedAt", descending: true)
            .addSnapshotListener { [weak self] querySnapshot, error in
                Task { @MainActor in
                    if let error = error {
                        self?.error = error
                        return
                    }

                    guard let documents = querySnapshot?.documents else {
                        self?.collections = []
                        return
                    }

                    self?.collections = documents.compactMap { document in
                        Collection(document: document)
                    }
                }
            }

        listener.set(registration)
    }

    // Make this nonisolated since it only interacts with thread-safe components
    nonisolated private func stopListeningToCollections() {
        listener.remove()
    }

    func createCollection(name: String, description: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(
                domain: "CollectionsManager", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }

        let collection = Collection(
            id: UUID().uuidString,
            name: name,
            description: description,
            thumbnailUrl: "",  // Will be updated when first video is added
            videoIds: []
        )

        try await db.collection("users")
            .document(userId)
            .collection("collections")
            .document(collection.id)
            .setData(collection.dictionary)
    }

    func addVideoToCollection(collectionId: String, videoId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(
                domain: "CollectionsManager", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }

        let collectionRef = db.collection("users")
            .document(userId)
            .collection("collections")
            .document(collectionId)

        try await db.runTransaction { [db] transaction, errorPointer in
            // Get the collection document
            guard let snapshot = try? transaction.getDocument(collectionRef),
                var collection = snapshot.data()
            else { return nil }

            // Update videoIds array
            var videoIds = collection["videoIds"] as? [String] ?? []
            if !videoIds.contains(videoId) {
                videoIds.append(videoId)
                collection["videoIds"] = videoIds
                collection["updatedAt"] = FieldValue.serverTimestamp()

                // If this is the first video, update thumbnailUrl
                if videoIds.count == 1 {
                    let videoRef = db.collection("videos").document(videoId)
                    guard let videoSnapshot = try? transaction.getDocument(videoRef),
                        let videoData = videoSnapshot.data(),
                        let metadata = videoData["metadata"] as? [String: Any],
                        let thumbnailUrl = metadata["thumbnailUrl"] as? String
                    else { return nil }

                    collection["thumbnailUrl"] = thumbnailUrl
                }

                transaction.updateData(collection, forDocument: collectionRef)
            }

            return nil
        }
    }

    func removeVideoFromCollection(collectionId: String, videoId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(
                domain: "CollectionsManager", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }

        let collectionRef = db.collection("users")
            .document(userId)
            .collection("collections")
            .document(collectionId)

        try await db.runTransaction { transaction, errorPointer in
            // Get the collection document
            guard let snapshot = try? transaction.getDocument(collectionRef),
                var collection = snapshot.data()
            else { return nil }

            // Update videoIds array
            var videoIds = collection["videoIds"] as? [String] ?? []
            if let index = videoIds.firstIndex(of: videoId) {
                videoIds.remove(at: index)
                collection["videoIds"] = videoIds
                collection["updatedAt"] = FieldValue.serverTimestamp()

                // If this was the last video, clear thumbnailUrl
                if videoIds.isEmpty {
                    collection["thumbnailUrl"] = ""
                }

                transaction.updateData(collection, forDocument: collectionRef)
            }

            return nil
        }
    }

    func deleteCollection(withId id: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(
                domain: "CollectionsManager", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }

        try await db.collection("users")
            .document(userId)
            .collection("collections")
            .document(id)
            .delete()
    }

    deinit {
        stopListeningToCollections()
    }
}
