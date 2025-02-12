import FirebaseAuth
import FirebaseFirestore
import SwiftUI
import os

private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "scroll2study",
    category: "LibraryView"
)

struct LibraryView: View {
    @StateObject private var viewModel = LibraryViewModel()
    @State private var showingError = false
    @State private var showingNewCollectionSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Saved Videos Section
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

                if viewModel.savedVideos.isEmpty {
                    Text("No saved videos yet")
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                } else {
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

                if viewModel.completedVideos.isEmpty {
                    Text("No completed videos yet")
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                } else {
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

                if viewModel.collections.isEmpty {
                    Text("No collections created yet")
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                } else {
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

                if viewModel.studyNotes.isEmpty {
                    Text("No study notes yet")
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                } else {
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

#Preview {
    NavigationView {
        LibraryView()
    }
}
