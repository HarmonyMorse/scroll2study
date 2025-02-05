import AVKit
import Foundation

class VideoPlaybackManager: ObservableObject {
    static let shared = VideoPlaybackManager()

    @Published private(set) var currentlyPlayingVideoId: String?
    @Published private(set) var isBuffering = false
    private var currentPlayer: AVPlayer?
    private var timeObserver: Any?
    private var statusObserver: NSKeyValueObservation?

    private init() {}

    deinit {
        removeObservers()
    }

    func startPlayback(videoId: String, player: AVPlayer) {
        // Stop current playback if any
        stopCurrentPlayback()

        // Start new playback
        currentlyPlayingVideoId = videoId
        currentPlayer = player

        // Add observers
        setupObservers(for: player)

        // Start playback
        player.play()
    }

    func stopCurrentPlayback() {
        currentPlayer?.pause()
        removeObservers()
        currentPlayer = nil
        currentlyPlayingVideoId = nil
        isBuffering = false
    }

    private func setupObservers(for player: AVPlayer) {
        // Remove any existing observers
        removeObservers()

        // Observe buffering state
        statusObserver = player.observe(\.timeControlStatus, options: [.new]) {
            [weak self] player, _ in
            Task { @MainActor in
                self?.isBuffering = player.timeControlStatus == .waitingToPlayAtSpecifiedRate
            }
        }

        // Observe playback progress
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            if let duration = player.currentItem?.duration,
                !duration.isIndefinite
            {
                let currentTime = time.seconds
                let totalTime = duration.seconds

                // If we're at the end of the video (with a small buffer)
                if currentTime >= totalTime - 0.5 {
                    self?.stopCurrentPlayback()
                }
            }
        }
    }

    private func removeObservers() {
        if let observer = timeObserver {
            currentPlayer?.removeTimeObserver(observer)
            timeObserver = nil
        }
        statusObserver?.invalidate()
        statusObserver = nil
    }

    func isPlaying(videoId: String) -> Bool {
        return currentlyPlayingVideoId == videoId
    }
}
