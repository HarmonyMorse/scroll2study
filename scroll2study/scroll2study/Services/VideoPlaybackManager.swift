import AVKit
import Foundation

class VideoPlaybackManager: ObservableObject {
    static let shared = VideoPlaybackManager()

    @Published private(set) var currentlyPlayingVideoId: String?
    @Published private(set) var isBuffering = false
    private var currentPlayer: AVPlayer?
    private var timeObserver: Any?
    private var statusObserver: NSKeyValueObservation?
    private var itemEndObserver: NSObjectProtocol?

    private init() {}

    deinit {
        removeObservers()
    }

    func startPlayback(videoId: String, player: AVPlayer, seekToStart: Bool = false) {
        // Stop current playback if any
        stopCurrentPlayback()

        // Start new playback
        currentlyPlayingVideoId = videoId
        currentPlayer = player

        // Only seek to start if explicitly requested (e.g., when changing videos)
        if seekToStart {
            player.seek(to: .zero)
        }

        // Add observers
        setupObservers(for: player)

        // Enable looping
        setupLooping(for: player)

        // Start playback
        player.play()
    }

    func stopCurrentPlayback() {
        // Don't seek to start when pausing
        currentPlayer?.pause()
        removeObservers()
        currentPlayer = nil
        currentlyPlayingVideoId = nil
        isBuffering = false

        if let observer = itemEndObserver {
            NotificationCenter.default.removeObserver(observer)
            itemEndObserver = nil
        }
    }

    private func setupLooping(for player: AVPlayer) {
        // Remove any existing end observer
        if let observer = itemEndObserver {
            NotificationCenter.default.removeObserver(observer)
            itemEndObserver = nil
        }

        // Add new end observer
        itemEndObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { [weak self, weak player] _ in
            // Seek to start and continue playing
            player?.seek(to: .zero)
            player?.play()

            // Reset buffering state
            self?.isBuffering = false
        }
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

        // Observe playback progress (for debugging or future features)
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self, weak player] time in
            guard let player = player,
                let duration = player.currentItem?.duration,
                !duration.isIndefinite
            else { return }

            // We can use this for progress tracking if needed
            let currentTime = time.seconds
            let totalTime = duration.seconds

            // Update buffering state if needed
            if let self = self {
                self.isBuffering = player.timeControlStatus == .waitingToPlayAtSpecifiedRate
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
