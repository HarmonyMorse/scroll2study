import FirebaseAuth
import FirebaseFirestore
import Foundation

class AchievementService {
    static let shared = AchievementService()
    private let userService = UserService.shared
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Achievement Milestones
    private let videoMilestones = [1, 10, 25, 50, 100, 200, 500]
    private let subjectMilestones = [1, 5, 10, 25, 50, 100]
    private let streakMilestones = [3, 7, 14, 30, 60, 100, 365]
    private let timeMilestones = [60, 180, 300, 480, 720] // in minutes
    private let socialMilestones = [5, 10, 25, 50, 100]
    
    // MARK: - Special Achievement Tracking
    
    /// Track a study session and update relevant achievements
    func trackStudySession(userId: String, startTime: Date, duration: TimeInterval, subjectsStudied: Set<String>) async throws {
        guard let user = try await userService.getUser(id: userId) else { return }
        var updatedUser = user
        
        // Update session time achievements
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: startTime)
        
        // Early Bird (before 8 AM)
        if hour < 8 {
            updatedUser.achievements.special.earlyBirdSessions += 1
        }
        
        // Night Owl (after 10 PM)
        if hour >= 22 {
            updatedUser.achievements.special.nightOwlSessions += 1
        }
        
        // Weekend Study
        let isWeekend = calendar.isDateInWeekend(startTime)
        if isWeekend {
            updatedUser.achievements.special.weekendStudySessions += 1
        }
        
        // Multi-subject Days
        if let lastStudyDate = user.stats.lastStudyDate,
           calendar.isDate(lastStudyDate, inSameDayAs: startTime) {
            // Add new subjects to today's studied subjects
            let studiedSubjectsToday = Set(user.preferences.selectedSubjects).union(subjectsStudied)
            if studiedSubjectsToday.count >= 5 {
                updatedUser.achievements.special.multiSubjectDays += 1
            }
        }
        
        // Focus Sessions (2+ hours without breaks)
        if duration >= 7200 { // 2 hours in seconds
            updatedUser.achievements.special.focusSessions += 1
        }
        
        // Speed Learning (3 videos in one hour)
        if duration <= 3600 && user.stats.completedVideos - user.achievements.videos.completedVideos >= 3 {
            updatedUser.achievements.special.speedLearning += 1
        }
        
        // Update longest session if applicable
        let sessionMinutes = Int(duration / 60)
        if sessionMinutes > user.achievements.time.longestSession {
            updatedUser.achievements.time.longestSession = sessionMinutes
        }
        
        // Update study streak
        try await updateStudyStreak(user: &updatedUser, studyDate: startTime)
        
        // Save updates
        try await userService.updateUser(updatedUser)
    }
    
    /// Track completion of a subject's complexity level
    func trackSubjectCompletion(userId: String, subject: String, level: Int) async throws {
        guard let user = try await userService.getUser(id: userId) else { return }
        var updatedUser = user
        
        // Track diverse learning (studying across difficulty levels)
        let studiedLevels = Set(user.preferences.selectedSubjects.map { _ in level })
        if studiedLevels.count >= 5 {
            updatedUser.achievements.special.diverseLearning += 1
        }
        
        try await userService.updateUser(updatedUser)
    }
    
    /// Track daily goals completion for perfect week achievement
    func trackDailyGoalCompletion(userId: String, date: Date) async throws {
        guard let user = try await userService.getUser(id: userId) else { return }
        var updatedUser = user
        
        let calendar = Calendar.current
        let weekOfYear = calendar.component(.weekOfYear, from: date)
        let currentWeekOfYear = calendar.component(.weekOfYear, from: Date())
        
        // If we completed all daily goals for a week
        if weekOfYear == currentWeekOfYear && user.stats.studyStreak >= 7 {
            updatedUser.achievements.special.perfectWeeks += 1
        }
        
        try await userService.updateUser(updatedUser)
    }
    
    // MARK: - Helper Functions
    
    private func updateStudyStreak(user: inout User, studyDate: Date) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let studyDay = calendar.startOfDay(for: studyDate)
        
        if let lastStudyDate = user.stats.lastStudyDate {
            let lastStudyDay = calendar.startOfDay(for: lastStudyDate)
            let daysBetween = calendar.dateComponents([.day], from: lastStudyDay, to: studyDay).day ?? 0
            
            if daysBetween == 1 {
                // Next consecutive day
                user.stats.studyStreak += 1
            } else if daysBetween == 0 {
                // Same day, no streak change
            } else {
                // Streak broken
                user.stats.studyStreak = 1
            }
        } else {
            // First study session
            user.stats.studyStreak = 1
        }
        
        // Update longest streak if applicable
        if user.stats.studyStreak > user.achievements.streaks.longestStreak {
            user.achievements.streaks.longestStreak = user.stats.studyStreak
        }
        
        user.stats.lastStudyDate = studyDate
    }
    
    /// Check and unlock achievements based on current progress
    private func checkAndUnlockAchievements(user: inout User) {
        // Video achievements
        for milestone in videoMilestones where user.stats.completedVideos >= milestone {
            user.achievements.videos.unlockedMilestones.insert(milestone)
        }
        
        // Subject achievements
        for milestone in subjectMilestones where user.achievements.subjects.completedSubjects >= milestone {
            user.achievements.subjects.unlockedMilestones.insert(milestone)
        }
        
        // Streak achievements
        for milestone in streakMilestones where user.stats.studyStreak >= milestone {
            user.achievements.streaks.unlockedMilestones.insert(milestone)
        }
        
        // Time achievements
        for milestone in timeMilestones where Int(user.stats.totalWatchTime / 60) >= milestone {
            user.achievements.time.unlockedMilestones.insert(milestone)
        }
        
        // Social achievements
        for milestone in socialMilestones {
            if user.achievements.social.createdCollections >= milestone {
                user.achievements.social.unlockedMilestones.insert(milestone)
            }
            if user.achievements.social.createdNotes >= milestone {
                user.achievements.social.unlockedMilestones.insert(milestone)
            }
            if user.achievements.social.sharedResources >= milestone {
                user.achievements.social.unlockedMilestones.insert(milestone)
            }
            if user.achievements.social.joinedGroups >= milestone {
                user.achievements.social.unlockedMilestones.insert(milestone)
            }
            if user.achievements.social.helpedStudents >= milestone {
                user.achievements.social.unlockedMilestones.insert(milestone)
            }
        }
    }
} 