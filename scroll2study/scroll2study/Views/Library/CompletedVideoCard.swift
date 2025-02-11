import SwiftUI

struct CompletedVideoCard: View {
    let video: Video
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
                    Text(formatDuration(video.metadata.duration))
                        .font(.caption2)
                        .foregroundColor(.white)
                        .monospacedDigit()
                }
                .padding(.horizontal, 8)
            }
            .frame(width: 160, height: 90)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                    .padding(8),
                alignment: .topTrailing
            )

            Text(video.subject)
                .font(.caption2)
                .foregroundColor(.secondary)

            HStack {
                Text("Level \(video.complexityLevel)")
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

    private func formatDuration(_ duration: Int) -> String {
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
