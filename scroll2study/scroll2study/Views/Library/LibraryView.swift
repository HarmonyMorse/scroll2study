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
    @Published var totalWatchTime: TimeInterval = 0
    @Published var showTimeInHours = true
    @Published var error: Error?

    private let userService = UserService.shared
    private var savedVideosManager: SavedVideosManager?
    private var userListener: ListenerRegistration?

    init() {
        setupManagers()
    }

    deinit {
        userListener?.remove()
    }

    private func setupManagers() {
        savedVideosManager = SavedVideosManager()
        setupUserListener()

        // Subscribe to savedVideosManager updates
        if let videos = savedVideosManager?.savedVideos {
            savedVideos = videos
        }
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

                if let userData = snapshot.flatMap({ User(from: $0) }) {
                    self.totalWatchTime = userData.stats.totalWatchTime
                }
            }
    }

    func loadUserData() {
        Task {
            guard let currentUser = Auth.auth().currentUser else { return }
            do {
                if let userData = try await userService.getUser(id: currentUser.uid) {
                    self.totalWatchTime = userData.stats.totalWatchTime
                }
            } catch {
                self.error = error
            }
        }
    }

    func toggleTimeDisplay() {
        showTimeInHours.toggle()
    }

    func formatWatchTime() -> String {
        if showTimeInHours {
            let hours = Int(totalWatchTime / 3600)
            return "\(hours)"
        } else {
            let minutes = Int(totalWatchTime / 60)
            return "\(minutes)"
        }
    }

    var watchTimeUnit: String {
        showTimeInHours ? "Hours" : "Minutes"
    }
}

struct SavedVideoCard: View {
    let video: SavedVideo

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
        }
        .frame(width: 160)
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

struct LibraryView: View {
    @StateObject private var viewModel = LibraryViewModel()
    @State private var showingError = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("My Library")
                    .font(.largeTitle)
                    .bold()
                    .padding(.horizontal)

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

                // Saved Videos
                LibrarySection(
                    title: "Saved Videos",
                    icon: "bookmark.fill",
                    count: viewModel.savedVideos.count
                ) {
                    ForEach(viewModel.savedVideos) { video in
                        SavedVideoCard(video: video)
                    }
                }

                // My Collections
                LibrarySection(title: "My Collections", icon: "folder.fill", count: 2) {
                    ForEach(0..<2) { _ in
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 160, height: 90)
                            .overlay(
                                Image(systemName: "folder.fill")
                                    .foregroundColor(.gray)
                                    .font(.largeTitle)
                            )
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

                // Recent Achievements
                HStack {
                    Label("Recent Achievements", systemImage: "star.fill")
                        .font(.headline)
                    Spacer()
                    Text("View All")
                        .foregroundColor(.blue)
                }
                .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(0..<3) { _ in
                            VStack {
                                Circle()
                                    .fill(Color.yellow.opacity(0.2))
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.yellow)
                                    )
                                Text("Study Streak")
                                    .font(.caption)
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Study Stats
                VStack(alignment: .leading, spacing: 12) {
                    Label("Study Statistics", systemImage: "chart.bar.fill")
                        .font(.headline)
                        .padding(.horizontal)

                    HStack(spacing: 20) {
                        StatBox(
                            title: viewModel.watchTimeUnit,
                            value: viewModel.formatWatchTime(),
                            icon: "clock.fill"
                        )
                        .onTapGesture {
                            viewModel.toggleTimeDisplay()
                        }
                        StatBox(
                            title: "Videos",
                            value: "\(viewModel.savedVideos.count)",
                            icon: "play.square.fill"
                        )
                        StatBox(title: "Subjects", value: "5", icon: "folder.fill")
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
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

struct StatBox: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            Text(value)
                .font(.title3)
                .bold()
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

#Preview {
    NavigationView {
        LibraryView()
    }
}
