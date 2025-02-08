import FirebaseAuth
import FirebaseFirestore
import Foundation

class UserService {
    static let shared = UserService()
    private let db = Firestore.firestore()

    private init() {}

    func createUserDocument(user: FirebaseAuth.User, role: User.UserRole = .consumer) async throws {
        let now = Date()
        let userData = User(
            id: user.uid,
            lastActive: now,
            role: role,
            preferences: User.Preferences(
                selectedSubjects: [],
                preferredLevel: 1,
                contentType: []
            ),
            profile: User.Profile(
                bio: "",
                avatarUrl: user.photoURL?.absoluteString ?? "",
                displayName: user.displayName ?? "User"
            ),
            stats: User.Stats(
                totalWatchTime: 0,
                completedVideos: 0,
                lastLoginAt: now
            ),
            settings: User.Settings(
                notifications: true,
                autoplay: true,
                preferredLanguage: "en"
            ),
            createdAt: now,
            updatedAt: now
        )

        try await db.collection("users")
            .document(user.uid)
            .setData(from: userData)
    }

    func getUser(id: String) async throws -> User? {
        let snapshot = try await db.collection("users")
            .document(id)
            .getDocument()

        return User(from: snapshot)
    }

    func updateUser(_ user: User) async throws {
        // Create a new user instance with updated timestamp
        let updatedUser = User(
            id: user.id,
            lastActive: user.lastActive,
            role: user.role,
            preferences: user.preferences,
            profile: user.profile,
            stats: user.stats,
            settings: user.settings,
            createdAt: user.createdAt,
            updatedAt: Date()
        )

        try await db.collection("users")
            .document(user.id)
            .setData(updatedUser.toDictionary(), merge: true)
    }

    func updateLastActive(for userId: String) async throws {
        try await db.collection("users")
            .document(userId)
            .updateData([
                "lastActive": Timestamp(date: Date()),
                "updatedAt": Timestamp(date: Date()),
            ])
    }

    func updateUserPreferences(userId: String, preferences: User.Preferences) async throws {
        try await db.collection("users")
            .document(userId)
            .updateData([
                "preferences": [
                    "selectedSubjects": preferences.selectedSubjects,
                    "preferredLevel": preferences.preferredLevel,
                    "contentType": preferences.contentType,
                ],
                "updatedAt": Timestamp(date: Date()),
            ])
    }

    func updateUserSettings(userId: String, settings: User.Settings) async throws {
        try await db.collection("users")
            .document(userId)
            .updateData([
                "settings": [
                    "notifications": settings.notifications,
                    "autoplay": settings.autoplay,
                    "preferredLanguage": settings.preferredLanguage,
                ],
                "updatedAt": Timestamp(date: Date()),
            ])
    }

    func updateUserStats(userId: String, stats: User.Stats) async throws {
        try await db.collection("users")
            .document(userId)
            .updateData([
                "stats": [
                    "totalWatchTime": stats.totalWatchTime,
                    "completedVideos": stats.completedVideos,
                    "lastLoginAt": Timestamp(date: stats.lastLoginAt),
                ],
                "updatedAt": Timestamp(date: Date()),
            ])
    }
}
