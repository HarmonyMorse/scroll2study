import FirebaseAuth
import SwiftUI

struct StudyNoteDetailView: View {
    let note: StudyNote
    let video: Video?
    @Environment(\.dismiss) private var dismiss
    @State private var editedText: String
    @State private var isEditing = false
    @State private var isSaving = false
    @State private var errorMessage: String?
    private let studyNoteService = StudyNoteService.shared

    init(note: StudyNote, video: Video?) {
        self.note = note
        self.video = video
        // Initialize edited text with original note text
        _editedText = State(initialValue: note.originalText)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Video info section (if available)
                if let video = video {
                    VideoHeaderView(video: video)
                }

                // Note content section
                VStack(alignment: .leading, spacing: 8) {
                    // Timestamp and edit button header
                    HStack {
                        Text(formatDate(note.createdAt))
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        Button(action: { isEditing.toggle() }) {
                            Text(isEditing ? "Done" : "Edit")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)

                    // Rich text editor
                    if isEditing {
                        TextEditor(text: $editedText)
                            .frame(minHeight: 200)
                            .padding(8)
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                            .padding(.horizontal)
                    } else {
                        Text(editedText)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                    }

                    // Summary section (if available)
                    if let summary = note.summary {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Summary")
                                .font(.headline)
                                .padding(.horizontal)

                            Text(summary)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                    }

                    // Error message
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal)
                    }

                    // Save button (only show when editing)
                    if isEditing {
                        Button(action: saveChanges) {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Text("Save Changes")
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(8)
                            }
                        }
                        .disabled(isSaving || editedText == note.originalText)
                        .padding()
                    }
                }
            }
        }
        .navigationTitle("Study Note")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func saveChanges() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isSaving = true
        errorMessage = nil

        Task {
            do {
                try await studyNoteService.updateNote(
                    userId: userId,
                    noteId: note.id,
                    newText: editedText
                )

                await MainActor.run {
                    isEditing = false
                    isSaving = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to save changes: \(error.localizedDescription)"
                    isSaving = false
                }
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// Helper view for video information header
struct VideoHeaderView: View {
    let video: Video

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: URL(string: video.metadata.thumbnailUrl)) { image in
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
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(video.title)
                .font(.headline)

            Text(video.subject)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

#Preview {
    NavigationView {
        StudyNoteDetailView(
            note: StudyNote(
                userId: "preview",
                videoId: "preview",
                originalText:
                    "This is a sample study note with some content to preview the layout and formatting of the view.",
                summary: "A brief summary of the note's content."
            ),
            video: Video(
                id: "preview",
                title: "Sample Video",
                description: "A sample video for preview",
                subject: "Mathematics",
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
}
