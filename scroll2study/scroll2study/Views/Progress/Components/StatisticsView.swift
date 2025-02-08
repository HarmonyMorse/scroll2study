import SwiftUI
import Charts
import FirebaseAuth
import FirebaseFirestore

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
                    ProgressComponents.StatCard(
                        title: "Study Streak",
                        value: "\(viewModel.studyStreak) Days",
                        icon: "flame.fill",
                        color: .orange
                    )
                    ProgressComponents.StatCard(
                        title: "Videos Completed",
                        value: "\(viewModel.completedVideos.count)",
                        icon: "play.circle.fill",
                        color: .blue
                    )
                    ProgressComponents.StatCard(
                        title: "Current Level",
                        value: "\(viewModel.currentLevel)",
                        icon: "star.fill",
                        color: .purple
                    )
                    ProgressComponents.StatCard(
                        title: "Completion Rate",
                        value: "\(Int((Double(viewModel.completedVideos.count) / Double(viewModel.gridService.videos.count)) * 100))%",
                        icon: "chart.line.uptrend.xyaxis",
                        color: .green
                    )
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
                .padding(.horizontal)

                // Subject Completion Stats
                VStack(alignment: .leading, spacing: 16) {
                    Text("Subject Completion")
                        .font(.title2)
                        .bold()

                    ForEach(viewModel.subjects) { subject in
                        let progress = viewModel.getSubjectProgress(subject)
                        ProgressComponents.SubjectProgressRow(
                            subject: subject.name,
                            progress: progress,
                            color: .blue
                        )
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}

#Preview {
    StatisticsView(viewModel: ProgressViewModel())
} 