import FirebaseAuth
import SwiftUI

struct VideoStudyNotesView: View {
    let video: Video
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var noteText: String = ""
    @State private var notes: [StudyNote] = []
    @State private var isLoading: Bool = false
    @State private var isSummarizing: Bool = false
    @State private var errorMessage: String?
    @State private var selectedNote: StudyNote?

    private let studyNoteService = StudyNoteService.shared
    @Web private var web

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

                // Action buttons
                HStack {
                    Button(action: saveNote) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Save Note")
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                    }
                    .disabled(noteText.isEmpty || isLoading)

                    Button(action: summarizeAndSave) {
                        if isSummarizing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Summarize & Save")
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.green)
                                .cornerRadius(8)
                        }
                    }
                    .disabled(noteText.isEmpty || isSummarizing)
                }
                .padding()

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding()
                }

                // List of existing notes
                if authManager.isAuthenticated {
                    List(notes) { note in
                        Button(action: {
                            showNoteDetail(note)
                        }) {
                            HStack(alignment: .top, spacing: 12) {
                                // Video thumbnail
                                AsyncImage(url: URL(string: video.metadata.thumbnailUrl)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                }
                                .frame(width: 120, height: 160)
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                                VStack(alignment: .leading, spacing: 8) {
                                    Text(video.title)
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)

                                    Text(note.originalText)
                                        .font(.body)
                                        .lineLimit(4)
                                        .foregroundColor(.secondary)

                                    Text(formatDate(note.createdAt))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                    .listStyle(PlainListStyle())
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

    private func summarizeAndSave() {
        guard !noteText.isEmpty, let userId = Auth.auth().currentUser?.uid else { return }
        isSummarizing = true
        errorMessage = nil

        Task {
            do {
                // Call OpenAI API directly
                let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
                let response = try await web.post(
                    "https://api.openai.com/v1/chat/completions",
                    headers: [
                        "Authorization": "Bearer \(apiKey)",
                        "Content-Type": "application/json",
                    ],
                    body: [
                        "model": "gpt-4",
                        "messages": [
                            [
                                "role": "system",
                                "content":
                                    "You are a helpful AI that creates concise summaries of study notes. Keep summaries clear and focused on key points.",
                            ],
                            [
                                "role": "user",
                                "content":
                                    "Please summarize the following study notes in a concise paragraph:\n\n\(noteText)",
                            ],
                        ],
                    ]
                )

                guard let summary = response["choices"]["0"]["message"]["content"].string else {
                    throw NSError(
                        domain: "", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to generate summary"])
                }

                let note = try await studyNoteService.createStudyNote(
                    userId: userId,
                    videoId: video.id,
                    originalText: noteText
                )

                try await studyNoteService.updateNoteSummary(
                    userId: userId,
                    noteId: note.id,
                    summary: summary
                )

                await MainActor.run {
                    noteText = ""
                    loadNotes()
                }
            } catch {
                await MainActor.run {
                    errorMessage =
                        "Failed to summarize and save note: \(error.localizedDescription)"
                }
            }

            await MainActor.run {
                isSummarizing = false
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
