import SwiftUI

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

struct StatsOverview: View {
    let completedCount: Int
    let totalCount: Int
    let percentage: Int
    
    var body: some View {
        HStack(spacing: 16) {
            Spacer()
            
            VStack {
                Text("\(completedCount)")
                    .font(.title2)
                    .bold()
                Text("Completed")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack {
                Text("\(totalCount)")
                    .font(.title2)
                    .bold()
                Text("Total")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack {
                Text("\(percentage)%")
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
    }
} 