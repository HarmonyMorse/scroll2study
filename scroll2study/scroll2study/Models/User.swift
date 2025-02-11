import FirebaseFirestore
import Foundation

struct User: Codable, Identifiable {
    let id: String  // Firebase Auth UID
    let lastActive: Date
    let role: UserRole
    var preferences: Preferences
    var profile: Profile
    var stats: Stats
    var settings: Settings
    var achievements: Achievements
    let createdAt: Date
    let updatedAt: Date

    enum UserRole: String, Codable {
        case creator
        case consumer
    }

    struct Preferences: Codable {
        var selectedSubjects: [String]
        var preferredLevel: Int
        var contentType: [String]
    }

    struct Profile: Codable {
        var bio: String
        var avatarUrl: String
        var displayName: String
    }

    struct Stats: Codable {
        var totalWatchTime: TimeInterval
        var completedVideos: Int
        var lastLoginAt: Date
        var studyStreak: Int
        var lastStudyDate: Date?
    }

    struct Settings: Codable {
        var notifications: Bool
        var autoplay: Bool
        var preferredLanguage: String
    }
    
    struct Achievements: Codable {
        var videos: VideoAchievements
        var subjects: SubjectAchievements
        var streaks: StreakAchievements
        var time: TimeAchievements
        var social: SocialAchievements
        var special: SpecialAchievements
        
        struct VideoAchievements: Codable {
            var completedVideos: Int
            var unlockedMilestones: Set<Int>
        }
        
        struct SubjectAchievements: Codable {
            var completedSubjects: Int
            var unlockedMilestones: Set<Int>
        }
        
        struct StreakAchievements: Codable {
            var longestStreak: Int
            var currentStreak: Int
            var unlockedMilestones: Set<Int>
        }
        
        struct TimeAchievements: Codable {
            var totalStudyMinutes: Int
            var longestSession: Int
            var unlockedMilestones: Set<Int>
        }
        
        struct SocialAchievements: Codable {
            var createdCollections: Int
            var createdNotes: Int
            var sharedResources: Int
            var joinedGroups: Int
            var helpedStudents: Int
            var unlockedMilestones: Set<Int>
        }
        
        struct SpecialAchievements: Codable {
            var earlyBirdSessions: Int
            var nightOwlSessions: Int
            var weekendStudySessions: Int
            var multiSubjectDays: Int
            var perfectWeeks: Int
            var speedLearning: Int
            var diverseLearning: Int
            var focusSessions: Int
            var unlockedMilestones: Set<Int>
        }
    }
}

// MARK: - Firestore Conversion
extension User {
    init?(from document: DocumentSnapshot) {
        guard let data = document.data() else { return nil }

        guard
            let lastActive = data["lastActive"] as? Timestamp,
            let roleString = data["role"] as? String,
            let role = UserRole(rawValue: roleString),
            let preferencesData = data["preferences"] as? [String: Any],
            let selectedSubjects = preferencesData["selectedSubjects"] as? [String],
            let preferredLevel = preferencesData["preferredLevel"] as? Int,
            let contentType = preferencesData["contentType"] as? [String],
            let profileData = data["profile"] as? [String: Any],
            let bio = profileData["bio"] as? String,
            let avatarUrl = profileData["avatarUrl"] as? String,
            let displayName = profileData["displayName"] as? String,
            let statsData = data["stats"] as? [String: Any],
            let totalWatchTime = statsData["totalWatchTime"] as? TimeInterval,
            let completedVideos = statsData["completedVideos"] as? Int,
            let lastLoginAt = statsData["lastLoginAt"] as? Timestamp,
            let studyStreak = statsData["studyStreak"] as? Int,
            let settingsData = data["settings"] as? [String: Any],
            let notifications = settingsData["notifications"] as? Bool,
            let autoplay = settingsData["autoplay"] as? Bool,
            let preferredLanguage = settingsData["preferredLanguage"] as? String,
            let achievementsData = data["achievements"] as? [String: Any],
            let createdAt = data["createdAt"] as? Timestamp,
            let updatedAt = data["updatedAt"] as? Timestamp
        else { return nil }

        // Parse achievements data
        let lastStudyDate = (statsData["lastStudyDate"] as? Timestamp)?.dateValue()
        
        let videoAchievements = Achievements.VideoAchievements(
            completedVideos: completedVideos,
            unlockedMilestones: Set((achievementsData["videoMilestones"] as? [Int]) ?? [])
        )
        
        let subjectAchievements = Achievements.SubjectAchievements(
            completedSubjects: achievementsData["completedSubjects"] as? Int ?? 0,
            unlockedMilestones: Set((achievementsData["subjectMilestones"] as? [Int]) ?? [])
        )
        
        let streakAchievements = Achievements.StreakAchievements(
            longestStreak: achievementsData["longestStreak"] as? Int ?? 0,
            currentStreak: studyStreak,
            unlockedMilestones: Set((achievementsData["streakMilestones"] as? [Int]) ?? [])
        )
        
        let timeAchievements = Achievements.TimeAchievements(
            totalStudyMinutes: Int(totalWatchTime / 60),
            longestSession: achievementsData["longestSession"] as? Int ?? 0,
            unlockedMilestones: Set((achievementsData["timeMilestones"] as? [Int]) ?? [])
        )
        
        let socialData = achievementsData["social"] as? [String: Any] ?? [:]
        let socialAchievements = Achievements.SocialAchievements(
            createdCollections: socialData["createdCollections"] as? Int ?? 0,
            createdNotes: socialData["createdNotes"] as? Int ?? 0,
            sharedResources: socialData["sharedResources"] as? Int ?? 0,
            joinedGroups: socialData["joinedGroups"] as? Int ?? 0,
            helpedStudents: socialData["helpedStudents"] as? Int ?? 0,
            unlockedMilestones: Set((socialData["milestones"] as? [Int]) ?? [])
        )
        
        let specialData = achievementsData["special"] as? [String: Any] ?? [:]
        let specialAchievements = Achievements.SpecialAchievements(
            earlyBirdSessions: specialData["earlyBirdSessions"] as? Int ?? 0,
            nightOwlSessions: specialData["nightOwlSessions"] as? Int ?? 0,
            weekendStudySessions: specialData["weekendStudySessions"] as? Int ?? 0,
            multiSubjectDays: specialData["multiSubjectDays"] as? Int ?? 0,
            perfectWeeks: specialData["perfectWeeks"] as? Int ?? 0,
            speedLearning: specialData["speedLearning"] as? Int ?? 0,
            diverseLearning: specialData["diverseLearning"] as? Int ?? 0,
            focusSessions: specialData["focusSessions"] as? Int ?? 0,
            unlockedMilestones: Set((specialData["milestones"] as? [Int]) ?? [])
        )

        self.id = document.documentID
        self.lastActive = lastActive.dateValue()
        self.role = role
        self.preferences = Preferences(
            selectedSubjects: selectedSubjects,
            preferredLevel: preferredLevel,
            contentType: contentType
        )
        self.profile = Profile(
            bio: bio,
            avatarUrl: avatarUrl,
            displayName: displayName
        )
        self.stats = Stats(
            totalWatchTime: totalWatchTime,
            completedVideos: completedVideos,
            lastLoginAt: lastLoginAt.dateValue(),
            studyStreak: studyStreak,
            lastStudyDate: lastStudyDate
        )
        self.settings = Settings(
            notifications: notifications,
            autoplay: autoplay,
            preferredLanguage: preferredLanguage
        )
        self.achievements = Achievements(
            videos: videoAchievements,
            subjects: subjectAchievements,
            streaks: streakAchievements,
            time: timeAchievements,
            social: socialAchievements,
            special: specialAchievements
        )
        self.createdAt = createdAt.dateValue()
        self.updatedAt = updatedAt.dateValue()
    }

    func toDictionary() -> [String: Any] {
        return [
            "lastActive": Timestamp(date: lastActive),
            "role": role.rawValue,
            "preferences": [
                "selectedSubjects": preferences.selectedSubjects,
                "preferredLevel": preferences.preferredLevel,
                "contentType": preferences.contentType,
            ],
            "profile": [
                "bio": profile.bio,
                "avatarUrl": profile.avatarUrl,
                "displayName": profile.displayName,
            ],
            "stats": [
                "totalWatchTime": stats.totalWatchTime,
                "completedVideos": stats.completedVideos,
                "lastLoginAt": Timestamp(date: stats.lastLoginAt),
                "studyStreak": stats.studyStreak,
                "lastStudyDate": stats.lastStudyDate.map { Timestamp(date: $0) }
            ],
            "settings": [
                "notifications": settings.notifications,
                "autoplay": settings.autoplay,
                "preferredLanguage": settings.preferredLanguage,
            ],
            "achievements": [
                "videoMilestones": Array(achievements.videos.unlockedMilestones),
                "completedSubjects": achievements.subjects.completedSubjects,
                "subjectMilestones": Array(achievements.subjects.unlockedMilestones),
                "longestStreak": achievements.streaks.longestStreak,
                "streakMilestones": Array(achievements.streaks.unlockedMilestones),
                "longestSession": achievements.time.longestSession,
                "timeMilestones": Array(achievements.time.unlockedMilestones),
                "social": [
                    "createdCollections": achievements.social.createdCollections,
                    "createdNotes": achievements.social.createdNotes,
                    "sharedResources": achievements.social.sharedResources,
                    "joinedGroups": achievements.social.joinedGroups,
                    "helpedStudents": achievements.social.helpedStudents,
                    "milestones": Array(achievements.social.unlockedMilestones)
                ],
                "special": [
                    "earlyBirdSessions": achievements.special.earlyBirdSessions,
                    "nightOwlSessions": achievements.special.nightOwlSessions,
                    "weekendStudySessions": achievements.special.weekendStudySessions,
                    "multiSubjectDays": achievements.special.multiSubjectDays,
                    "perfectWeeks": achievements.special.perfectWeeks,
                    "speedLearning": achievements.special.speedLearning,
                    "diverseLearning": achievements.special.diverseLearning,
                    "focusSessions": achievements.special.focusSessions,
                    "milestones": Array(achievements.special.unlockedMilestones)
                ]
            ],
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt),
        ]
    }
}
