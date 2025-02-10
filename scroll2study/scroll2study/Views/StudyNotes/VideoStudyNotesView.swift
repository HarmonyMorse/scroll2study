import FirebaseAuth
import SwiftUI

struct VideoStudyNotesView: View {
    let video: Video
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var noteText: String = ""
    @State private var notes: [StudyNote] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var selectedNote: StudyNote?

    private let studyNoteService = StudyNoteService.shared

    var body: some View {
        NavigationView {
            VStack {
                // Text editor for new notes
                TextEditor(text: $noteText)
                    .frame(height: 200)
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .padding()

                // Save button
                Button(action: saveNote) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Save Note")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                }
                .disabled(noteText.isEmpty || isLoading || !authManager.isAuthenticated)
                .padding(.horizontal)

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }

                // List of existing notes
                if authManager.isAuthenticated {
                    List(notes) { note in
                        Button(action: {
                            showNoteDetail(note)
                        }) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(note.originalText)
                                    .font(.body)
                                    .lineLimit(2)
                                    .foregroundColor(.primary)

                                if let summary = note.summary {
                                    Text("Summary:")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text(summary)
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                }

                                Text(formatDate(note.createdAt))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .sheet(item: $selectedNote) { note in
                        NavigationView {
                            StudyNoteDetailView(note: note, video: video)
                        }
                    }
                } else {
                    Spacer()
                    Text("Please sign in to view and create notes")
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            .navigationTitle("Notes for \(video.title)")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
            .onAppear(perform: loadNotes)
        }
    }

    private func saveNote() {
        guard !noteText.isEmpty, let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        errorMessage = nil

        Task {
            do {
                _ = try await studyNoteService.createStudyNote(
                    userId: userId,
                    videoId: video.id,
                    originalText: noteText
                )

                // Clear the text and reload notes
                await MainActor.run {
                    noteText = ""
                    loadNotes()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to save note: \(error.localizedDescription)"
                }
            }

            await MainActor.run {
                isLoading = false
            }
        }
    }

    private func loadNotes() {
        guard let userId = Auth.auth().currentUser?.uid else {
            notes = []
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let loadedNotes = try await studyNoteService.getVideoStudyNotes(
                    userId: userId,
                    videoId: video.id
                )

                await MainActor.run {
                    notes = loadedNotes
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to load notes: \(error.localizedDescription)"
                }
            }

            await MainActor.run {
                isLoading = false
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func showNoteDetail(_ note: StudyNote) {
        selectedNote = note
    }
}

#Preview {
    VideoStudyNotesView(
        video: Video(
            id: "preview",
            title: "Sample Video",
            description: "A sample video",
            subject: "Math",
            complexityLevel: 1,
            metadata: VideoMetadata(
                duration: 300,
                views: 0,
                thumbnailUrl: "",
                createdAt: Date(),
                videoUrl: "",
                storagePath: ""
            ),
            position: Position(x: 0, y: 0),
            isActive: true
        )
    )
}
