import FirebaseAuth
import FirebaseFirestore
import Foundation
import SwiftUI

struct EditProfileView: View {
    let user: User
    let onUpdate: (User) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var displayName: String
    @State private var bio: String
    @State private var notifications: Bool
    @State private var autoplay: Bool
    @State private var preferredLanguage: String
    @State private var preferredLevel: Int
    @State private var showError = false
    @State private var errorMessage: String?

    private let userService = UserService.shared
    private let availableLevels = Array(1...15)  // Support up to 15 levels

    init(user: User, onUpdate: @escaping (User) -> Void) {
        self.user = user
        self.onUpdate = onUpdate
        _displayName = State(initialValue: user.profile.displayName)
        _bio = State(initialValue: user.profile.bio)
        _notifications = State(initialValue: user.settings.notifications)
        _autoplay = State(initialValue: user.settings.autoplay)
        _preferredLanguage = State(initialValue: user.settings.preferredLanguage)
        _preferredLevel = State(initialValue: user.preferences.preferredLevel)
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Profile Information") {
                    TextField("Display Name", text: $displayName)
                    TextField("Bio", text: $bio, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Learning Preferences") {
                    Picker("Preferred Level", selection: $preferredLevel) {
                        ForEach(availableLevels, id: \.self) { level in
                            Text(levelDescription(for: level)).tag(level)
                        }
                    }
                }

                Section("Settings") {
                    Toggle("Notifications", isOn: $notifications)
                    Toggle("Autoplay", isOn: $autoplay)

                    Picker("Language", selection: $preferredLanguage) {
                        Text("English").tag("en")
                        Text("Spanish").tag("es")
                        Text("French").tag("fr")
                        Text("German").tag("de")
                    }
                }
            }
            .navigationTitle("Edit Profile")
            #if !os(macOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }

    private func levelDescription(for level: Int) -> String {
        return "Level \(level)"
    }

    private func saveChanges() {
        var updatedUser = user

        // Update profile
        updatedUser.profile.displayName = displayName
        updatedUser.profile.bio = bio

        // Update preferences
        updatedUser.preferences.preferredLevel = preferredLevel

        // Update settings
        updatedUser.settings.notifications = notifications
        updatedUser.settings.autoplay = autoplay
        updatedUser.settings.preferredLanguage = preferredLanguage

        Task {
            do {
                try await userService.updateUser(updatedUser)
                onUpdate(updatedUser)
                dismiss()
            } catch {
                errorMessage = "Failed to update profile: \(error.localizedDescription)"
                showError = true
            }
        }
    }
}

#Preview {
    EditProfileView(
        user: User(
            id: "preview",
            lastActive: Date(),
            role: .consumer,
            preferences: User.Preferences(
                selectedSubjects: [],
                preferredLevel: 1,
                contentType: []
            ),
            profile: User.Profile(
                bio: "Sample bio",
                avatarUrl: "",
                displayName: "Preview User"
            ),
            stats: User.Stats(
                totalWatchTime: 3600,
                completedVideos: 10,
                lastLoginAt: Date(),
                studyStreak: 0,
                lastStudyDate: nil
            ),
            settings: User.Settings(
                notifications: true,
                autoplay: true,
                preferredLanguage: "en"
            ),
            achievements: User.Achievements(
                videos: .init(completedVideos: 0, unlockedMilestones: []),
                subjects: .init(completedSubjects: 0, unlockedMilestones: []),
                streaks: .init(longestStreak: 0, currentStreak: 0, unlockedMilestones: []),
                time: .init(totalStudyMinutes: 0, longestSession: 0, unlockedMilestones: []),
                social: .init(
                    createdCollections: 0,
                    createdNotes: 0,
                    sharedResources: 0,
                    joinedGroups: 0,
                    helpedStudents: 0,
                    unlockedMilestones: []
                ),
                special: .init(
                    earlyBirdSessions: 0,
                    nightOwlSessions: 0,
                    weekendStudySessions: 0,
                    multiSubjectDays: 0,
                    perfectWeeks: 0,
                    speedLearning: 0,
                    diverseLearning: 0,
                    focusSessions: 0,
                    unlockedMilestones: []
                )
            ),
            createdAt: Date(),
            updatedAt: Date()
        )
    ) { _ in }
}
