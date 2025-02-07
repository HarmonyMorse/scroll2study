import AVFoundation
import AVKit
import FirebaseAuth  // For Auth.auth()
// Local imports
import FirebaseFirestore  // For SavedVideo
import SwiftUI

// Reference types from our app
struct VideoPlayerView: View {
    let video: Video
    let isCurrent: Bool
    @StateObject private var playbackManager = VideoPlaybackManager.shared
    @StateObject private var savedVideosManager = SavedVideosManager()
    @State private var player: AVPlayer?
    @State private var isLoading = false
    @State private var error: Error?
    @State private var showSpeedPicker = false
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var timeObserver: Any?
    @State private var showProgressBar = false
    @State private var hasBeenWatched = false  // Track if video has been watched
    private let availableSpeeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]

    private var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }

    private var isPlaying: Bool {
        playbackManager.isPlaying(videoId: video.id)
    }

    var body: some View {
        ZStack {
            if let player = player {
                CustomVideoPlayer(player: player)
                    .onAppear {
                        // Configure video player settings
                        player.play()
                        setupTimeObserver()  // Add time observer to track progress
                    }
                    .onDisappear {
                        removeTimeObserver()
                        playbackManager.stopCurrentPlayback()
                    }
                    .overlay(
                        Group {
                            if playbackManager.isBuffering && isPlaying {
                                ZStack {
                                    Color.black.opacity(0.3)
                                    ProgressView()
                                        .scaleEffect(1.5)
                                }
                            }
                        }
                    )
                    .overlay(
                        HStack(alignment: .bottom) {
                            // Left side vertical button stack
                            VStack(spacing: 20) {
                                Spacer()

                                // Progress bar toggle button
                                Button(action: { showProgressBar.toggle() }) {
                                    VStack(spacing: 4) {
                                        Image(
                                            systemName: showProgressBar ? "timer" : "timer.circle"
                                        )
                                        .font(.system(size: 28))
                                        .foregroundColor(.white)
                                        .frame(width: 44, height: 44)
                                        .background(Color.black.opacity(0.4))
                                        .clipShape(Circle())

                                        Text(showProgressBar ? "Hide" : "Time")
                                            .font(.caption2)
                                            .foregroundColor(.white)
                                    }
                                }
                                .overlay(alignment: .trailing) {
                                    if showProgressBar {
                                        // Progress popup
                                        HStack(spacing: 16) {
                                            // Progress bar
                                            GeometryReader { geometry in
                                                ZStack(alignment: .leading) {
                                                    // Background track
                                                    Capsule()
                                                        .fill(Color.white.opacity(0.3))
                                                        .frame(height: 3)
                                                        .frame(
                                                            maxHeight: .infinity, alignment: .center
                                                        )

                                                    // Progress track
                                                    Capsule()
                                                        .fill(Color.white)
                                                        .opacity(hasBeenWatched ? 1.0 : 0.3)
                                                        .frame(
                                                            width: geometry.size.width * progress,
                                                            height: 3
                                                        )
                                                        .frame(
                                                            maxHeight: .infinity, alignment: .center
                                                        )

                                                    // Drag handle
                                                    Circle()
                                                        .fill(Color.white)
                                                        .opacity(hasBeenWatched ? 1.0 : 0.3)
                                                        .frame(width: 12, height: 12)
                                                        .shadow(
                                                            color: .black.opacity(0.3), radius: 2
                                                        )
                                                        .position(
                                                            x: max(
                                                                6,
                                                                min(
                                                                    geometry.size.width * progress,
                                                                    geometry.size.width - 6)),
                                                            y: geometry.size.height / 2)
                                                }
                                                .frame(height: 24)
                                                .gesture(
                                                    DragGesture(minimumDistance: 0)
                                                        .onChanged { value in
                                                            guard hasBeenWatched else { return }  // Prevent seeking if not watched
                                                            if duration > 0 {
                                                                let percentage =
                                                                    value.location.x
                                                                    / geometry.size.width
                                                                let time =
                                                                    duration
                                                                    * Double(
                                                                        max(0, min(1, percentage)))
                                                                player.seek(
                                                                    to: CMTime(
                                                                        seconds: time,
                                                                        preferredTimescale: 600))
                                                            }
                                                        }
                                                )
                                            }
                                            .frame(width: 140, height: 24)

                                            // Time display
                                            Text(
                                                "\(formatTime(currentTime)) / \(formatTime(duration))"
                                            )
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.white)
                                            .monospacedDigit()
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color.black.opacity(0.85))
                                                .shadow(
                                                    color: .black.opacity(0.2), radius: 8, x: 0,
                                                    y: 4)
                                        )
                                        .offset(x: 180, y: 0)
                                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                                    }
                                }

                                // Save button
                                Button(action: { toggleSaveVideo() }) {
                                    VStack(spacing: 4) {
                                        Image(
                                            systemName: savedVideosManager.isVideoSaved(video.id)
                                                ? "bookmark.fill" : "bookmark"
                                        )
                                        .font(.system(size: 28))
                                        .foregroundColor(.white)
                                        .frame(width: 44, height: 44)
                                        .background(Color.black.opacity(0.4))
                                        .clipShape(Circle())

                                        Text(
                                            savedVideosManager.isVideoSaved(video.id)
                                                ? "Saved" : "Save"
                                        )
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                    }
                                }

                                // Speed button
                                Button(action: { showSpeedPicker.toggle() }) {
                                    VStack(spacing: 4) {
                                        Image(systemName: "speedometer")
                                            .font(.system(size: 28))
                                            .foregroundColor(.white)
                                            .frame(width: 44, height: 44)
                                            .background(Color.black.opacity(0.4))
                                            .clipShape(Circle())

                                        Text("\(String(format: "%.1fx", player.rate))")
                                            .font(.caption2)
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .padding(.leading, 16)
                            .padding(.bottom, 80)  // Extra padding for tab bar

                            Spacer()

                            // Right side progress info
                            VStack(alignment: .trailing) {
                                Spacer()
                                if showProgressBar {
                                    Text("\(formatTime(currentTime)) / \(formatTime(duration))")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(.trailing, 16)
                                        .padding(.bottom, 80)
                                }
                            }
                        }
                    )
                    .overlay(
                        VStack(spacing: 0) {
                            Spacer()  // Just keep this empty to remove the old progress bar
                        }
                    )
                    .sheet(isPresented: $showSpeedPicker) {
                        SpeedPickerView(player: player, speeds: availableSpeeds)
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
                VideoThumbnailView(
                    thumbnailUrl: video.metadata.thumbnailUrl,
                    onPlayTapped: {
                        Task {
                            await loadVideo()
                            if let player = player {
                                playbackManager.startPlayback(videoId: video.id, player: player)
                            }
                        }
                    }
                )
            }
        }
        .safeAreaInset(edge: .bottom) {  // Add safe area inset for tab bar
            Color.clear.frame(height: 0)
        }
        .onTapGesture {
            togglePlayback()
        }
        .onChange(of: isCurrent) { newIsCurrent in
            if !newIsCurrent && isPlaying {
                playbackManager.stopCurrentPlayback()
                cleanupPlayer()  // Stop and cleanup when swiped away
            }
        }
        .onDisappear {
            print("DEBUG: VideoPlayerView disappeared")
            cleanupPlayer()
        }
    }

    private func loadVideo() async {
        guard !video.metadata.videoUrl.isEmpty else {
            print("DEBUG: Video URL is empty")
            return
        }

        print("DEBUG: Attempting to load video with URL: \(video.metadata.videoUrl)")
        isLoading = true
        defer { isLoading = false }

        do {
            // Create player item directly with the HTTPS URL
            guard let url = URL(string: video.metadata.videoUrl) else {
                print("DEBUG: Failed to create URL from string: \(video.metadata.videoUrl)")
                throw NSError(
                    domain: "VideoPlayerView", code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Invalid video URL"])
            }

            print("DEBUG: Successfully created URL: \(url)")

            // Create player item with looping configuration
            let playerItem = AVPlayerItem(url: url)

            // Set initial duration if available
            if playerItem.status == .readyToPlay {
                self.duration = playerItem.duration.seconds
            }

            // Add observer for item status
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemFailedToPlayToEndTime,
                object: playerItem,
                queue: .main
            ) { notification in
                if let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey]
                    as? Error
                {
                    print("DEBUG: Failed to play video: \(error)")
                }
            }

            // Observe item status
            let statusObserver = playerItem.observe(\.status, options: [.new]) { item, _ in
                switch item.status {
                case .failed:
                    if let error = item.error {
                        print("DEBUG: Player item failed: \(error)")
                    }
                case .readyToPlay:
                    print("DEBUG: Player item is ready to play")
                    Task { @MainActor in
                        self.duration = item.duration.seconds
                    }
                case .unknown:
                    print("DEBUG: Player item status is unknown")
                @unknown default:
                    break
                }
            }

            print("DEBUG: Created player item")

            // Create the player
            let player = AVPlayer(playerItem: playerItem)
            player.volume = 1.0
            player.actionAtItemEnd = .none  // Prevent player from pausing at end
            print("DEBUG: Created player")

            await MainActor.run {
                self.player = player
                print("DEBUG: Set player on main actor")
                setupTimeObserver()  // Set up time observer immediately after player is created
            }
        } catch {
            print("DEBUG: Error loading video: \(error)")
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
            playbackManager.startPlayback(videoId: video.id, player: player, seekToStart: false)
        }
    }

    private func setupTimeObserver() {
        guard let player = player else { return }

        // Remove any existing observer
        removeTimeObserver()

        // Update initial duration
        if let currentItem = player.currentItem {
            // Wait for duration to be available
            if currentItem.status == .readyToPlay {
                duration = currentItem.duration.seconds
            }

            // Observe status changes to get duration when ready
            let statusObserver = currentItem.observe(\.status) { item, _ in
                if item.status == .readyToPlay {
                    Task { @MainActor in
                        self.duration = item.duration.seconds
                    }
                }
            }

            // Keep the observer alive
            objc_setAssociatedObject(
                currentItem, "statusObserver", statusObserver, .OBJC_ASSOCIATION_RETAIN)

            // Observe duration changes
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: currentItem,
                queue: .main
            ) { _ in
                let duration = player.currentItem?.duration.seconds ?? 0
                if duration > 0 {
                    Task { @MainActor in
                        self.duration = duration
                        self.hasBeenWatched = true  // Mark as watched when video completes
                    }
                }
            }

            // Also observe when duration becomes available
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemTimeJumped,
                object: currentItem,
                queue: .main
            ) { _ in
                let duration = currentItem.duration.seconds
                if !duration.isNaN && duration > 0 {
                    Task { @MainActor in
                        self.duration = duration
                    }
                }
            }
        }

        // Add periodic time observer
        let interval = CMTime(seconds: 0.1, preferredTimescale: 600)
        let observer = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            self.currentTime = time.seconds
        }
        timeObserver = observer
    }

    private func removeTimeObserver() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
    }

    private func cleanupPlayer() {
        removeTimeObserver()
        playbackManager.stopCurrentPlayback()
        player = nil
    }

    private func toggleSaveVideo() {
        Task {
            do {
                if savedVideosManager.isVideoSaved(video.id) {
                    try await savedVideosManager.removeVideo(withId: video.id)
                } else {
                    let savedVideo = SavedVideo(
                        id: video.id,
                        title: video.title,
                        thumbnailURL: video.metadata.thumbnailUrl,
                        videoURL: video.metadata.videoUrl,
                        savedAt: Date(),
                        duration: duration,
                        subject: video.subject
                    )
                    try await savedVideosManager.saveVideo(savedVideo)
                }
            } catch {
                print("Error toggling video save state: \(error)")
            }
        }
    }

    // Add this helper function for formatting time
    private func formatTime(_ timeInSeconds: Double) -> String {
        guard !timeInSeconds.isNaN && timeInSeconds.isFinite else {
            return "0:00"
        }
        let totalSeconds = Int(max(0, timeInSeconds))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct SpeedPickerView: View {
    let player: AVPlayer
    let speeds: [Double]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                ForEach(speeds, id: \.self) { speed in
                    Button(action: {
                        player.rate = Float(speed)
                        dismiss()
                    }) {
                        HStack {
                            Text("\(speed)x")
                            Spacer()
                            if player.rate == Float(speed) {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Playback Speed")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    VideoPlayerView(
        video: Video(
            id: "test",
            title: "Test Video",
            description: "Test Description",
            subject: "math",
            complexityLevel: 1,
            metadata: VideoMetadata(
                duration: 300,
                views: 0,
                thumbnailUrl: "",
                createdAt: Date(),
                videoUrl: "",
                storagePath: ""
            ),
            position: Position(x: 0, y: 0),
            isActive: true
        ),
        isCurrent: true
    )
}
