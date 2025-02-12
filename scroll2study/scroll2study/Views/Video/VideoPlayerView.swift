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
    @State private var showStudyNotes = false
    @State private var showCelebration = false  // New state for celebration popup
    @State private var celebrationMessage: String = ""  // Store the selected message
    private let availableSpeeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
    private let messages = [
        "Great job! 🎉",
        "You're crushing it! 💪",
        "Knowledge gained! 🧠",
        "Keep up the momentum! 🚀",
        "Learning champion! 🏆",
        "You're on fire! 🔥",
    ]

    private func checkWatchStatus() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let progressRef = Firestore.firestore().collection("user_progress").document(
            "\(userId)_\(video.id)")

        progressRef.getDocument { document, error in
            if let document = document, document.exists,
                let watchedFull = document.data()?["watchedFull"] as? Bool
            {
                DispatchQueue.main.async {
                    self.hasBeenWatched = watchedFull
                }
            }
        }
    }

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
                        player.play()
                        setupTimeObserver()
                        checkWatchStatus()
                    }
                    .onDisappear {
                        removeTimeObserver()
                        playbackManager.stopCurrentPlayback()
                    }
                    .overlay(bufferingOverlay)
                    .overlay(celebrationOverlay)
                    .overlay(controlsOverlay)
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
                    title: video.title,
                    duration: TimeInterval(video.metadata.duration),
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
            if !newIsCurrent {
                player?.pause()  // Always pause when not current
                playbackManager.stopCurrentPlayback()
                cleanupPlayer()  // Stop and cleanup when swiped away
            }
        }
        .onDisappear {
            print("DEBUG: VideoPlayerView disappeared")
            player?.pause()  // Ensure video is paused when view disappears
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
                        if !self.hasBeenWatched {
                            player.pause() // Pause the video
                            self.celebrationMessage = self.messages.randomElement() ?? "Great job! 🎉"
                            withAnimation {
                                self.showCelebration = true
                            }
                        }
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
                        subject: video.subject,
                        complexityLevel: video.complexityLevel
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

    // MARK: - View Components

    private var bufferingOverlay: some View {
        Group {
            if playbackManager.isBuffering && isPlaying {
                ZStack {
                    Color.black.opacity(0.3)
                    ProgressView()
                        .scaleEffect(1.5)
                }
            }
        }
    }

    private var celebrationOverlay: some View {
        Group {
            if showCelebration {
                CelebrationView(
                    message: celebrationMessage,
                    isPresented: $showCelebration
                )
                .transition(.opacity)
            }
        }
    }

    private var controlsOverlay: some View {
        HStack(alignment: .bottom) {
            controlButtonStack
            Spacer()
        }
        .padding(.bottom, 20)
        .padding(.leading, 16)
    }

    private var controlButtonStack: some View {
        VStack(spacing: 20) {
            Spacer()
            progressButton
            saveButton
            studyNotesButton
            speedButton
            Spacer().frame(height: 20)
        }
    }

    private var progressButton: some View {
        Button(action: { showProgressBar.toggle() }) {
            VStack(spacing: 4) {
                Image(systemName: showProgressBar ? "timer" : "timer.circle")
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
                progressBarOverlay
            }
        }
    }

    private var progressBarOverlay: some View {
        HStack(spacing: 16) {
            progressBarTrack
            timeDisplay
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.85))
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        )
        .offset(x: 180, y: 0)
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    private var progressBarTrack: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 3)
                    .frame(maxHeight: .infinity, alignment: .center)

                Capsule()
                    .fill(Color.white)
                    .opacity(hasBeenWatched ? 1.0 : 0.3)
                    .frame(width: geometry.size.width * progress, height: 3)
                    .frame(maxHeight: .infinity, alignment: .center)

                progressDragHandle(in: geometry)
            }
            .frame(height: 24)
            .gesture(progressDragGesture(in: geometry))
        }
        .frame(width: 140, height: 24)
    }

    private func progressDragHandle(in geometry: GeometryProxy) -> some View {
        Circle()
            .fill(Color.white)
            .opacity(hasBeenWatched ? 1.0 : 0.3)
            .frame(width: 12, height: 12)
            .shadow(color: .black.opacity(0.3), radius: 2)
            .position(
                x: max(6, min(geometry.size.width * progress, geometry.size.width - 6)),
                y: geometry.size.height / 2
            )
    }

    private func progressDragGesture(in geometry: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard hasBeenWatched else { return }
                if duration > 0 {
                    let percentage = value.location.x / geometry.size.width
                    let time = duration * Double(max(0, min(1, percentage)))
                    player?.seek(to: CMTime(seconds: time, preferredTimescale: 600))
                }
            }
    }

    private var timeDisplay: some View {
        Text("\(formatTime(currentTime)) / \(formatTime(duration))")
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.white)
            .monospacedDigit()
    }

    private var saveButton: some View {
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

                Text(savedVideosManager.isVideoSaved(video.id) ? "Saved" : "Save")
                    .font(.caption2)
                    .foregroundColor(.white)
            }
        }
    }

    private var studyNotesButton: some View {
        Button(action: { showStudyNotes = true }) {
            VStack(spacing: 4) {
                Image(systemName: "note.text")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.4))
                    .clipShape(Circle())

                Text("Notes")
                    .font(.caption2)
                    .foregroundColor(.white)
            }
        }
    }

    private var speedButton: some View {
        Button(action: { showSpeedPicker.toggle() }) {
            VStack(spacing: 4) {
                Image(systemName: "speedometer")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.4))
                    .clipShape(Circle())

                Text("Speed")
                    .font(.caption2)
                    .foregroundColor(.white)
            }
        }
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

struct CelebrationView: View {
    let message: String
    @Binding var isPresented: Bool

    var body: some View {
        GeometryReader { geometry in
            Color.green
                .overlay(
                    VStack {
                        Text(message)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        Text("Tap to dismiss")
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.top, 8)
                    }
                )
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation {
                        isPresented = false
                    }
                }
        }
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
