import SwiftUI
import os

private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "scroll2study",
    category: "LibraryView"
)

struct LibrarySection: View {
    let title: String
    let icon: String
    let count: Int

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
                    ForEach(0..<count, id: \.self) { _ in
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
                .padding(.horizontal)
            }
        }
    }
}

struct LibraryView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("My Library")
                    .font(.largeTitle)
                    .bold()
                    .padding(.horizontal)

                // Continue Watching
                LibrarySection(title: "Continue Watching", icon: "play.circle", count: 3)

                // Saved Videos
                LibrarySection(title: "Saved Videos", icon: "bookmark.fill", count: 4)

                // My Collections
                LibrarySection(title: "My Collections", icon: "folder.fill", count: 2)

                // Study Notes
                LibrarySection(title: "Study Notes", icon: "note.text", count: 5)

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
                        StatBox(title: "Videos", value: "24", icon: "play.square.fill")
                        StatBox(title: "Subjects", value: "5", icon: "folder.fill")
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
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
