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
                        ForEach(Array(gridService.subjects.enumerated()), id: \.element.id) {
                            subjectIndex, subject in
                            ForEach(
                                Array(gridService.complexityLevels.enumerated()), id: \.element.id
                            ) { levelIndex, level in
                                GridCell(subject: subject, level: level)
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                                    .offset(
                                        x: CGFloat(subjectIndex - currentSubjectIndex)
                                            * geometry.size.width + offset.width,
                                        y: CGFloat(levelIndex - currentLevelIndex)
                                            * geometry.size.height + offset.height
                                    )
                            }
                        }
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

    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Text(subject.name)
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Level: \(level.name)")
                .font(.title2)
                .foregroundColor(.secondary)

            Text(level.description)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Text(subject.description)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }
}

#Preview {
    GridView()
}
