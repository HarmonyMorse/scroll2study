import Foundation
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