import FirebaseAuth
import FirebaseFirestore
import SwiftUI

class ProgressViewModel: ObservableObject {
    @Published var subjects: [Subject] = []
    @Published var complexityLevels: [ComplexityLevel] = []
    @Published var progressMap: [String: [Int: Bool]] = [:]  // [subjectId: [complexityLevel: isWatched]]
    @Published var isLoading = false
    @Published var error: Error?
    @Published var studyStreak: Int = 0
    @Published var currentLevel: Int = 1
    @Published var completedVideos: [Video] = []

    private let db = Firestore.firestore()
    let gridService = GridService()  // Make this public since we need it in the view

    func getSubjectProgress(_ subject: Subject) -> Double {
        let subjectProgress = progressMap[subject.id] ?? [:]
        let totalLevels = complexityLevels.count
        let completedLevels = subjectProgress.values.filter { $0 }.count
        return totalLevels > 0 ? Double(completedLevels) / Double(totalLevels) : 0
    }

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
            var newCompletedVideos: [Video] = []

            for document in progressSnapshot.documents {
                let data = document.data()
                if let videoId = data["videoId"] as? String {
                    // Find the video in gridService to get subject and complexity
                    if let video = gridService.videos.first(where: { $0.id == videoId }) {
                        if newProgressMap[video.subject] == nil {
                            newProgressMap[video.subject] = [:]
                        }
                        newProgressMap[video.subject]?[video.complexityLevel] = true
                        newCompletedVideos.append(video)
                    }
                }
            }

            // Calculate current level based on completed videos
            let totalCompleted = progressSnapshot.documents.count
            currentLevel = max(1, min(totalCompleted / 5 + 1, complexityLevels.count))

            // Fetch study streak
            let userDoc = try await db.collection("users").document(userId).getDocument()
            if let userData = userDoc.data() {
                studyStreak = userData["studyStreak"] as? Int ?? 0
            }

            await MainActor.run {
                self.progressMap = newProgressMap
                self.completedVideos = newCompletedVideos
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

enum ProgressViewType {
    case grid
    case overview
    case achievements
}

struct ProgressMenuView: View {
    @Binding var isPresented: Bool
    @Binding var selectedView: ProgressViewType

    var body: some View {
        VStack(spacing: 20) {
            Text("Progress View")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top)

            Button(action: {
                selectedView = .grid
                isPresented = false
            }) {
                HStack {
                    Image(systemName: "square.grid.3x3")
                        .font(.title2)
                    Text("Progress Grid")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            }

            Button(action: {
                selectedView = .overview
                isPresented = false
            }) {
                HStack {
                    Image(systemName: "chart.bar")
                        .font(.title2)
                    Text("Overview")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(10)
            }

            Button(action: {
                selectedView = .achievements
                isPresented = false
            }) {
                HStack {
                    Image(systemName: "trophy")
                        .font(.title2)
                    Text("Achievements")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(10)
            }

            Button(action: {
                isPresented = false
            }) {
                Text("Cancel")
                    .foregroundColor(.secondary)
            }
            .padding(.top)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(20)
        .shadow(radius: 10)
        .padding()
    }
}

enum SubjectStatType: Int {
    case total = 0
    case explored = 1
    case completed = 2

    var title: String {
        switch self {
        case .total: return "Total Subjects"
        case .explored: return "Explored Subjects"
        case .completed: return "Completed Subjects"
        }
    }

    mutating func cycle() {
        self = SubjectStatType(rawValue: (rawValue + 1) % 3) ?? .total
    }
}

enum VideoStatType: Int {
    case total = 0
    case completed = 1

    var title: String {
        switch self {
        case .total: return "Total Videos"
        case .completed: return "Completed Videos"
        }
    }

    mutating func cycle() {
        self = VideoStatType(rawValue: (rawValue + 1) % 2) ?? .total
    }
}

enum TimeStatType: Int {
    case minutes = 0
    case hours = 1
    case streak = 2

    var title: String {
        switch self {
        case .minutes: return "Minutes Watched"
        case .hours: return "Hours Watched"
        case .streak: return "Day Streak"
        }
    }

    mutating func cycle() {
        self = TimeStatType(rawValue: (rawValue + 1) % 3) ?? .minutes
    }
}

enum SubjectFilter {
    case all
    case completed
    case inProgress
    case notStarted

    var title: String {
        switch self {
        case .all: return "All"
        case .completed: return "Completed"
        case .inProgress: return "In Progress"
        case .notStarted: return "Not Started"
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var progress: Double? = nil

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 50, height: 50)
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
            }

            VStack(spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let progress = progress {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 4)
                                .cornerRadius(2)

                            Rectangle()
                                .fill(color)
                                .frame(width: geometry.size.width * progress, height: 4)
                                .cornerRadius(2)
                        }
                    }
                    .frame(height: 4)
                    .padding(.top, 8)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct ProgressOverview: View {
    @ObservedObject var viewModel: ProgressViewModel
    @State private var subjectStatType: SubjectStatType = .total
    @State private var videoStatType: VideoStatType = .total
    @State private var timeStatType: TimeStatType = .minutes
    @State private var subjectFilter: SubjectFilter = .all

    private var exploredSubjects: [Subject] {
        viewModel.subjects.filter { subject in
            viewModel.progressMap[subject.id]?.values.contains(true) ?? false
        }
    }

    private var completedSubjects: [Subject] {
        viewModel.subjects.filter { subject in
            let progress = viewModel.getSubjectProgress(subject)
            return progress >= 1.0
        }
    }

    private var subjectStats: (title: String, value: String, progress: Double) {
        let total = viewModel.subjects.count
        switch subjectStatType {
        case .total:
            return ("Total Subjects", "\(total)", 1.0)
        case .explored:
            let explored = exploredSubjects.count
            return ("Explored Subjects", "\(explored)", Double(explored) / Double(total))
        case .completed:
            let completed = completedSubjects.count
            return ("Completed Subjects", "\(completed)", Double(completed) / Double(total))
        }
    }

    private var videoStats: (title: String, value: String, progress: Double) {
        let total = viewModel.gridService.videos.count
        switch videoStatType {
        case .total:
            return ("Total Videos", "\(total)", 1.0)
        case .completed:
            let completed = viewModel.completedVideos.count
            return ("Completed Videos", "\(completed)", Double(completed) / Double(total))
        }
    }

    private var timeStats: (title: String, value: String, progress: Double) {
        let totalMinutes = viewModel.completedVideos.reduce(0) { $0 + ($1.metadata.duration / 60) }
        let maxStreak = 30  // Maximum streak to show in progress bar

        switch timeStatType {
        case .minutes:
            return ("Minutes Watched", "\(totalMinutes)", min(Double(totalMinutes) / 1000.0, 1.0))
        case .hours:
            let hours = totalMinutes / 60
            return ("Hours Watched", "\(hours)", min(Double(hours) / 50.0, 1.0))
        case .streak:
            return (
                "Day Streak", "\(viewModel.studyStreak)",
                min(Double(viewModel.studyStreak) / Double(maxStreak), 1.0)
            )
        }
    }

    private var filteredSubjects: [Subject] {
        switch subjectFilter {
        case .all:
            return viewModel.subjects
        case .completed:
            return viewModel.subjects.filter { subject in
                let progress = viewModel.getSubjectProgress(subject)
                return progress >= 1.0
            }
        case .inProgress:
            return viewModel.subjects.filter { subject in
                let progress = viewModel.getSubjectProgress(subject)
                return progress > 0 && progress < 1.0
            }
        case .notStarted:
            return viewModel.subjects.filter { subject in
                let progress = viewModel.getSubjectProgress(subject)
                return progress == 0
            }
        }
    }

    private var emptyStateMessage: String {
        switch subjectFilter {
        case .all: return "No Subjects Available"
        case .completed: return "No Completed Subjects"
        case .inProgress: return "No Subjects In Progress"
        case .notStarted: return "No Subjects to Start"
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Main Stats Grid
                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                    ], spacing: 16
                ) {
                    Group {
                        // First Row - Original Stats
                        Button(action: {
                            withAnimation {
                                videoStatType.cycle()
                            }
                        }) {
                            StatCard(
                                title: videoStats.title,
                                value: videoStats.value,
                                icon: "play.circle.fill",
                                color: .blue,
                                progress: videoStats.progress
                            )
                        }
                        .buttonStyle(PlainButtonStyle())

                        Button(action: {
                            withAnimation {
                                subjectStatType.cycle()
                            }
                        }) {
                            StatCard(
                                title: subjectStats.title,
                                value: subjectStats.value,
                                icon: "folder.fill",
                                color: .orange,
                                progress: subjectStats.progress
                            )
                        }
                        .buttonStyle(PlainButtonStyle())

                        // Second Row - Time Stats
                        Button(action: {
                            withAnimation {
                                timeStatType.cycle()
                            }
                        }) {
                            StatCard(
                                title: timeStats.title,
                                value: timeStats.value,
                                icon: "clock.fill",
                                color: .green,
                                progress: timeStats.progress
                            )
                        }
                        .buttonStyle(PlainButtonStyle())

                        StatCard(
                            title: "Average Time/Video",
                            value: "12 min",
                            icon: "timer",
                            color: .purple,
                            progress: 0.6
                        )

                        // Third Row - Achievement Stats
                        StatCard(
                            title: "Achievements",
                            value: "3/10",
                            icon: "trophy.fill",
                            color: .yellow,
                            progress: 0.3
                        )

                        StatCard(
                            title: "Current Level",
                            value: "\(viewModel.currentLevel)",
                            icon: "star.fill",
                            color: .orange,
                            progress: Double(viewModel.currentLevel) / 10.0
                        )

                        // Fourth Row - Learning Stats
                        StatCard(
                            title: "Learning Streak",
                            value: "\(viewModel.studyStreak) days",
                            icon: "flame.fill",
                            color: .red,
                            progress: min(Double(viewModel.studyStreak) / 30.0, 1.0)
                        )

                        StatCard(
                            title: "Quiz Score",
                            value: "85%",
                            icon: "checkmark.circle.fill",
                            color: .green,
                            progress: 0.85
                        )

                        // Fifth Row - Engagement Stats
                        StatCard(
                            title: "Notes Created",
                            value: "15",
                            icon: "note.text",
                            color: .blue,
                            progress: 0.5
                        )

                        StatCard(
                            title: "Collections",
                            value: "4",
                            icon: "folder.badge.plus",
                            color: .indigo,
                            progress: 0.4
                        )
                    }
                }
                .padding(.horizontal)

                // Subject Progress
                VStack(alignment: .leading, spacing: 16) {
                    Text("Subject Progress")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)

                    // Subject Filter
                    Picker("Filter", selection: $subjectFilter) {
                        ForEach(
                            [SubjectFilter.all, .completed, .inProgress, .notStarted], id: \.self
                        ) { filter in
                            Text(filter.title)
                                .tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    if filteredSubjects.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "folder.badge.questionmark")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            Text(emptyStateMessage)
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        ForEach(filteredSubjects) { subject in
                            let progress = viewModel.getSubjectProgress(subject)
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(subject.name)
                                        .font(.headline)
                                    Spacer()
                                    Text("\(Int(progress * 100))%")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }

                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(height: 8)
                                            .cornerRadius(4)

                                        Rectangle()
                                            .fill(Color.blue)
                                            .frame(width: geometry.size.width * progress, height: 8)
                                            .cornerRadius(4)
                                    }
                                }
                                .frame(height: 8)
                            }
                            .padding()
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
}

struct VideoProgressView: View {
    @StateObject private var viewModel = ProgressViewModel()
    @EnvironmentObject private var videoSelection: VideoSelectionState
    @State private var contentSize: CGSize = .zero
    @State private var containerSize: CGSize = .zero
    @State private var scrollPosition: CGPoint = .zero
    @Binding var selectedView: ProgressViewType

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
        let video = viewModel.gridService.videos.first {
            $0.subject == subject.id && $0.complexityLevel == level.level
        }

        return Button(action: {
            if let video = video {
                videoSelection.selectedVideo = video
                videoSelection.shouldNavigateToVideo = true
            }
        }) {
            ZStack {
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
        }
        .disabled(!hasVideo)
        .frame(width: cellWidth, height: cellHeight)
        .shadow(radius: 1)
    }

    var body: some View {
        Group {
            switch selectedView {
            case .grid:
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
                        ScrollView([.horizontal, .vertical], showsIndicators: true) {
                            VStack(alignment: .leading, spacing: verticalSpacing) {
                                Color.clear.frame(height: headerHeight)

                                ForEach(viewModel.complexityLevels) { level in
                                    HStack(spacing: horizontalSpacing) {
                                        Color.clear.frame(width: labelWidth + horizontalSpacing)

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

                        Group {
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

                            HStack {
                                VStack(alignment: .trailing, spacing: verticalSpacing) {
                                    Color.clear.frame(height: headerHeight)

                                    ForEach(viewModel.complexityLevels) { level in
                                        Text("Level \(level.level)")
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
                .task {
                    await viewModel.fetchData()
                }
            case .overview:
                ProgressOverview(viewModel: viewModel)
                    .navigationBarTitleDisplayMode(.inline)
            case .achievements:
                VStack {
                    Text("Achievements Coming Soon")
                        .font(.title)
                }
            }
        }
        .navigationTitle(
            {
                switch selectedView {
                case .grid: return "Progress Grid"
                case .overview: return "Progress Overview"
                case .achievements: return "Achievements"
                }
            }())
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
        VideoProgressView(selectedView: .constant(.grid))
    }
}
