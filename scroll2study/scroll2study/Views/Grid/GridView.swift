import SwiftUI

struct GridView: View {
    @StateObject private var gridService = GridService()
    @State private var currentSubjectIndex = 0
    @State private var currentLevelIndex = 0
    @State private var isDragging = false
    @State private var dragStartLocation: CGPoint = .zero
    @State private var isScrollingHorizontally = false
    @State private var offset: CGSize = .zero

    // Percentage of screen width/height needed to trigger a snap
    private let snapThreshold: CGFloat = 0.2

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
                            ) { levelIndex, level in
                                GridCell(
                                    subject: subject,
                                    level: level,
                                    hasVideo: gridService.hasVideo(for: subject.id, at: level.id)
                                )
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .offset(
                                    x: CGFloat(subjectIndex - currentSubjectIndex)
                                        * geometry.size.width + offset.width,
                                    y: CGFloat(levelIndex - currentLevelIndex)
                                        * geometry.size.height + offset.height
                                )
                            }
                        }

                        // Navigation Overlay
                        VStack {
                            if !gridService.subjects.isEmpty
                                && !gridService.complexityLevels.isEmpty
                            {
                                let currentSubject = gridService.subjects[currentSubjectIndex]
                                let currentLevel = gridService.complexityLevels[currentLevelIndex]

                                HStack(spacing: 4) {
                                    Text(currentSubject.name)
                                        .fontWeight(.bold)

                                    Text("•")
                                        .foregroundColor(.secondary)

                                    Text("Level \(currentLevel.name)")
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                                .shadow(radius: 2)
                                .padding(.top, 16)
                            }

                            Spacer()
                        }
                        .padding(.top, geometry.safeAreaInsets.top + 64)  // Increased from 44 to 64
                        .allowsHitTesting(false)
                    }
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if !isDragging {
                                    dragStartLocation = value.startLocation
                                    let horizontalDrag =
                                        abs(value.translation.width) > abs(value.translation.height)
                                    isScrollingHorizontally = horizontalDrag
                                }
                                isDragging = true

                                if isScrollingHorizontally {
                                    offset = CGSize(width: value.translation.width, height: 0)
                                } else {
                                    offset = CGSize(width: 0, height: value.translation.height)
                                }
                            }
                            .onEnded { value in
                                isDragging = false
                                let dragDistance = CGPoint(
                                    x: value.location.x - dragStartLocation.x,
                                    y: value.location.y - dragStartLocation.y
                                )

                                // Calculate percentage moved relative to screen size
                                let horizontalPercentage = abs(dragDistance.x / geometry.size.width)
                                let verticalPercentage = abs(dragDistance.y / geometry.size.height)

                                withAnimation(.easeInOut(duration: 0.3)) {
                                    if isScrollingHorizontally {
                                        if horizontalPercentage > snapThreshold {
                                            let newIndex =
                                                dragDistance.x > 0
                                                ? max(currentSubjectIndex - 1, 0)
                                                : min(
                                                    currentSubjectIndex + 1,
                                                    gridService.subjects.count - 1)
                                            currentSubjectIndex = newIndex
                                        }
                                        offset = .zero
                                    } else {
                                        if verticalPercentage > snapThreshold {
                                            let newIndex =
                                                dragDistance.y > 0
                                                ? max(currentLevelIndex - 1, 0)
                                                : min(
                                                    currentLevelIndex + 1,
                                                    gridService.complexityLevels.count - 1)
                                            currentLevelIndex = newIndex
                                        }
                                        offset = .zero
                                    }
                                }

                                // Reset scrolling direction after animation
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    isScrollingHorizontally = false
                                }
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
        }
    }
}

struct GridCell: View {
    let subject: Subject
    let level: ComplexityLevel
    let hasVideo: Bool

    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            if hasVideo {
                Text(level.description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Text(subject.description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .foregroundColor(.secondary)
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
        .opacity(hasVideo ? 1.0 : 0.8)
    }
}

#Preview {
    GridView()
}
