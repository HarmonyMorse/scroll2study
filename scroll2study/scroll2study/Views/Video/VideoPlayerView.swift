import AVFoundation
import AVKit
import SwiftUI

struct VideoPlayerView: View {
    let video: Video
    let isCurrent: Bool
    @StateObject private var playbackManager = VideoPlaybackManager.shared
    @State private var player: AVPlayer?
    @State private var isLoading = false
    @State private var error: Error?
    @State private var showSpeedPicker = false
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var timeObserver: Any?
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
                        configureAudioSession()
                        setupTimeObserver()
                        if isCurrent && !isPlaying {
                            playbackManager.startPlayback(videoId: video.id, player: player)
                        }
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
                        VStack(spacing: 8) {
                            // Progress bar at the top
                            GeometryReader { geometry in
                                VStack(spacing: 0) {
                                    ZStack(alignment: .leading) {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(height: 3)

                                        Rectangle()
                                            .fill(Color.white)
                                            .frame(
                                                width: geometry.size.width * progress,
                                                height: 3
                                            )
                                    }
                                    .gesture(
                                        DragGesture(minimumDistance: 0)
                                            .onChanged { value in
                                                if duration > 0 {
                                                    let percentage =
                                                        value.location.x / geometry.size.width
                                                    let time =
                                                        duration
                                                        * Double(max(0, min(1, percentage)))
                                                    player.seek(
                                                        to: CMTime(
                                                            seconds: time, preferredTimescale: 600))
                                                }
                                            }
                                    )
                                }
                            }
                            .frame(height: 3)
                            .padding(.top, 8)  // Add some padding from the top edge

                            Spacer()

                            // Speed button at the bottom
                            HStack {
                                Spacer()
                                Button(action: { showSpeedPicker.toggle() }) {
                                    Image(systemName: "speedometer")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(Circle())
                                }
                                .padding()
                            }
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
            // Only load if we don't already have a player
            if player == nil {
                await loadVideo()
            }
        }
        .onChange(of: isCurrent) { newIsCurrent in
            if newIsCurrent {
                if let player = player {
                    playbackManager.startPlayback(
                        videoId: video.id, player: player, seekToStart: true)
                }
            } else if isPlaying {
                playbackManager.stopCurrentPlayback()
            }
        }
        .onDisappear {
            print("DEBUG: VideoPlayerView disappeared")
            cleanupPlayer()
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
            duration = currentItem.duration.seconds

            // Observe duration changes (in case it wasn't initially available)
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: currentItem,
                queue: .main
            ) { _ in
                if let duration = player.currentItem?.duration.seconds {
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
            .navigationBarTitleDisplayMode(.inline)
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
