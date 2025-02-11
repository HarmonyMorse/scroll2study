import SwiftUI

struct CompletedVideosFullView: View {
    let videos: [Video]
    let viewModel: LibraryViewModel

    var body: some View {
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
        .navigationTitle("Completed Videos")
    }
}
