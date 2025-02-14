import AVKit
import FirebaseAuth
import FirebaseFirestore
import SwiftUI

// The GridView file is already in the same module as the other files,
// so we don't need explicit imports for internal types

struct GridView: View {
    @StateObject private var gridService = GridService()
    @EnvironmentObject private var videoSelection: VideoSelectionState
    @State private var currentSubjectIndex = 0
    @State private var currentLevelIndex = 0
    @State private var isDragging = false
    @State private var dragStartLocation: CGPoint = .zero
    @State private var isScrollingHorizontally = false
    @State private var offset: CGSize = .zero
    @State private var user: User?
    @State private var hasInitialized = false

    // Percentage of screen width/height needed to trigger a snap
    private let snapThreshold: CGFloat = 0.2
    private let userService = UserService.shared

    private var currentSubject: Subject? {
        guard !gridService.subjects.isEmpty else { return nil }
        return gridService.subjects[currentSubjectIndex]
    }

    private var currentLevel: ComplexityLevel? {
        guard !gridService.complexityLevels.isEmpty else { return nil }
        return gridService.complexityLevels[currentLevelIndex]
    }

    private func navigateToVideo(_ video: Video) {
        guard !gridService.subjects.isEmpty && !gridService.complexityLevels.isEmpty else { return }

        if let subjectIndex = gridService.subjects.firstIndex(where: { $0.id == video.subject }),
            let levelIndex = gridService.complexityLevels.firstIndex(where: {
                $0.level == video.complexityLevel
            })
        {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentSubjectIndex = subjectIndex
                currentLevelIndex = levelIndex
            }
        }
    }

    private func loadUserPreferences() async {
        guard let currentUser = Auth.auth().currentUser else { return }
        do {
            if let userData = try await userService.getUser(id: currentUser.uid) {
                user = userData
                // Only set preferred level if we haven't initialized and there's no selected video
                if !hasInitialized && !gridService.complexityLevels.isEmpty
                    && videoSelection.selectedVideo == nil
                {
                    let preferredLevel = userData.preferences.preferredLevel
                    currentLevelIndex =
                        gridService.complexityLevels.firstIndex { level in
                            level.level == preferredLevel
                        } ?? 0
                }
            }
        } catch {
            print("Error loading user preferences: \(error.localizedDescription)")
        }
    }

    private func gridCell(
        for subject: Subject, level: ComplexityLevel,
        subjectIndex: Int, levelIndex: Int,
        geometryWidth: CGFloat, geometryHeight: CGFloat
    ) -> some View {
        GridCell(
            subject: subject,
            level: level,
            hasVideo: gridService.hasVideo(for: subject.id, at: level.level),
            isCurrent: subjectIndex == currentSubjectIndex && levelIndex == currentLevelIndex,
            gridService: gridService
        )
        .frame(width: geometryWidth, height: geometryHeight)
        .offset(
            x: CGFloat(subjectIndex - currentSubjectIndex) * geometryWidth + offset.width,
            y: CGFloat(levelIndex - currentLevelIndex) * geometryHeight + offset.height
        )
    }

    private func handleDragChange(_ value: DragGesture.Value) {
        if !isDragging {
            dragStartLocation = value.startLocation
            isScrollingHorizontally = abs(value.translation.width) > abs(value.translation.height)
        }
        isDragging = true

        if isScrollingHorizontally {
            offset = CGSize(width: value.translation.width, height: 0)
        } else {
            offset = CGSize(width: 0, height: value.translation.height)
        }
    }

    private func handleDragEnd(_ value: DragGesture.Value, geometrySize: CGSize) {
        isDragging = false
        let dragDistance = CGPoint(
            x: value.location.x - dragStartLocation.x,
            y: value.location.y - dragStartLocation.y
        )

        let horizontalPercentage = abs(dragDistance.x / geometrySize.width)
        let verticalPercentage = abs(dragDistance.y / geometrySize.height)

        withAnimation(.easeInOut(duration: 0.3)) {
            if isScrollingHorizontally {
                if horizontalPercentage > snapThreshold {
                    let previousSubjectIndex = currentSubjectIndex
                    currentSubjectIndex =
                        dragDistance.x > 0
                        ? max(currentSubjectIndex - 1, 0)
                        : min(currentSubjectIndex + 1, gridService.subjects.count - 1)

                    // Only reset to preferred level when manually dragging between subjects
                    // and not when navigating from video selection
                    if previousSubjectIndex != currentSubjectIndex,
                        let preferredLevel = user?.preferences.preferredLevel,
                        !gridService.complexityLevels.isEmpty,
                        videoSelection.selectedVideo == nil  // Only reset if not from video selection
                    {
                        currentLevelIndex =
                            gridService.complexityLevels.firstIndex { level in
                                level.level == preferredLevel
                            } ?? 0
                    }
                }
            } else {
                if verticalPercentage > snapThreshold {
                    currentLevelIndex =
                        dragDistance.y > 0
                        ? max(currentLevelIndex - 1, 0)
                        : min(currentLevelIndex + 1, gridService.complexityLevels.count - 1)
                }
            }
            offset = .zero
        }

        // Reset scrolling direction after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isScrollingHorizontally = false
        }
    }

    private var navigationOverlay: some View {
        VStack {
            if let subject = currentSubject,
                let level = currentLevel
            {
                Spacer()
                HStack(spacing: 4) {
                    Text(subject.name)
                        .fontWeight(.bold)
                    Text("•")
                        .foregroundColor(.secondary)
                    Text("Level \(level.level)")
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .shadow(radius: 2)
                .padding(.bottom, 100)
            }
        }
        .allowsHitTesting(false)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if gridService.isLoading {
                    ProgressView()
                } else if let error = gridService.error {
                    VStack {
                        Text("Error loading grid")
                            .font(.headline)
                        Text(error.localizedDescription)
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                } else {
                    ZStack {
                        // Grid Content
                        ForEach(Array(gridService.subjects.enumerated()), id: \.element.id) {
                            subjectIndex, subject in
                            ForEach(
                                Array(gridService.complexityLevels.enumerated()), id: \.element.id
                            ) {
                                levelIndex, level in
                                gridCell(
                                    for: subject,
                                    level: level,
                                    subjectIndex: subjectIndex,
                                    levelIndex: levelIndex,
                                    geometryWidth: geometry.size.width,
                                    geometryHeight: geometry.size.height
                                )
                            }
                        }

                        navigationOverlay
                    }
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                handleDragChange(value)
                            }
                            .onEnded { value in
                                handleDragEnd(value, geometrySize: geometry.size)
                            }
                    )
                    .animation(.easeInOut(duration: 0.3), value: offset)
                }
            }
            .clipped()
        }
        .edgesIgnoringSafeArea(.all)
        .task {
            await gridService.fetchGridData()

            // If we have a selected video, navigate to it first
            if let video = videoSelection.selectedVideo {
                navigateToVideo(video)
                videoSelection.selectedVideo = nil
            }

            await loadUserPreferences()
            hasInitialized = true
        }
        .onChange(of: videoSelection.selectedVideo) { video in
            if let video = video {
                navigateToVideo(video)
                videoSelection.selectedVideo = nil
            }
        }
    }
}

struct GridCell: View {
    let subject: Subject
    let level: ComplexityLevel
    let hasVideo: Bool
    let isCurrent: Bool
    @ObservedObject var gridService: GridService

    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            if let video = gridService.getVideo(for: subject.id, at: level.level) {
                if isCurrent {
                    VideoPlayerView(video: video, isCurrent: true)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Gradient background for non-current cells
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.3),
                            Color.purple.opacity(0.3)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .overlay(
                        Text(video.title)
                            .font(.callout)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .padding()
                    )
                }
            } else {
                Spacer()
                Image(systemName: "video.slash")
                    .font(.system(size: 40))
                    .foregroundColor(.secondary)
                Text("No Video Available")
                    .font(.title3)
                    .foregroundColor(.secondary)
                Text("Content coming soon for this level")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }
}

#Preview {
    GridView()
}
