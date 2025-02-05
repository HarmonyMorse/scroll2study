import AVKit
import Foundation

class VideoPlaybackManager: ObservableObject {
    static let shared = VideoPlaybackManager()

    @Published private(set) var currentlyPlayingVideoId: String?
    private var currentPlayer: AVPlayer?
    private var timeObserver: Any?

    private init() {}

    deinit {
        removeTimeObserver()
    }

    func startPlayback(videoId: String, player: AVPlayer) {
        // Stop current playback if any
        stopCurrentPlayback()

        // Start new playback
        currentlyPlayingVideoId = videoId
        currentPlayer = player

        // Add observer to detect when video ends
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: .main
        ) { [weak self] time in
            if let duration = player.currentItem?.duration, !duration.isIndefinite {
                let currentTime = time.seconds
                let totalTime = duration.seconds

                // If we're at the end of the video (with a small buffer)
                if currentTime >= totalTime - 0.5 {
                    self?.stopCurrentPlayback()
                }
            }
        }

        player.play()
    }

    func stopCurrentPlayback() {
        currentPlayer?.pause()
        removeTimeObserver()
        currentPlayer = nil
        currentlyPlayingVideoId = nil
    }

    private func removeTimeObserver() {
        if let observer = timeObserver {
            currentPlayer?.removeTimeObserver(observer)
            timeObserver = nil
        }
    }

    func isPlaying(videoId: String) -> Bool {
        return currentlyPlayingVideoId == videoId
    }
}
