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
    @State private var showSpeedPicker = false
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    private let availableSpeeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]

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
                        VStack {
                            Spacer()

                            // Speed button
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

                            // Progress bar
                            VStack(spacing: 0) {
                                // Custom progress bar
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(height: 3)

                                        Rectangle()
                                            .fill(Color.white)
                                            .frame(
                                                width: geometry.size.width
                                                    * CGFloat(currentTime / max(duration, 1)),
                                                height: 3)
                                    }
                                }
                                .frame(height: 3)
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { value in
                                            if duration > 0 {
                                                let percentage =
                                                    value.location.x / value.startLocation.x
                                                let time = duration * Double(percentage)
                                                player.seek(
                                                    to: CMTime(
                                                        seconds: time, preferredTimescale: 600))
                                            }
                                        }
                                )
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 100)  // Space for the nav bar
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
            await loadVideo()
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

            // Create player item with looping configuration
            let playerItem = AVPlayerItem(url: url)

            // Create the player
            let player = AVPlayer(playerItem: playerItem)
            player.volume = 1.0
            player.actionAtItemEnd = .none  // Prevent player from pausing at end

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
            playbackManager.startPlayback(videoId: video.id, player: player, seekToStart: false)
        }
    }

    private func setupTimeObserver() {
        guard let player = player else { return }

        // Update duration
        if let duration = player.currentItem?.duration {
            self.duration = duration.seconds
        }

        // Add time observer
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            currentTime = time.seconds
        }
    }

    private func removeTimeObserver() {
        // Time observer cleanup is handled by AVPlayer automatically
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
