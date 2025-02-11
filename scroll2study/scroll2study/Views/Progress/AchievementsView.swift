import SwiftUI

struct Achievement: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let progress: Double
    let goal: Int
    let current: Int
    let category: AchievementCategory
}

enum AchievementCategory: String, CaseIterable {
    case videos = "Videos"
    case subjects = "Subjects"
    case streaks = "Streaks"
    case time = "Time"
    case social = "Social"
    case special = "Special"
    
    var icon: String {
        switch self {
        case .videos: return "play.circle.fill"
        case .subjects: return "folder.fill"
        case .streaks: return "flame.fill"
        case .time: return "clock.fill"
        case .social: return "person.2.fill"
        case .special: return "star.fill"
        }
    }
}

class AchievementsViewModel: ObservableObject {
    @Published var achievements: [Achievement] = []
    
    init() {
        // Video achievements
        let videoMilestones = [1, 10, 25, 50, 100, 200, 500]
        let completedVideos = 15 // This should be fetched from your data
        
        for milestone in videoMilestones {
            achievements.append(
                Achievement(
                    title: "\(milestone) Videos",
                    description: "Complete \(milestone) videos",
                    icon: "play.circle.fill",
                    progress: min(Double(completedVideos) / Double(milestone), 1.0),
                    goal: milestone,
                    current: min(completedVideos, milestone),
                    category: .videos
                )
            )
        }
        
        // Subject achievements
        let subjectMilestones = [1, 5, 10, 25, 50, 100]
        let completedSubjects = 3 // This should be fetched from your data
        
        for milestone in subjectMilestones {
            achievements.append(
                Achievement(
                    title: "\(milestone) Subjects",
                    description: "Complete \(milestone) subjects",
                    icon: "folder.fill",
                    progress: min(Double(completedSubjects) / Double(milestone), 1.0),
                    goal: milestone,
                    current: min(completedSubjects, milestone),
                    category: .subjects
                )
            )
        }
        
        // Streak achievements
        let streakMilestones = [(3, "Weekend Warrior"), (7, "Week Champion"), (14, "Fortnight Master"), 
                               (30, "Monthly Maven"), (60, "Dedication Master"), (100, "Unstoppable"), 
                               (365, "Year of Excellence")]
        let currentStreak = 5 // This should be fetched from your data
        
        for (days, title) in streakMilestones {
            achievements.append(
                Achievement(
                    title: title,
                    description: "Maintain a \(days)-day study streak",
                    icon: "flame.fill",
                    progress: min(Double(currentStreak) / Double(days), 1.0),
                    goal: days,
                    current: min(currentStreak, days),
                    category: .streaks
                )
            )
        }
        
        // Time achievements
        let studyMinutes = 120 // This should be fetched from your data
        let timeAchievements = [
            (60, "Hour Scholar", "Study for 1 hour"),
            (180, "Deep Diver", "Study for 3 hours"),
            (300, "Focus Master", "Study for 5 hours"),
            (480, "Full-Day Scholar", "Study for 8 hours"),
            (720, "Marathon Learner", "Study for 12 hours")
        ]
        
        for (minutes, title, description) in timeAchievements {
            achievements.append(
                Achievement(
                    title: title,
                    description: description,
                    icon: "clock.fill",
                    progress: min(Double(studyMinutes) / Double(minutes), 1.0),
                    goal: minutes,
                    current: min(studyMinutes, minutes),
                    category: .time
                )
            )
        }
        
        // Social achievements
        let socialAchievements = [
            (5, "Collection Creator", "Create 5 study collections", "folder.badge.plus", 2),
            (3, "Note Taker", "Create 3 study notes", "note.text", 1),
            (10, "Helpful Scholar", "Share 10 study resources", "square.and.arrow.up", 3),
            (5, "Collaborator", "Join 5 study groups", "person.3.fill", 1),
            (20, "Community Pillar", "Help 20 other students", "hand.raised.fill", 4)
        ]
        
        for (goal, title, description, icon, current) in socialAchievements {
            achievements.append(
                Achievement(
                    title: title,
                    description: description,
                    icon: icon,
                    progress: min(Double(current) / Double(goal), 1.0),
                    goal: goal,
                    current: current,
                    category: .social
                )
            )
        }
        
        // Special achievements
        let specialAchievements = [
            ("Early Bird", "Complete a study session before 8 AM", "sunrise.fill", 0, 1),
            ("Night Owl", "Complete a study session after 10 PM", "moon.stars.fill", 1, 1),
            ("Weekend Warrior", "Study for 4 hours on a weekend", "calendar.badge.clock", 2, 4),
            ("Subject Explorer", "Study 5 different subjects in one day", "rectangle.grid.2x2.fill", 3, 5),
            ("Perfect Week", "Complete all daily goals for a week", "checkmark.seal.fill", 5, 7),
            ("Speed Learner", "Complete 3 videos in one hour", "bolt.fill", 2, 3),
            ("Diverse Scholar", "Study across all difficulty levels", "chart.bar.fill", 4, 5),
            ("Focus Champion", "Study for 2 hours without breaks", "brain.head.profile", 1, 2)
        ]
        
        for (title, description, icon, current, goal) in specialAchievements {
            achievements.append(
                Achievement(
                    title: title,
                    description: description,
                    icon: icon,
                    progress: min(Double(current) / Double(goal), 1.0),
                    goal: goal,
                    current: current,
                    category: .special
                )
            )
        }
    }
}

struct CategoryButton: View {
    let category: AchievementCategory
    let isSelected: Bool
    
    var body: some View {
        HStack {
            Image(systemName: category.icon)
                .font(.headline)
            Text(category.rawValue)
                .font(.headline)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(isSelected ? Color.blue : Color.clear)
        .foregroundColor(isSelected ? .white : .primary)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                // Achievement Icon with Background
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 44, height: 44)
                    Image(systemName: achievement.icon)
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(achievement.title)
                        .font(.headline)
                    Text(achievement.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Progress Circle
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                        .frame(width: 40, height: 40)
                    
                    Circle()
                        .trim(from: 0, to: achievement.progress)
                        .stroke(achievement.progress >= 1.0 ? Color.green : Color.blue, lineWidth: 3)
                        .frame(width: 40, height: 40)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(achievement.current)/\(achievement.goal)")
                        .font(.caption2)
                        .bold()
                }
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)
                        .cornerRadius(3)
                    
                    Rectangle()
                        .fill(achievement.progress >= 1.0 ? Color.green : Color.blue)
                        .frame(width: geometry.size.width * achievement.progress, height: 6)
                        .cornerRadius(3)
                }
            }
            .frame(height: 6)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct AchievementsView: View {
    @StateObject private var viewModel = AchievementsViewModel()
    @State private var selectedCategory: AchievementCategory = .videos
    
    var filteredAchievements: [Achievement] {
        viewModel.achievements.filter { $0.category == selectedCategory }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Category Selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(AchievementCategory.allCases, id: \.self) { category in
                            Button(action: {
                                withAnimation {
                                    selectedCategory = category
                                }
                            }) {
                                CategoryButton(
                                    category: category,
                                    isSelected: selectedCategory == category
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                // Stats Overview
                HStack(spacing: 16) {
                    let totalAchievements = viewModel.achievements.count
                    let completedAchievements = viewModel.achievements.filter { $0.progress >= 1.0 }.count
                    
                    Spacer()
                    
                    VStack {
                        Text("\(completedAchievements)")
                            .font(.title2)
                            .bold()
                        Text("Completed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack {
                        Text("\(totalAchievements)")
                            .font(.title2)
                            .bold()
                        Text("Total")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack {
                        Text("\(Int((Double(completedAchievements) / Double(totalAchievements)) * 100))%")
                            .font(.title2)
                            .bold()
                        Text("Progress")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color(UIColor.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
                
                // Achievement Cards
                LazyVStack(spacing: 16) {
                    ForEach(filteredAchievements) { achievement in
                        AchievementCard(achievement: achievement)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
}

#Preview {
    AchievementsView()
}