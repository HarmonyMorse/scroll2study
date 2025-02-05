import AVKit
import SwiftUI

struct VideoPlayerView: View {
    let video: Video
    @State private var player: AVPlayer?
    @State private var isPlaying = false

    var body: some View {
        ZStack {
            if let player = player {
                VideoPlayer(player: player)
                    .onAppear {
                        player.play()
                        isPlaying = true
                    }
                    .onDisappear {
                        player.pause()
                        isPlaying = false
                    }
            } else {
                // Placeholder view when video is not loaded
                AsyncImage(url: URL(string: video.metadata.thumbnailUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            ProgressView()
                        )
                }
                .overlay(
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.white)
                        .opacity(isPlaying ? 0 : 1)
                )
            }
        }
        .onTapGesture {
            togglePlayback()
        }
        .onAppear {
            // In a real app, you would get the actual video URL from your video service
            // For now, we'll use a placeholder URL
            let dummyUrl = URL(string: "https://example.com/videos/\(video.id).mp4")!
            player = AVPlayer(url: dummyUrl)
        }
    }

    private func togglePlayback() {
        if let player = player {
            if isPlaying {
                player.pause()
            } else {
                player.play()
            }
            isPlaying.toggle()
        }
    }
}
