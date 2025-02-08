import Charts
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
        NavigationView {
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
                                        Color.clear.onChange(of: proxy.frame(in: .named("scroll")))
                                        {
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
                    VStack {
                        Text("Overview Coming Soon")
                            .font(.title)
                    }
                case .achievements:
                    VStack {
                        Text("Achievements Coming Soon")
                            .font(.title)
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
            .navigationTitle(
                {
                    switch selectedView {
                    case .grid: return ""  // Empty title for grid view
                    case .overview: return "Progress Overview"
                    case .achievements: return "Achievements"
                    }
                }()
            )
        }
    }
}

struct ProgressView: View {
    @State private var selectedTab = 0
    @StateObject private var viewModel = ProgressViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Custom tab bar
            HStack(spacing: 20) {
                TabButton(
                    title: "Overview", systemImage: "chart.bar.fill",
                    isSelected: selectedTab == 0
                ) {
                    selectedTab = 0
                }

                TabButton(
                    title: "Grid", systemImage: "square.grid.3x3.fill",
                    isSelected: selectedTab == 1
                ) {
                    selectedTab = 1
                }

                TabButton(
                    title: "Statistics", systemImage: "chart.pie.fill",
                    isSelected: selectedTab == 2
                ) {
                    selectedTab = 2
                }
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)

            TabView(selection: $selectedTab) {
                ProgressOverviewView(viewModel: viewModel)
                    .tag(0)

                GridProgressView()
                    .tag(1)

                StatisticsView(viewModel: viewModel)
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .navigationTitle("Progress")
    }
}

struct TabButton: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 20))
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(isSelected ? .blue : .gray)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
}

struct ProgressOverviewView: View {
    @ObservedObject var viewModel: ProgressViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Overall Progress Card
                VStack(alignment: .leading, spacing: 12) {
                    Text("Overall Progress")
                        .font(.title2)
                        .bold()

                    ProgressBar(progress: 0.65, color: .blue)
                        .frame(height: 12)

                    HStack {
                        Text("65% Complete")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("26/40 Videos")
                            .foregroundColor(.secondary)
                    }
                    .font(.subheadline)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)

                // Subject Progress Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Subject Progress")
                        .font(.title2)
                        .bold()

                    VStack(spacing: 20) {
                        SubjectProgressRow(subject: "Mathematics", progress: 0.8, color: .blue)
                        SubjectProgressRow(subject: "Physics", progress: 0.6, color: .green)
                        SubjectProgressRow(subject: "Chemistry", progress: 0.4, color: .orange)
                        SubjectProgressRow(subject: "Biology", progress: 0.3, color: .purple)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
            }
            .padding()
        }
    }
}

struct StatisticsView: View {
    @ObservedObject var viewModel: ProgressViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Quick Stats
                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                    ], spacing: 16
                ) {
                    StatCard(
                        title: "Study Streak", value: "5 Days", icon: "flame.fill", color: .orange)
                    StatCard(
                        title: "Time Watched", value: "12.5 Hours", icon: "clock.fill", color: .blue
                    )
                    StatCard(
                        title: "Videos Today", value: "3", icon: "play.circle.fill", color: .green)
                    StatCard(
                        title: "Completion Rate", value: "85%", icon: "chart.line.uptrend.xyaxis",
                        color: .purple)
                }
                .padding(.horizontal)

                // Weekly Activity Chart
                VStack(alignment: .leading, spacing: 12) {
                    Text("Weekly Activity")
                        .font(.title2)
                        .bold()

                    Chart {
                        BarMark(x: .value("Day", "Mon"), y: .value("Videos", 3))
                        BarMark(x: .value("Day", "Tue"), y: .value("Videos", 5))
                        BarMark(x: .value("Day", "Wed"), y: .value("Videos", 2))
                        BarMark(x: .value("Day", "Thu"), y: .value("Videos", 4))
                        BarMark(x: .value("Day", "Fri"), y: .value("Videos", 6))
                        BarMark(x: .value("Day", "Sat"), y: .value("Videos", 3))
                        BarMark(x: .value("Day", "Sun"), y: .value("Videos", 1))
                    }
                    .frame(height: 200)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)

                // Achievement Stats
                VStack(alignment: .leading, spacing: 16) {
                    Text("Achievements")
                        .font(.title2)
                        .bold()

                    ForEach(["Beginner Master", "Subject Expert", "Dedication Award"], id: \.self) {
                        achievement in
                        HStack {
                            Image(systemName: "medal.fill")
                                .foregroundColor(.yellow)
                            Text(achievement)
                            Spacer()
                            Text("Earned")
                                .foregroundColor(.green)
                        }
                        .padding()
                        .background(Color(UIColor.tertiarySystemBackground))
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
            }
            .padding()
        }
    }
}

struct ProgressBar: View {
    let progress: Double
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .foregroundColor(Color(UIColor.systemGray5))

                Rectangle()
                    .foregroundColor(color)
                    .frame(width: geometry.size.width * progress)
            }
            .cornerRadius(6)
        }
    }
}

struct SubjectProgressRow: View {
    let subject: String
    let progress: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(subject)
                    .font(.headline)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .foregroundColor(.secondary)
            }

            ProgressBar(progress: progress, color: color)
                .frame(height: 8)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .foregroundColor(.secondary)
            }
            .font(.subheadline)

            Text(value)
                .font(.title2)
                .bold()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationView {
        VideoProgressView(selectedView: .constant(.grid))
    }
}
