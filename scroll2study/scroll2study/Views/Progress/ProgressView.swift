import FirebaseAuth
import FirebaseFirestore
import SwiftUI

class ProgressViewModel: ObservableObject {
    @Published var subjects: [Subject] = []
    @Published var complexityLevels: [ComplexityLevel] = []
    @Published var progressMap: [String: [Int: Bool]] = [:]  // [subjectId: [complexityLevel: isWatched]]
    @Published var isLoading = false
    @Published var error: Error?

    private let db = Firestore.firestore()
    let gridService = GridService()  // Make this public since we need it in the view

    func fetchData() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        isLoading = true
        error = nil

        do {
            // Fetch subjects and complexity levels using existing GridService
            await gridService.fetchGridData()

            subjects = gridService.subjects.sorted(by: { $0.order < $1.order })
            complexityLevels = gridService.complexityLevels.sorted(by: { $0.level < $1.level })

            // Fetch user progress
            let progressSnapshot = try await db.collection("user_progress")
                .whereField("userId", isEqualTo: userId)
                .whereField("watchedFull", isEqualTo: true)
                .getDocuments()

            // Process progress data
            var newProgressMap: [String: [Int: Bool]] = [:]

            for document in progressSnapshot.documents {
                let data = document.data()
                if let videoId = data["videoId"] as? String {
                    // Find the video in gridService to get subject and complexity
                    if let video = gridService.videos.first(where: { $0.id == videoId }) {
                        if newProgressMap[video.subject] == nil {
                            newProgressMap[video.subject] = [:]
                        }
                        newProgressMap[video.subject]?[video.complexityLevel] = true
                    }
                }
            }

            await MainActor.run {
                self.progressMap = newProgressMap
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
        }
    }
}

struct VideoProgressView: View {
    @StateObject private var viewModel = ProgressViewModel()
    @State private var contentSize: CGSize = .zero
    @State private var containerSize: CGSize = .zero
    @State private var scrollPosition: CGPoint = .zero

    // 9:16 aspect ratio for video thumbnails (portrait)
    private let cellWidth: CGFloat = 45
    private let cellHeight: CGFloat = 80  // 9:16 ratio
    private let labelWidth: CGFloat = 50
    private let horizontalSpacing: CGFloat = 8
    private let verticalSpacing: CGFloat = 12
    private let headerHeight: CGFloat = 40

    private func progressCell(for subject: Subject, level: ComplexityLevel) -> some View {
        let isWatched = viewModel.progressMap[subject.id]?[level.level] ?? false
        let hasVideo = viewModel.gridService.hasVideo(for: subject.id, at: level.level)

        return ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(isWatched ? Color.green.opacity(0.8) : Color.gray.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(Color.gray.opacity(0.2), lineWidth: 1)
                )

            if !hasVideo {
                Image(systemName: "xmark")
                    .foregroundColor(.gray)
                    .font(.system(size: 12, weight: .bold))
            } else if isWatched {
                Image(systemName: "checkmark")
                    .foregroundColor(.white)
                    .font(.system(size: 12, weight: .bold))
            }
        }
        .frame(width: cellWidth, height: cellHeight)
        .shadow(radius: 1)
    }

    var body: some View {
        GeometryReader { geometry in
            if viewModel.isLoading {
                SwiftUI.ProgressView()
            } else if let error = viewModel.error {
                VStack {
                    Text("Error loading progress")
                        .font(.headline)
                    Text(error.localizedDescription)
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
            } else {
                ZStack(alignment: .topLeading) {
                    // Main scrollable content
                    ScrollView([.horizontal, .vertical], showsIndicators: true) {
                        VStack(alignment: .leading, spacing: verticalSpacing) {
                            // Spacer for top header
                            Color.clear.frame(height: headerHeight)

                            // Grid content
                            ForEach(viewModel.complexityLevels) { level in
                                HStack(spacing: horizontalSpacing) {
                                    // Spacer for left header
                                    Color.clear.frame(width: labelWidth + horizontalSpacing)

                                    // Progress cells
                                    ForEach(viewModel.subjects) { subject in
                                        progressCell(for: subject, level: level)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .padding(.horizontal, horizontalSpacing)
                        .background(
                            GeometryReader { proxy in
                                Color.clear.onChange(of: proxy.frame(in: .named("scroll"))) {
                                    frame in
                                    scrollPosition = CGPoint(
                                        x: frame.minX,
                                        y: frame.minY
                                    )
                                }
                            }
                        )
                    }
                    .coordinateSpace(name: "scroll")

                    // Fixed position headers
                    Group {
                        // Top header (subjects) - full width, fixed height
                        VStack {
                            HStack(spacing: horizontalSpacing) {
                                Color.clear.frame(width: labelWidth + horizontalSpacing)

                                HStack(spacing: horizontalSpacing) {
                                    ForEach(viewModel.subjects) { subject in
                                        Text(subject.name)
                                            .font(.caption2)
                                            .frame(width: cellWidth)
                                            .frame(height: headerHeight)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(2)
                                    }
                                }
                            }
                            .frame(height: headerHeight)
                            .background(Color(UIColor.systemBackground))
                            .offset(x: scrollPosition.x)

                            Spacer()
                        }
                        .zIndex(2)

                        // Left header (levels) - fixed width, full height
                        HStack {
                            VStack(alignment: .trailing, spacing: verticalSpacing) {
                                Color.clear.frame(height: headerHeight)

                                ForEach(viewModel.complexityLevels) { level in
                                    Text("Level \(level.name)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .frame(width: labelWidth)
                                        .frame(height: cellHeight)
                                        .multilineTextAlignment(.trailing)
                                        .padding(.vertical, 4)
                                }
                            }
                            .frame(width: labelWidth + horizontalSpacing)
                            .background(Color(UIColor.systemBackground))
                            .offset(y: scrollPosition.y)

                            Spacer()
                        }
                        .zIndex(1)
                    }
                }
            }
        }
        .task {
            await viewModel.fetchData()
        }
    }
}

// Preference key for tracking scroll offset
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {
        value = nextValue()
    }
}

// Size preference key to track content size
struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

#Preview {
    NavigationView {
        VideoProgressView()
    }
}
