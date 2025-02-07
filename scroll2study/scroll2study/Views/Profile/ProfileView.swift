import FirebaseAuth
import FirebaseFirestore
import Foundation
import SwiftUI

struct ProfileView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var user: User?
    @State private var isEditingProfile = false
    @State private var showingSignOutAlert = false
    @State private var errorMessage: String?
    @State private var showError = false

    private let userService = UserService.shared

    var body: some View {
        List {
            if let user = user {
                Section {
                    HStack {
                        if let url = URL(string: user.profile.avatarUrl),
                            !user.profile.avatarUrl.isEmpty
                        {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                            }
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.gray)
                        }

                        VStack(alignment: .leading) {
                            Text(user.profile.displayName)
                                .font(.headline)
                            if !user.profile.bio.isEmpty {
                                Text(user.profile.bio)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Learning Preferences") {
                    HStack {
                        Image(systemName: "graduationcap")
                        Text("Preferred Level")
                        Spacer()
                        Text(levelDescription(for: user.preferences.preferredLevel))
                            .foregroundColor(.secondary)
                    }
                }

                Section("Statistics") {
                    HStack {
                        Image(systemName: "clock")
                        Text("Total Watch Time")
                        Spacer()
                        Text(formatDuration(user.stats.totalWatchTime))
                    }

                    HStack {
                        Image(systemName: "checkmark.circle")
                        Text("Completed Videos")
                        Spacer()
                        Text("\(user.stats.completedVideos)")
                    }
                }

                Section("Settings") {
                    Toggle(isOn: .constant(user.settings.notifications)) {
                        HStack {
                            Image(systemName: "bell")
                            Text("Notifications")
                        }
                    }

                    Toggle(isOn: .constant(user.settings.autoplay)) {
                        HStack {
                            Image(systemName: "play.circle")
                            Text("Autoplay")
                        }
                    }

                    HStack {
                        Image(systemName: "globe")
                        Text("Language")
                        Spacer()
                        Text(user.settings.preferredLanguage.uppercased())
                    }
                }

                Section {
                    Button(role: .destructive, action: { showingSignOutAlert = true }) {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                            Spacer()
                        }
                    }
                }
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Profile")
        .toolbar {
            if user != nil {
                Button("Edit") {
                    isEditingProfile = true
                }
            }
        }
        .refreshable {
            await loadUserData()
        }
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
        .sheet(isPresented: $isEditingProfile) {
            if let user = user {
                EditProfileView(user: user) { updatedUser in
                    self.user = updatedUser
                }
            }
        }
        .task {
            await loadUserData()
        }
    }

    private func loadUserData() async {
        guard let currentUser = Auth.auth().currentUser else { return }

        do {
            if let userData = try await userService.getUser(id: currentUser.uid) {
                user = userData
            }
        } catch {
            errorMessage = "Failed to load user data: \(error.localizedDescription)"
            showError = true
        }
    }

    private func signOut() {
        do {
            try authManager.signOut()
        } catch {
            errorMessage = "Failed to sign out: \(error.localizedDescription)"
            showError = true
        }
    }

    private func formatDuration(_ timeInterval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: timeInterval) ?? "0m"
    }

    private func levelDescription(for level: Int) -> String {
        switch level {
        case 1:
            return "Beginner"
        case 2:
            return "Elementary"
        case 3:
            return "Intermediate"
        case 4:
            return "Advanced"
        case 5:
            return "Expert"
        default:
            return "Level \(level)"
        }
    }
}

#Preview {
    ProfileView()
}
