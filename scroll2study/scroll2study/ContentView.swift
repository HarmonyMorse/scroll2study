//
//  ContentView.swift
//  scroll2study
//
//  Created by Harm on 2/3/25.
//

import FirebaseAuth
import SwiftUI

class ViewState: ObservableObject {
    @Published var isLoggedIn = false
    @Published var counter = 0
    @Published var errorMessage = ""

    func signInAnonymously() async {
        do {
            let result = try await Auth.auth().signInAnonymously()
            await MainActor.run {
                isLoggedIn = true
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }

    func signOut() async {
        do {
            try await Auth.auth().signOut()
            await MainActor.run {
                isLoggedIn = false
                counter = 0
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }

    func incrementCounter() async {
        guard let user = Auth.auth().currentUser else {
            await MainActor.run {
                errorMessage = "Not logged in"
            }
            return
        }

        do {
            let token = try await user.getIDToken()

            guard let url = URL(string: "http://localhost:3000/incrementCounter") else { return }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(CounterResponse.self, from: data)
            await MainActor.run {
                counter = response.personalCounter
            }
        } catch {
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
