import AVKit
import FirebaseStorage
import SwiftUI

struct VideoPlayerView: View {
    let video: Video
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var isLoading = false
    @State private var error: Error?

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
            } else if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            } else if error != nil {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundColor(.red)
                    Text("Error loading video")
                        .foregroundColor(.red)
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
        .task {
            await loadVideo()
        }
    }

    private func loadVideo() async {
        guard !video.metadata.videoUrl.isEmpty else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            // Get the download URL from Firebase Storage
            let storage = Storage.storage()
            let videoRef = storage.reference(forURL: video.metadata.videoUrl)
            let url = try await videoRef.downloadURL()

            // Create and configure the player
            let player = AVPlayer(url: url)
            await MainActor.run {
                self.player = player
            }
        } catch {
            print("Error loading video: \(error)")
            await MainActor.run {
                self.error = error
            }
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

#Preview {
    let metadata = VideoMetadata(
        duration: 300,
        views: 0,
        thumbnailUrl: "",
        createdAt: Date(),
        videoUrl: "",
        storagePath: ""
    )
    let position = Position(x: 0, y: 0)
    let video = Video(
        id: "test",
        title: "Test Video",
        description: "Test Description",
        subject: "math",
        complexityLevel: 1,
        metadata: metadata,
        position: position,
        isActive: true
    )
    return VideoPlayerView(video: video)
}
