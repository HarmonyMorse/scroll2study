import Foundation
import SwiftUI

// Import our custom types
struct SavedVideosFullView: View {
    let videos: [SavedVideo]
    @ObservedObject var viewModel: LibraryViewModel
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
                return firstLevel < secondLevel
            case .levelDesc:
                let firstLevel = first.complexityLevel ?? 0
                let secondLevel = second.complexityLevel ?? 0
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

// Add extension for SavedVideo to convert to Video
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
