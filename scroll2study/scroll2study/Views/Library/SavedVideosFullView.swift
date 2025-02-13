import Foundation
import SwiftUI

struct SavedVideosFullView: View {
    let videos: [SavedVideo]
    @ObservedObject var viewModel: LibraryViewModel
    @State private var searchText = ""
    @State private var selectedSubject: String?
    @State private var sortOption: SortOption = .dateDesc
    @State private var showingFilterSheet = false
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var videoSelection: VideoSelectionState

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
        VStack {
            if videos.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "bookmark.slash")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No saved videos yet")
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    Text("Start exploring videos and bookmark the ones you want to watch later")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(action: {
                        videoSelection.shouldNavigateToVideo = true
                        dismiss()
                    }) {
                        Label("Explore Videos", systemImage: "play.circle.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: 280)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
                .padding()
                .frame(maxHeight: .infinity)
            } else {
                HStack {
                    Menu {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Button(action: { sortOption = option }) {
                                if sortOption == option {
                                    Label(option.label, systemImage: "checkmark")
                                } else {
                                    Text(option.label)
                                }
                            }
                        }
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down")
                    }
                    .padding(.horizontal)

                    Spacer()

                    Button(action: { showingFilterSheet = true }) {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    }
                    .padding(.horizontal)
                }
                .padding(.top)

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
            }
        }
        .navigationTitle("Saved Videos")
        .searchable(text: $searchText, prompt: "Search videos")
        .sheet(isPresented: $showingFilterSheet) {
            FilterSheet(selectedSubject: $selectedSubject, subjects: subjects)
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
