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
    private let gridService = GridService()
    private let studyNoteService = StudyNoteService.shared
    private var savedVideosManager: SavedVideosManager?
    private var collectionsManager: CollectionsManager?
    private var userListener: ListenerRegistration?
    private var progressListener: ListenerRegistration?

    init() {
        setupManagers()
        loadStudyNotes()
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

struct SavedVideoCard: View {
    let video: SavedVideo
    @ObservedObject var viewModel: LibraryViewModel
    @State private var showingCollectionSheet = false

    var body: some View {
        VStack(alignment: .leading) {
            // Gradient background instead of thumbnail
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]
                    ),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                VStack(spacing: 4) {
                    Text(video.title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    Text(formatDuration(video.duration))
                        .font(.caption2)
                        .foregroundColor(.white)
                        .monospacedDigit()
                }
                .padding(.horizontal, 8)
            }
            .frame(width: 160, height: 90)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(video.subject)
                .font(.caption2)
                .foregroundColor(.secondary)

            HStack {
                Text("Level \(video.complexityLevel ?? 1)")
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

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct CompletedVideoCard: View {
    let video: Video
    @ObservedObject var viewModel: LibraryViewModel
    @State private var showingCollectionSheet = false

    var body: some View {
        VStack(alignment: .leading) {
            // Gradient background instead of thumbnail
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]
                    ),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                VStack(spacing: 4) {
                    Text(video.title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    Text(formatDuration(video.metadata.duration))
                        .font(.caption2)
                        .foregroundColor(.white)
                        .monospacedDigit()
                }
                .padding(.horizontal, 8)
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

            Text(video.subject)
                .font(.caption2)
                .foregroundColor(.secondary)

            HStack {
                Text("Level \(video.complexityLevel)")
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

    private func formatDuration(_ duration: Int) -> String {
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct LibrarySection<Content: View>: View {
    let title: String
    let icon: String
    let count: Int
    let content: Content
    let onHeaderTap: () -> Void

    init(
        title: String,
        icon: String,
        count: Int,
        onHeaderTap: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.count = count
        self.content = content()
        self.onHeaderTap = onHeaderTap
    }

    var body: some View {
        VStack(alignment: .leading) {
            Button(action: onHeaderTap) {
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
            }
            .buttonStyle(PlainButtonStyle())

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
    let viewModel: LibraryViewModel

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

            Text("\(viewModel.getVideosForCollection(collection).count) videos")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(width: 160)
    }
}

struct StudyNoteCard: View {
    let note: StudyNote
    let video: Video?
    @State private var showingDetail = false

    var body: some View {
        Button(action: { showingDetail = true }) {
            HStack(alignment: .top, spacing: 12) {
                // Video preview with gradient
                if let video = video {
                    ZStack {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blue.opacity(0.3), Color.purple.opacity(0.3),
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )

                        VStack(spacing: 4) {
                            Text(video.title)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                            Text(formatDuration(video.metadata.duration))
                                .font(.caption2)
                                .foregroundColor(.white)
                                .monospacedDigit()
                        }
                        .padding(.horizontal, 8)
                    }
                    .frame(width: 120, height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(note.originalText)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text(note.originalText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(3)

                    Text(formatDate(note.createdAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            NavigationView {
                if let video = video {
                    VideoStudyNotesView(video: video)
                } else {
                    Text(note.originalText)
                        .padding()
                        .navigationTitle("Study Note")
                }
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatDuration(_ duration: Int) -> String {
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct SavedVideosSection: View {
    let videos: [SavedVideo]
    let viewModel: LibraryViewModel
    @Binding var selectedSection: LibrarySectionType?

    var body: some View {
        if !videos.isEmpty {
            LibrarySection(
                title: "Saved Videos",
                icon: "bookmark.fill",
                count: videos.count,
                onHeaderTap: { selectedSection = .savedVideos }
            ) {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(videos) { video in
                            SavedVideoCard(video: video, viewModel: viewModel)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

struct CompletedVideosSection: View {
    let videos: [Video]
    let viewModel: LibraryViewModel
    @Binding var selectedSection: LibrarySectionType?

    var body: some View {
        if !videos.isEmpty {
            LibrarySection(
                title: "Completed Videos",
                icon: "checkmark.circle.fill",
                count: videos.count,
                onHeaderTap: { selectedSection = .completedVideos }
            ) {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(videos) { video in
                            CompletedVideoCard(video: video, viewModel: viewModel)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

struct CollectionsSection: View {
    let collections: [Collection]
    let viewModel: LibraryViewModel
    @Binding var selectedSection: LibrarySectionType?

    var body: some View {
        if !collections.isEmpty {
            LibrarySection(
                title: "Collections",
                icon: "folder.fill",
                count: collections.count,
                onHeaderTap: { selectedSection = .collections }
            ) {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(collections) { collection in
                            CollectionCard(collection: collection, viewModel: viewModel)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

struct StudyNotesSection: View {
    let notes: [StudyNote]
    let viewModel: LibraryViewModel
    @Binding var selectedSection: LibrarySectionType?

    var body: some View {
        if !notes.isEmpty {
            LibrarySection(
                title: "Study Notes",
                icon: "note.text",
                count: notes.count,
                onHeaderTap: { selectedSection = .studyNotes }
            ) {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(notes) { note in
                            StudyNoteCard(
                                note: note,
                                video: viewModel.getVideo(id: note.videoId)
                            )
                            .frame(width: 300)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

enum LibrarySectionType: Identifiable {
    case savedVideos
    case completedVideos
    case collections
    case studyNotes

    var id: Int {
        switch self {
        case .savedVideos: return 0
        case .completedVideos: return 1
        case .collections: return 2
        case .studyNotes: return 3
        }
    }
}

struct SavedVideosFullView: View {
    let videos: [SavedVideo]
    let viewModel: LibraryViewModel
    @State private var searchText = ""
    @State private var selectedSubject: String?
    @State private var sortOption: SortOption = .dateDesc
    @State private var showingFilterSheet = false

    enum SortOption {
        case dateAsc
        case dateDesc
        case titleAsc
        case titleDesc
        case subject
        case levelAsc
        case levelDesc

        var label: String {
            switch self {
            case .dateAsc: return "Date (Oldest)"
            case .dateDesc: return "Date (Newest)"
            case .titleAsc: return "Title (A-Z)"
            case .titleDesc: return "Title (Z-A)"
            case .subject: return "Subject"
            case .levelAsc: return "Level (Low to High)"
            case .levelDesc: return "Level (High to Low)"
            }
        }
    }

    private var subjects: [String] {
        Array(Set(videos.map { $0.subject })).sorted()
    }

    private var filteredVideos: [SavedVideo] {
        var result = videos

        // Apply subject filter
        if let subject = selectedSubject {
            result = result.filter { $0.subject == subject }
        }

        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }

        // Apply sorting
        return result.sorted { (first: SavedVideo, second: SavedVideo) in
            switch sortOption {
            case .dateAsc:
                return first.savedAt < second.savedAt
            case .dateDesc:
                return first.savedAt > second.savedAt
            case .titleAsc:
                return first.title < second.title
            case .titleDesc:
                return first.title > second.title
            case .subject:
                return first.subject < second.subject
            case .levelAsc:
                let firstLevel = first.complexityLevel ?? 0
                let secondLevel = second.complexityLevel ?? 0
                print(
                    "Comparing levels: \(first.title) (\(firstLevel)) < \(second.title) (\(secondLevel))"
                )
                return firstLevel < secondLevel
            case .levelDesc:
                let firstLevel = first.complexityLevel ?? 0
                let secondLevel = second.complexityLevel ?? 0
                print(
                    "Comparing levels: \(first.title) (\(firstLevel)) > \(second.title) (\(secondLevel))"
                )
                return firstLevel > secondLevel
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search and filter bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search videos", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Menu(
                    content: {
                        ForEach(SortOption.allCases, id: \.label) { option in
                            Button(action: { sortOption = option }) {
                                HStack {
                                    Text(option.label)
                                    if sortOption == option {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    },
                    label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .foregroundColor(.blue)
                    })

                Button(action: { showingFilterSheet = true }) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.systemBackground))

            // Filter chips
            if selectedSubject != nil {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        if let subject = selectedSubject {
                            FilterChip(text: subject) {
                                selectedSubject = nil
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
            }

            // Videos grid
            ScrollView {
                LazyVGrid(
                    columns: [
                        GridItem(.adaptive(minimum: 160), spacing: 16)
                    ],
                    spacing: 16
                ) {
                    ForEach(filteredVideos) { video in
                        NavigationLink(
                            destination: VideoPlayerView(
                                video: viewModel.getVideo(id: video.id) ?? video.toVideo(),
                                isCurrent: true)
                        ) {
                            SavedVideoCard(video: video, viewModel: viewModel)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            }
            .navigationTitle("Saved Videos")
            .sheet(isPresented: $showingFilterSheet) {
                FilterSheet(selectedSubject: $selectedSubject, subjects: subjects)
            }
        }
    }
}

struct FilterChip: View {
    let text: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.subheadline)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct FilterSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedSubject: String?
    let subjects: [String]

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Subject")) {
                    ForEach(subjects, id: \.self) { subject in
                        Button(action: {
                            selectedSubject = subject
                            dismiss()
                        }) {
                            HStack {
                                Text(subject)
                                Spacer()
                                if selectedSubject == subject {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filter Videos")
            .navigationBarItems(
                leading: Button("Reset") {
                    selectedSubject = nil
                    dismiss()
                },
                trailing: Button("Done") {
                    dismiss()
                }
            )
        }
    }
}

extension SavedVideosFullView.SortOption: CaseIterable {
    static var allCases: [SavedVideosFullView.SortOption] = [
        .dateDesc,
        .dateAsc,
        .titleAsc,
        .titleDesc,
        .subject,
        .levelDesc,
        .levelAsc,
    ]
}

// Update the SavedVideo extension
extension SavedVideo {
    func toVideo() -> Video {
        return Video(
            id: id,
            title: title,
            description: "",  // Add description if available in SavedVideo
            subject: subject,
            complexityLevel: complexityLevel ?? 1,  // Use the complexity level or default to 1
            metadata: VideoMetadata(
                duration: Int(duration),  // Convert TimeInterval to Int
                views: 0,
                thumbnailUrl: thumbnailURL,
                createdAt: savedAt,
                videoUrl: videoURL,
                storagePath: ""
            ),
            position: Position(x: 0, y: 0),
            isActive: true
        )
    }
}

struct CompletedVideosFullView: View {
    let videos: [Video]
    let viewModel: LibraryViewModel

    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 160), spacing: 16)
                ], spacing: 16
            ) {
                ForEach(videos) { video in
                    CompletedVideoCard(video: video, viewModel: viewModel)
                }
            }
            .padding()
        }
        .navigationTitle("Completed Videos")
    }
}

struct CollectionsFullView: View {
    let collections: [Collection]
    let viewModel: LibraryViewModel

    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 160), spacing: 16)
                ], spacing: 16
            ) {
                ForEach(collections) { collection in
                    CollectionCard(collection: collection, viewModel: viewModel)
                }
            }
            .padding()
        }
        .navigationTitle("Collections")
    }
}

struct StudyNotesFullView: View {
    let notes: [StudyNote]
    let viewModel: LibraryViewModel

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(notes) { note in
                    StudyNoteCard(
                        note: note,
                        video: viewModel.getVideo(id: note.videoId)
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Study Notes")
    }
}

struct LibraryView: View {
    @StateObject private var viewModel = LibraryViewModel()
    @State private var showingError = false
    @State private var showingNewCollectionSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Saved Videos Section
                if !viewModel.savedVideos.isEmpty {
                    NavigationLink(
                        destination: SavedVideosFullView(
                            videos: viewModel.savedVideos, viewModel: viewModel)
                    ) {
                        HStack {
                            Label("Saved Videos", systemImage: "bookmark.fill")
                                .font(.headline)
                            Spacer()
                            Text("\(viewModel.savedVideos.count)")
                                .foregroundColor(.gray)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(PlainButtonStyle())

                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 16) {
                            ForEach(viewModel.savedVideos) { video in
                                SavedVideoCard(video: video, viewModel: viewModel)
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // Completed Videos Section
                if !viewModel.completedVideos.isEmpty {
                    NavigationLink(
                        destination: CompletedVideosFullView(
                            videos: viewModel.completedVideos, viewModel: viewModel)
                    ) {
                        HStack {
                            Label("Completed Videos", systemImage: "checkmark.circle.fill")
                                .font(.headline)
                            Spacer()
                            Text("\(viewModel.completedVideos.count)")
                                .foregroundColor(.gray)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(PlainButtonStyle())

                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 16) {
                            ForEach(viewModel.completedVideos) { video in
                                CompletedVideoCard(video: video, viewModel: viewModel)
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // Collections Section
                if !viewModel.collections.isEmpty {
                    NavigationLink(
                        destination: CollectionsFullView(
                            collections: viewModel.collections, viewModel: viewModel)
                    ) {
                        HStack {
                            Label("Collections", systemImage: "folder.fill")
                                .font(.headline)
                            Spacer()
                            Text("\(viewModel.collections.count)")
                                .foregroundColor(.gray)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(PlainButtonStyle())

                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 16) {
                            ForEach(viewModel.collections) { collection in
                                CollectionCard(collection: collection, viewModel: viewModel)
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // Study Notes Section
                if !viewModel.studyNotes.isEmpty {
                    NavigationLink(
                        destination: StudyNotesFullView(
                            notes: viewModel.studyNotes, viewModel: viewModel)
                    ) {
                        HStack {
                            Label("Study Notes", systemImage: "note.text")
                                .font(.headline)
                            Spacer()
                            Text("\(viewModel.studyNotes.count)")
                                .foregroundColor(.gray)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(PlainButtonStyle())

                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 16) {
                            ForEach(viewModel.studyNotes) { note in
                                StudyNoteCard(
                                    note: note,
                                    video: viewModel.getVideo(id: note.videoId)
                                )
                                .frame(width: 300)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Library")
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
