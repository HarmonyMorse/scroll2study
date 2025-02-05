import AVFoundation
import AVKit
import FirebaseStorage
import SwiftUI

struct VideoPlayerView: View {
    let video: Video
    let isCurrent: Bool
    @StateObject private var playbackManager = VideoPlaybackManager.shared
    @State private var player: AVPlayer?
    @State private var isLoading = false
    @State private var error: Error?

    private var isPlaying: Bool {
        playbackManager.isPlaying(videoId: video.id)
    }

    var body: some View {
        ZStack {
            if let player = player {
                VideoPlayer(player: player)
                    .onAppear {
                        configureAudioSession()
                        if isCurrent && !isPlaying {
                            playbackManager.startPlayback(videoId: video.id, player: player)
                        }
                    }
                    .onDisappear {
                        playbackManager.stopCurrentPlayback()
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
        // Watch for changes in isCurrent
        .onChange(of: isCurrent) { newIsCurrent in
            if newIsCurrent {
                if let player = player {
                    playbackManager.startPlayback(videoId: video.id, player: player)
                }
            } else if isPlaying {
                playbackManager.stopCurrentPlayback()
            }
        }
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback, mode: .moviePlayback, options: [.allowAirPlay, .allowBluetooth])
            try AVAudioSession.sharedInstance().setActive(
                true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }

    private func loadVideo() async {
        guard !video.metadata.videoUrl.isEmpty else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let storage = Storage.storage()
            let videoRef = storage.reference(forURL: video.metadata.videoUrl)
            let url = try await videoRef.downloadURL()

            let player = AVPlayer(url: url)
            player.volume = 1.0

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
        guard let player = player else { return }

        if isPlaying {
            playbackManager.stopCurrentPlayback()
        } else {
            playbackManager.startPlayback(videoId: video.id, player: player)
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
    return VideoPlayerView(video: video, isCurrent: true)
}
