//
//  ContentView.swift
//  scroll2study
//
//  Created by Harm on 2/3/25.
//

import FirebaseAuth
import SwiftUI
import os

private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "scroll2study", category: "ContentView")

class ViewState: ObservableObject {
    @Published var isLoggedIn = false
    @Published var counter = 0
    @Published var errorMessage = ""

    init() {
        logger.info("📊 ViewState initialized")
    }

    func signInAnonymously() async {
        logger.info("🔑 Attempting anonymous sign in")
        do {
            let result = try await Auth.auth().signInAnonymously()
            logger.info("✅ Anonymous sign in successful - UID: \(result.user.uid)")
            await MainActor.run {
                isLoggedIn = true
                errorMessage = ""
            }
        } catch {
            logger.error("❌ Sign in failed: \(error.localizedDescription)")
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }

    func signOut() async {
        logger.info("🚪 Attempting sign out")
        do {
            try await Auth.auth().signOut()
            logger.info("✅ Sign out successful")
            await MainActor.run {
                isLoggedIn = false
                counter = 0
                errorMessage = ""
            }
        } catch {
            logger.error("❌ Sign out failed: \(error.localizedDescription)")
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }

    func incrementCounter() async {
        guard let user = Auth.auth().currentUser else {
            logger.error("❌ Increment counter failed: No authenticated user")
            await MainActor.run {
                errorMessage = "Not logged in"
            }
            return
        }

        logger.info("🔢 Attempting to increment counter for user: \(user.uid)")
        do {
            let token = try await user.getIDToken()
            logger.debug("🎫 Successfully obtained ID token")

            guard let url = URL(string: "http://localhost:3000/incrementCounter") else {
                logger.error("❌ Invalid URL for increment counter")
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            logger.info("📡 Sending increment counter request")
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(CounterResponse.self, from: data)
            logger.info("✅ Counter incremented successfully to: \(response.personalCounter)")

            await MainActor.run {
                counter = response.personalCounter
                errorMessage = ""
            }
        } catch {
            logger.error("❌ Counter increment failed: \(error.localizedDescription)")
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }
}

struct ContentView: View {
    @StateObject private var state = ViewState()

    var body: some View {
        VStack(spacing: 20) {
            if state.isLoggedIn {
                Text("Personal Counter: \(state.counter)")
                    .font(.title)

                Button("Increment Counter") {
                    Task {
                        await state.incrementCounter()
                    }
                }
                .buttonStyle(.borderedProminent)

                Button("Sign Out") {
                    Task {
                        await state.signOut()
                    }
                }
                .buttonStyle(.bordered)
            } else {
                Text("Welcome to Scroll2Study")
                    .font(.title)

                Button("Sign In Anonymously") {
                    Task {
                        await state.signInAnonymously()
                    }
                }
                .buttonStyle(.borderedProminent)
            }

            if !state.errorMessage.isEmpty {
                Text(state.errorMessage)
                    .foregroundColor(.red)
                    .font(.callout)
            }
        }
        .padding()
    }
}

struct CounterResponse: Codable {
    let personalCounter: Int
}

#Preview {
    ContentView()
}
