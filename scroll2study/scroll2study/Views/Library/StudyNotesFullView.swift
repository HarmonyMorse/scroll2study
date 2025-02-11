import SwiftUI

struct StudyNotesFullView: View {
    let notes: [StudyNote]
    let viewModel: LibraryViewModel

    var body: some View {
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
        .navigationTitle("Study Notes")
    }
}
