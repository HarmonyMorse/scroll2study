import SwiftUI

struct StudyNotesFullView: View {
    let notes: [StudyNote]
    let viewModel: LibraryViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingNewNoteSheet = false
    @EnvironmentObject private var videoSelection: VideoSelectionState

    var body: some View {
        VStack {
            if notes.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "note.text.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No study notes yet")
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    Text("Create notes while watching videos to help you study better")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(action: {
                        videoSelection.shouldNavigateToVideo = true
                        dismiss()
                    }) {
                        Label("Start Learning", systemImage: "play.circle.fill")
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
            }
        }
        .navigationTitle("Study Notes")
        .toolbar {
            if !notes.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNewNoteSheet = true }) {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
        }
        .sheet(isPresented: $showingNewNoteSheet) {
            StandaloneStudyNoteView()
        }
    }
}
