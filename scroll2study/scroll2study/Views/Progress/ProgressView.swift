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

    func fetchData() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        isLoading = true
        error = nil

        do {
            // Fetch subjects and complexity levels using existing GridService
            let gridService = GridService()
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

    // 9:16 aspect ratio for video thumbnails (portrait)
    private let cellWidth: CGFloat = 45
    private let cellHeight: CGFloat = 80  // 9:16 ratio
    private let labelWidth: CGFloat = 50
    private let horizontalSpacing: CGFloat = 8
    private let verticalSpacing: CGFloat = 12

    private var needsHorizontalScroll: Bool {
        let totalWidth =
            labelWidth + horizontalSpacing + CGFloat(viewModel.subjects.count)
            * (cellWidth + horizontalSpacing)
        return totalWidth > containerSize.width
    }

    private var needsVerticalScroll: Bool {
        let totalHeight =
            40  // Header height
            + CGFloat(viewModel.complexityLevels.count) * (cellHeight + verticalSpacing)
        return totalHeight > containerSize.height
    }

    private func progressCell(for subject: Subject, level: ComplexityLevel) -> some View {
        let isWatched = viewModel.progressMap[subject.id]?[level.level] ?? false

        return ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(isWatched ? Color.green.opacity(0.8) : Color.gray.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(Color.gray.opacity(0.2), lineWidth: 1)
                )

            if isWatched {
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
            ScrollView(
                [
                    needsHorizontalScroll ? .horizontal : [],
                    needsVerticalScroll ? .vertical : [],
                ], showsIndicators: true
            ) {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
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
                            VStack(alignment: .leading, spacing: verticalSpacing) {
                                // Header row with subject names
                                HStack(alignment: .top, spacing: horizontalSpacing) {
                                    // Empty cell for complexity level labels
                                    Rectangle()
                                        .fill(Color.clear)
                                        .frame(width: labelWidth)

                                    // Subject headers
                                    ForEach(viewModel.subjects) { subject in
                                        Text(subject.name)
                                            .font(.caption2)
                                            .frame(width: cellWidth)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(2)
                                    }
                                }

                                // Grid rows
                                ForEach(viewModel.complexityLevels) { level in
                                    HStack(spacing: horizontalSpacing) {
                                        // Complexity level label
                                        Text("Level \(level.name)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                            .frame(width: labelWidth)
                                            .multilineTextAlignment(.trailing)

                                        // Progress cells
                                        ForEach(viewModel.subjects) { subject in
                                            progressCell(for: subject, level: level)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                        }
                        Spacer()
                    }
                    Spacer()
                }
                .frame(
                    minWidth: needsHorizontalScroll ? nil : geometry.size.width,
                    minHeight: needsVerticalScroll ? nil : geometry.size.height
                )
                .background(
                    GeometryReader { contentGeometry in
                        Color.clear.preference(
                            key: SizePreferenceKey.self,
                            value: contentGeometry.size
                        )
                    }
                )
            }
            .onPreferenceChange(SizePreferenceKey.self) { size in
                contentSize = size
            }
            .onAppear {
                containerSize = geometry.size
            }
        }
        .navigationTitle("My Progress")
        .task {
            await viewModel.fetchData()
        }
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
