// Import the module containing LibraryViewModel
import FirebaseAuth
import FirebaseFirestore
import SwiftUI

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
                            // Collection Thumbnail
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
                                        )
                                }
                                .frame(width: 80, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            } else {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 80, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        Image(systemName: "folder.fill")
                                            .foregroundColor(.gray)
                                    )
                            }

                            // Collection Info
                            VStack(alignment: .leading, spacing: 4) {
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
            if !viewModel.collections.isEmpty {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingNewCollectionSheet = true }) {
                        Image(systemName: "folder.badge.plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingNewCollectionSheet) {
            NewCollectionSheet(viewModel: viewModel)
        }
    }
}

struct CollectionDetailView: View {
    @ObservedObject var viewModel: LibraryViewModel
    let collection: Collection
    @State private var showingDeleteAlert = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        let videos = viewModel.getVideosForCollection(collection)

        List {
            Section {
                if !collection.description.isEmpty {
                    Text(collection.description)
                        .foregroundColor(.secondary)
                }
            }

            Section {
                ForEach(videos) { video in
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

                        VStack(alignment: .leading) {
                            Text(video.title)
                                .font(.headline)
                            Text(video.subject)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading, 8)
                    }
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
                Text("Videos")
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
