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
    @Published var error: Error?

    private let userService = UserService.shared
    private let gridService = GridService()
    private var savedVideosManager: SavedVideosManager?
    private var collectionsManager: CollectionsManager?
    private var userListener: ListenerRegistration?
    private var progressListener: ListenerRegistration?

    init() {
        setupManagers()
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
}

struct SavedVideoCard: View {
    let video: SavedVideo
    @ObservedObject var viewModel: LibraryViewModel
    @State private var showingCollectionSheet = false

    var body: some View {
        VStack(alignment: .leading) {
            AsyncImage(url: URL(string: video.thumbnailURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        Image(systemName: "play.circle.fill")
                            .foregroundColor(.gray)
                            .font(.largeTitle)
                    )
            }
            .frame(width: 160, height: 90)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(video.title)
                .font(.caption)
                .lineLimit(2)
                .foregroundColor(.primary)

            Text(video.subject)
                .font(.caption2)
                .foregroundColor(.secondary)

            HStack {
                Text(video.subject)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: { showingCollectionSheet = true }) {
                    Image(systemName: "folder.badge.plus")
                        .foregroundColor(.blue)
                }
            }
        }
        .frame(width: 160)
        .sheet(isPresented: $showingCollectionSheet) {
            AddToCollectionSheet(viewModel: viewModel, videoId: video.id)
        }
    }
}

struct CompletedVideoCard: View {
    let video: Video
    @ObservedObject var viewModel: LibraryViewModel
    @State private var showingCollectionSheet = false

    var body: some View {
        VStack(alignment: .leading) {
            AsyncImage(url: URL(string: video.metadata.thumbnailUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        Image(systemName: "play.circle.fill")
                            .foregroundColor(.gray)
                            .font(.largeTitle)
                    )
            }
            .frame(width: 160, height: 90)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                    .padding(8),
                alignment: .topTrailing
            )

            Text(video.title)
                .font(.caption)
                .lineLimit(2)
                .foregroundColor(.primary)

            Text(video.subject)
                .font(.caption2)
                .foregroundColor(.secondary)

            HStack {
                Text(video.subject)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: { showingCollectionSheet = true }) {
                    Image(systemName: "folder.badge.plus")
                        .foregroundColor(.blue)
                }
            }
        }
        .frame(width: 160)
        .sheet(isPresented: $showingCollectionSheet) {
            AddToCollectionSheet(viewModel: viewModel, videoId: video.id)
        }
    }
}

struct LibrarySection<Content: View>: View {
    let title: String
    let icon: String
    let count: Int
    let content: Content

    init(title: String, icon: String, count: Int, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.count = count
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.headline)
                Spacer()
                Text("\(count)")
                    .foregroundColor(.gray)
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    content
                }
                .padding(.horizontal)
            }
        }
    }
}

struct CollectionCard: View {
    let collection: Collection
    let videos: [Video]

    var body: some View {
        VStack(alignment: .leading) {
            if !collection.thumbnailUrl.isEmpty {
                AsyncImage(url: URL(string: collection.thumbnailUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay(
                            Image(systemName: "folder.fill")
                                .foregroundColor(.gray)
                                .font(.largeTitle)
                        )
                }
                .frame(width: 160, height: 90)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 160, height: 90)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        Image(systemName: "folder.fill")
                            .foregroundColor(.gray)
                            .font(.largeTitle)
                    )
            }

            Text(collection.name)
                .font(.caption)
                .lineLimit(2)
                .foregroundColor(.primary)

            Text("\(videos.count) videos")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(width: 160)
    }
}

struct LibraryView: View {
    @StateObject private var viewModel = LibraryViewModel()
    @State private var showingError = false
    @State private var showingNewCollectionSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Text("My Library")
                        .font(.largeTitle)
                        .bold()
                    Spacer()
                }
                .padding(.horizontal)

                // Saved Videos
                LibrarySection(
                    title: "Saved Videos",
                    icon: "bookmark.fill",
                    count: viewModel.savedVideos.count
                ) {
                    ForEach(viewModel.savedVideos) { video in
                        SavedVideoCard(video: video, viewModel: viewModel)
                    }
                }

                // My Collections
                NavigationLink(destination: CollectionsView(viewModel: viewModel)) {
                    LibrarySection(
                        title: "My Collections",
                        icon: "folder.fill",
                        count: viewModel.collections.count
                    ) {
                        ForEach(viewModel.collections) { collection in
                            let collectionVideos = viewModel.getVideosForCollection(collection)
                            CollectionCard(collection: collection, videos: collectionVideos)
                        }
                    }
                }

                // Study Notes
                LibrarySection(title: "Study Notes", icon: "note.text", count: 5) {
                    ForEach(0..<5) { _ in
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 160, height: 90)
                            .overlay(
                                Image(systemName: "note.text")
                                    .foregroundColor(.gray)
                                    .font(.largeTitle)
                            )
                    }
                }

                // Continue Watching
                LibrarySection(title: "Continue Watching", icon: "play.circle", count: 3) {
                    ForEach(0..<3) { _ in
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 160, height: 90)
                            .overlay(
                                Image(systemName: "play.circle.fill")
                                    .foregroundColor(.gray)
                                    .font(.largeTitle)
                            )
                    }
                }

                // Completed Videos
                LibrarySection(
                    title: "Completed Videos",
                    icon: "checkmark.circle.fill",
                    count: viewModel.completedVideos.count
                ) {
                    ForEach(viewModel.completedVideos) { video in
                        CompletedVideoCard(video: video, viewModel: viewModel)
                    }
                }
            }
            .padding(.vertical)
        }
        .sheet(isPresented: $showingNewCollectionSheet) {
            NewCollectionSheet(viewModel: viewModel)
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {
                showingError = false
            }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "An unknown error occurred")
        }
        .onReceive(viewModel.$error) { error in
            showingError = error != nil
        }
    }
}

struct NewCollectionSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: LibraryViewModel
    @State private var name = ""
    @State private var description = ""
    @State private var isCreating = false
    @State private var error: Error?

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Collection Name", text: $name)
                    TextField("Description", text: $description)
                }
            }
            .navigationTitle("New Collection")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Create") {
                    createCollection()
                }
                .disabled(name.isEmpty || isCreating)
            )
            .alert("Error", isPresented: .constant(error != nil)) {
                Button("OK", role: .cancel) {
                    error = nil
                }
            } message: {
                if let error = error {
                    Text(error.localizedDescription)
                }
            }
        }
    }

    private func createCollection() {
        isCreating = true
        Task {
            do {
                try await viewModel.createCollection(name: name, description: description)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                self.error = error
            }
            await MainActor.run {
                isCreating = false
            }
        }
    }
}

struct AddToCollectionSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: LibraryViewModel
    let videoId: String
    @State private var isAdding = false
    @State private var error: Error?
    @State private var showingNewCollectionSheet = false

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.collections) { collection in
                    Button(action: { addToCollection(collection.id) }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(collection.name)
                                    .font(.headline)
                                Text("\(collection.videoIds.count) videos")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if collection.videoIds.contains(videoId) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .disabled(isAdding || collection.videoIds.contains(videoId))
                }

                Button(action: { showingNewCollectionSheet = true }) {
                    Label("Create New Collection", systemImage: "folder.badge.plus")
                }
            }
            .navigationTitle("Add to Collection")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
            .sheet(isPresented: $showingNewCollectionSheet) {
                NewCollectionSheet(viewModel: viewModel)
            }
            .alert("Error", isPresented: .constant(error != nil)) {
                Button("OK", role: .cancel) {
                    error = nil
                }
            } message: {
                if let error = error {
                    Text(error.localizedDescription)
                }
            }
        }
    }

    private func addToCollection(_ collectionId: String) {
        isAdding = true
        Task {
            do {
                try await viewModel.addVideoToCollection(videoId, collectionId: collectionId)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                self.error = error
            }
            await MainActor.run {
                isAdding = false
            }
        }
    }
}

#Preview {
    NavigationView {
        LibraryView()
    }
}
