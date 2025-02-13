import SwiftUI

struct CompletedVideosFullView: View {
    let videos: [Video]
    let viewModel: LibraryViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            if videos.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.trianglebadge.exclamationmark")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No completed videos yet")
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    Text("Watch videos to completion to see them appear here")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(action: { dismiss() }) {
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
                    LazyVGrid(
                        columns: [
                            GridItem(.adaptive(minimum: 160), spacing: 16)
                        ], spacing: 16
                    ) {
                        ForEach(videos) { video in
                            CompletedVideoCard(video: video, viewModel: viewModel)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Completed Videos")
    }
}
