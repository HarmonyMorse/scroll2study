import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct SavedVideoCard: View {
    let video: SavedVideo
    @ObservedObject var viewModel: LibraryViewModel
    @State private var showingCollectionSheet = false

    var body: some View {
        VStack(alignment: .leading) {
            // Gradient background instead of thumbnail
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]
                    ),
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
                    Text(formatDuration(video.duration))
                        .font(.caption2)
                        .foregroundColor(.white)
                        .monospacedDigit()
                }
                .padding(.horizontal, 8)
            }
            .frame(width: 160, height: 90)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(video.subject)
                .font(.caption2)
                .foregroundColor(.secondary)

            HStack {
                Text("Level \(video.complexityLevel ?? 1)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: { showingCollectionSheet = true }) {
                    Image(systemName: "folder.badge.plus")
                        .foregroundColor(.blue)
                }
            }
        }
        .frame(width: 160)
        .sheet(isPresented: $showingCollectionSheet) {
            AddToCollectionSheet(viewModel: viewModel, videoId: video.id)
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
