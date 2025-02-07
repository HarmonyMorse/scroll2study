import SwiftUI
import os

private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "scroll2study",
    category: "LibraryView"
)

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
    @StateObject private var savedVideosManager = SavedVideosManager()
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
                    count: savedVideosManager.savedVideos.count
                ) {
                    ForEach(savedVideosManager.savedVideos) { video in
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
                        StatBox(title: "Hours", value: "12", icon: "clock.fill")
                        StatBox(
                            title: "Videos", value: "\(savedVideosManager.savedVideos.count)",
                            icon: "play.square.fill")
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
            Text(savedVideosManager.error?.localizedDescription ?? "An unknown error occurred")
        }
        .onReceive(savedVideosManager.$error) { error in
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
