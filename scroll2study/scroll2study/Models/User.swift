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
    }

    struct Settings: Codable {
        var notifications: Bool
        var autoplay: Bool
        var preferredLanguage: String
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
            let settingsData = data["settings"] as? [String: Any],
            let notifications = settingsData["notifications"] as? Bool,
            let autoplay = settingsData["autoplay"] as? Bool,
            let preferredLanguage = settingsData["preferredLanguage"] as? String,
            let createdAt = data["createdAt"] as? Timestamp,
            let updatedAt = data["updatedAt"] as? Timestamp
        else { return nil }

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
            lastLoginAt: lastLoginAt.dateValue()
        )
        self.settings = Settings(
            notifications: notifications,
            autoplay: autoplay,
            preferredLanguage: preferredLanguage
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
            ],
            "settings": [
                "notifications": settings.notifications,
                "autoplay": settings.autoplay,
                "preferredLanguage": settings.preferredLanguage,
            ],
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt),
        ]
    }
}
