import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class AchievementsViewModel: ObservableObject {
    @Published var achievements: [Achievement] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let userService = UserService.shared
    private let achievementService = AchievementService.shared
    private var listenerRegistration: ListenerRegistration?
    
    init() {
        setupUserListener()
    }
    
    deinit {
        listenerRegistration?.remove()
    }
    
    func setupUserListener() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        
        // Setup real-time listener for user document
        listenerRegistration = Firestore.firestore()
            .collection("users")
            .document(userId)
            .addSnapshotListener { [weak self] documentSnapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.error = error
                    self.isLoading = false
                    return
                }
                
                guard let document = documentSnapshot,
                      let user = User(from: document) else {
                    self.isLoading = false
                    return
                }
                
                self.updateAchievements(from: user)
                self.isLoading = false
            }
    }
    
    private func updateAchievements(from user: User) {
        var newAchievements: [Achievement] = []
        
        // Video achievements
        for milestone in achievementService.videoMilestones {
            let isUnlocked = user.achievements.videos.unlockedMilestones.contains(milestone)
            newAchievements.append(
                Achievement(
                    title: "\(milestone) Videos",
                    description: "Complete \(milestone) videos",
                    icon: "play.circle.fill",
                    progress: min(Double(user.stats.completedVideos) / Double(milestone), 1.0),
                    goal: milestone,
                    current: min(user.stats.completedVideos, milestone),
                    category: .videos
                )
            )
        }
        
        // Subject achievements
        for milestone in achievementService.subjectMilestones {
            let isUnlocked = user.achievements.subjects.unlockedMilestones.contains(milestone)
            newAchievements.append(
                Achievement(
                    title: "\(milestone) Subjects",
                    description: "Complete \(milestone) subjects",
                    icon: "folder.fill",
                    progress: min(Double(user.achievements.subjects.completedSubjects) / Double(milestone), 1.0),
                    goal: milestone,
                    current: min(user.achievements.subjects.completedSubjects, milestone),
                    category: .subjects
                )
            )
        }
        
        // Streak achievements
        let streakMilestones = [
            (3, "Weekend Warrior"),
            (7, "Week Champion"),
            (14, "Fortnight Master"),
            (30, "Monthly Maven"),
            (60, "Dedication Master"),
            (100, "Unstoppable"),
            (365, "Year of Excellence")
        ]
        
        for (days, title) in streakMilestones {
            let isUnlocked = user.achievements.streaks.unlockedMilestones.contains(days)
            newAchievements.append(
                Achievement(
                    title: title,
                    description: "Maintain a \(days)-day study streak",
                    icon: "flame.fill",
                    progress: min(Double(user.stats.studyStreak) / Double(days), 1.0),
                    goal: days,
                    current: min(user.stats.studyStreak, days),
                    category: .streaks
                )
            )
        }
        
        // Time achievements
        let timeAchievements = [
            (60, "Hour Scholar", "Study for 1 hour"),
            (180, "Deep Diver", "Study for 3 hours"),
            (300, "Focus Master", "Study for 5 hours"),
            (480, "Full-Day Scholar", "Study for 8 hours"),
            (720, "Marathon Learner", "Study for 12 hours")
        ]
        
        let totalStudyMinutes = Int(user.stats.totalWatchTime / 60)
        for (minutes, title, description) in timeAchievements {
            let isUnlocked = user.achievements.time.unlockedMilestones.contains(minutes)
            newAchievements.append(
                Achievement(
                    title: title,
                    description: description,
                    icon: "clock.fill",
                    progress: min(Double(totalStudyMinutes) / Double(minutes), 1.0),
                    goal: minutes,
                    current: min(totalStudyMinutes, minutes),
                    category: .time
                )
            )
        }
        
        // Social achievements
        let socialAchievements = [
            (user.achievements.social.createdCollections, "Collection Creator", "Create 5 study collections", "folder.badge.plus", 5),
            (user.achievements.social.createdNotes, "Note Taker", "Create 3 study notes", "note.text", 3),
            (user.achievements.social.sharedResources, "Helpful Scholar", "Share 10 study resources", "square.and.arrow.up", 10),
            (user.achievements.social.joinedGroups, "Collaborator", "Join 5 study groups", "person.3.fill", 5),
            (user.achievements.social.helpedStudents, "Community Pillar", "Help 20 other students", "hand.raised.fill", 20)
        ]
        
        for (current, title, description, icon, goal) in socialAchievements {
            let isUnlocked = user.achievements.social.unlockedMilestones.contains(goal)
            newAchievements.append(
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
            (user.achievements.special.earlyBirdSessions, "Early Bird", "Complete a study session before 8 AM", "sunrise.fill", 1),
            (user.achievements.special.nightOwlSessions, "Night Owl", "Complete a study session after 10 PM", "moon.stars.fill", 1),
            (user.achievements.special.weekendStudySessions, "Weekend Warrior", "Study for 4 hours on a weekend", "calendar.badge.clock", 4),
            (user.achievements.special.multiSubjectDays, "Subject Explorer", "Study 5 different subjects in one day", "rectangle.grid.2x2.fill", 5),
            (user.achievements.special.perfectWeeks, "Perfect Week", "Complete all daily goals for a week", "checkmark.seal.fill", 7),
            (user.achievements.special.speedLearning, "Speed Learner", "Complete 3 videos in one hour", "bolt.fill", 3),
            (user.achievements.special.diverseLearning, "Diverse Scholar", "Study across all difficulty levels", "chart.bar.fill", 5),
            (user.achievements.special.focusSessions, "Focus Champion", "Study for 2 hours without breaks", "brain.head.profile", 2)
        ]
        
        for (current, title, description, icon, goal) in specialAchievements {
            let isUnlocked = user.achievements.special.unlockedMilestones.contains(goal)
            newAchievements.append(
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
        
        DispatchQueue.main.async {
            self.achievements = newAchievements
        }
    }
} 