// Import the module containing LibraryViewModel
import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct CollectionsView: View {
    @ObservedObject var viewModel: LibraryViewModel
    @State private var showingNewCollectionSheet = false

    var body: some View {
        List {
            ForEach(viewModel.collections) { collection in
                NavigationLink {
                    CollectionDetailView(viewModel: viewModel, collection: collection)
                } label: {
                    HStack {
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
                            .frame(width: 60, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 60, height: 40)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .overlay(
                                    Image(systemName: "folder.fill")
                                        .foregroundColor(.gray)
                                )
                        }

                        VStack(alignment: .leading) {
                            Text(collection.name)
                                .font(.headline)
                            let videos = viewModel.getVideosForCollection(collection)
                            Text("\(videos.count) videos")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading, 8)
                    }
                }
            }
        }
        .navigationTitle("Collections")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingNewCollectionSheet = true }) {
                    Image(systemName: "folder.badge.plus")
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
                        AsyncImage(url: URL(string: video.metadata.thumbnailUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
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
}
