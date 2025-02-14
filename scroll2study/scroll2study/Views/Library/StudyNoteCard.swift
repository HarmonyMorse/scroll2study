import SwiftUI

struct StudyNoteCard: View {
    let note: StudyNote
    let video: Video?
    @State private var showingDetail = false

    var body: some View {
        Button(action: { showingDetail = true }) {
            HStack(alignment: .top, spacing: 12) {
                // Video preview with gradient
                if let video = video {
                    ZStack {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blue.opacity(0.3), Color.purple.opacity(0.3),
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )

                        VStack(spacing: 4) {
                            Text(video.title)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                            Text(formatDuration(video.metadata.duration))
                                .font(.caption2)
                                .foregroundColor(.white)
                                .monospacedDigit()
                        }
                        .padding(.horizontal, 8)
                    }
                    .frame(width: 120, height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(note.originalText)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text(note.originalText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(3)

                    Text(formatDate(note.createdAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            NavigationView {
                StudyNoteDetailView(note: note, video: video)
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatDuration(_ duration: Int) -> String {
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
