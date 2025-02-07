import AVKit
import FirebaseAuth
import FirebaseFirestore
import Foundation

class VideoPlaybackManager: ObservableObject {
    static let shared = VideoPlaybackManager()
    private let db = Firestore.firestore()
    private let userService = UserService.shared

    @Published private(set) var currentlyPlayingVideoId: String?
    @Published private(set) var isBuffering = false
    private var currentPlayer: AVPlayer?
    private var timeObserver: Any?
    private var statusObserver: NSKeyValueObservation?
    private var itemEndObserver: NSObjectProtocol?
    private var lastUpdateTime: Date?
    private var accumulatedWatchTime: TimeInterval = 0
    private let progressThreshold: Double = 0.9  // Consider video watched at 90% completion
    private let watchTimeUpdateInterval: TimeInterval = 30  // Update watch time every 30 seconds

    private init() {}

    deinit {
        removeObservers()
        updateTotalWatchTime()
    }

    private func updateVideoProgress(videoId: String, currentTime: Double, totalTime: Double) {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let progress = currentTime / totalTime
        if progress >= progressThreshold {
            // Create or update progress document
            let progressRef = db.collection("user_progress").document("\(userId)_\(videoId)")
            progressRef.setData(
                [
                    "userId": userId,
                    "videoId": videoId,
                    "watchedFull": true,
                    "lastWatchedAt": FieldValue.serverTimestamp(),
                    "progress": progress,
                ], merge: true
            ) { error in
                if let error = error {
                    print("Error updating progress: \(error.localizedDescription)")
                }
            }
        }

        // Update accumulated watch time
        if let lastUpdate = lastUpdateTime {
            let timeElapsed = Date().timeIntervalSince(lastUpdate)
            accumulatedWatchTime += timeElapsed

            // Update total watch time in Firestore periodically
            if accumulatedWatchTime >= watchTimeUpdateInterval {
                updateTotalWatchTime()
            }
        }
        lastUpdateTime = Date()
    }

    private func updateTotalWatchTime() {
        guard accumulatedWatchTime > 0,
            let userId = Auth.auth().currentUser?.uid
        else { return }

        Task {
            do {
                if var user = try await userService.getUser(id: userId) {
                    user.stats.totalWatchTime += accumulatedWatchTime
                    try await userService.updateUser(user)
                    accumulatedWatchTime = 0
                }
            } catch {
                print("Error updating total watch time: \(error.localizedDescription)")
            }
        }
    }

    func startPlayback(videoId: String, player: AVPlayer, seekToStart: Bool = false) {
        // Stop current playback if any
        stopCurrentPlayback()

        // Start new playback
        currentlyPlayingVideoId = videoId
        currentPlayer = player
        lastUpdateTime = Date()
        accumulatedWatchTime = 0

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
        // Update total watch time before stopping
        updateTotalWatchTime()

        // Don't seek to start when pausing
        currentPlayer?.pause()
        removeObservers()
        currentPlayer = nil
        currentlyPlayingVideoId = nil
        isBuffering = false
        lastUpdateTime = nil

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

        // Observe playback progress
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self, weak player] time in
            guard let player = player,
                let duration = player.currentItem?.duration,
                !duration.isIndefinite,
                let videoId = self?.currentlyPlayingVideoId
            else { return }

            let currentTime = time.seconds
            let totalTime = duration.seconds

            // Update progress in Firestore
            self?.updateVideoProgress(
                videoId: videoId, currentTime: currentTime, totalTime: totalTime)

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
