import AVKit
import FirebaseAuth
import FirebaseFirestore
import SwiftUI

// The GridView file is already in the same module as the other files,
// so we don't need explicit imports for internal types

struct GridView: View {
    @StateObject private var gridService = GridService()
    @State private var currentSubjectIndex = 0
    @State private var currentLevelIndex = 0
    @State private var isDragging = false
    @State private var dragStartLocation: CGPoint = .zero
    @State private var isScrollingHorizontally = false
    @State private var offset: CGSize = .zero
    @State private var user: User?

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

    private func loadUserPreferences() async {
        guard let currentUser = Auth.auth().currentUser else { return }
        do {
            if let userData = try await userService.getUser(id: currentUser.uid) {
                user = userData
                // Adjust currentLevelIndex based on user's preferred level
                if !gridService.complexityLevels.isEmpty {
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

                    // Reset to user's preferred level when switching subjects
                    if previousSubjectIndex != currentSubjectIndex,
                        let preferredLevel = user?.preferences.preferredLevel,
                        !gridService.complexityLevels.isEmpty
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
            await loadUserPreferences()
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
                        .overlay(
                            VStack {
                                Spacer()
                                VStack(spacing: 8) {
                                    Text(video.title)
                                        .font(.headline)
                                    Text(video.description)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(.ultraThinMaterial)
                            }
                        )
                } else {
                    // Show thumbnail for non-current cells
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
                        VStack {
                            Spacer()
                            VStack(spacing: 8) {
                                Text(video.title)
                                    .font(.headline)
                                Text(video.description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                        }
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
