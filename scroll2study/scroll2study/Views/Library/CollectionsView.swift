// Import the module containing LibraryViewModel
import FirebaseAuth
import FirebaseFirestore
import SwiftUI
// Import our custom components
@_spi(Components) import scroll2study

struct CollectionsView: View {
    @ObservedObject var viewModel: LibraryViewModel
    @State private var showingNewCollectionSheet = false

    var body: some View {
        List {
            if viewModel.collections.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No Collections Yet")
                            .font(.headline)
                        Text("Create your first collection to organize your study materials")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button(action: { showingNewCollectionSheet = true }) {
                            Text("Create Collection")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        .padding(.top)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                }
            } else {
                ForEach(viewModel.collections) { collection in
                    NavigationLink(
                        destination: CollectionDetailView(
                            viewModel: viewModel, collection: collection)
                    ) {
                        HStack(spacing: 16) {
                            // Collection Gradient Background
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.blue.opacity(0.3),
                                    Color.purple.opacity(0.3)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .overlay(
                                Image(systemName: "folder.fill")
                                    .foregroundColor(.primary)
                                    .font(.system(size: 24))
                            )
                            .frame(width: 80, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                            // Collection Info
                            VStack(alignment: .leading) {
                                Text(collection.name)
                                    .font(.headline)
                                let videos = viewModel.getVideosForCollection(collection)
                                Text("\(videos.count) videos")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                if !collection.description.isEmpty {
                                    Text(collection.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
        }
        .navigationTitle("My Collections")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingNewCollectionSheet = true }) {
                    Image(systemName: "folder.badge.plus")
                }
            }
        }
        .sheet(isPresented: $showingNewCollectionSheet) {
            NewCollectionOptionsSheet(viewModel: viewModel)
        }
    }
}

struct CollectionDetailView: View {
    @ObservedObject var viewModel: LibraryViewModel
    let collection: Collection
    @State private var showingDeleteAlert = false
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var videoSelection: VideoSelectionState
    @State private var hideCompleted = false

    var body: some View {
        let videos = viewModel.getVideosForCollection(collection)
        let filteredVideos = hideCompleted ? videos.filter { !viewModel.isVideoCompleted($0.id) } : videos

        List {
            Section {
                if !collection.description.isEmpty {
                    Text(collection.description)
                        .foregroundColor(.secondary)
                }
            }

            Section {
                Toggle("Hide Completed Videos", isOn: $hideCompleted)
                    .padding(.vertical, 4)
            }

            Section {
                ForEach(filteredVideos) { video in
                    Button(action: {
                        videoSelection.selectedVideo = video
                        videoSelection.shouldNavigateToVideo = true
                    }) {
                        HStack {
                            // Gradient thumbnail with timestamp and level
                            ZStack {
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.blue.opacity(0.3), Color.purple.opacity(0.3),
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )

                                VStack(spacing: 2) {
                                    Text("Level \(video.complexityLevel)")
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                    Text(formatDuration(video.metadata.duration))
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                        .monospacedDigit()
                                }
                            }
                            .frame(width: 80, height: 45)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .overlay(
                                Group {
                                    if viewModel.isVideoCompleted(video.id) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.system(size: 16))
                                            .padding(4)
                                    }
                                },
                                alignment: .topTrailing
                            )

                            VStack(alignment: .leading) {
                                Text(video.title)
                                    .font(.headline)
                                Text(video.subject)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.leading, 8)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            Task {
                                try? await viewModel.removeVideoFromCollection(
                                    video.id, collectionId: collection.id)
                            }
                        } label: {
                            Label("Remove", systemImage: "trash")
                        }
                    }
                }
            } header: {
                Text("Videos (\(filteredVideos.count))")
            }
        }
        .navigationTitle(collection.name)
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label("Delete Collection", systemImage: "trash")
                }
            }
        }
        .alert("Delete Collection?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    try? await viewModel.deleteCollection(collection.id)
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to delete this collection? This action cannot be undone.")
        }
    }

    private func formatDuration(_ duration: Int) -> String {
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
