//
//  ContentView.swift
//  scroll2study
//
//  Created by Harm on 2/3/25.
//

import FirebaseAuth
import SwiftUI

struct ContentView: View {
    @State private var isLoggedIn = false
    @State private var counter = 0
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 20) {
            if isLoggedIn {
                Text("Personal Counter: \(counter)")
                    .font(.title)

                Button("Increment Counter") {
                    incrementCounter()
                }
                .buttonStyle(.borderedProminent)

                Button("Sign Out") {
                    signOut()
                }
                .buttonStyle(.bordered)
            } else {
                Text("Welcome to Scroll2Study")
                    .font(.title)

                Button("Sign In Anonymously") {
                    signInAnonymously()
                }
                .buttonStyle(.borderedProminent)
            }

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.callout)
            }
        }
        .padding()
    }

    private func signInAnonymously() {
        Auth.auth().signInAnonymously { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
                return
            }
            isLoggedIn = true
        }
    }

    private func signOut() {
        do {
            try Auth.auth().signOut()
            isLoggedIn = false
            counter = 0
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func incrementCounter() {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "Not logged in"
            return
        }

        user.getIDToken { token, error in
            guard let token = token else {
                errorMessage = error?.localizedDescription ?? "Failed to get token"
                return
            }

            guard let url = URL(string: "http://localhost:3000/incrementCounter") else { return }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    DispatchQueue.main.async {
                        errorMessage = error.localizedDescription
                    }
                    return
                }

                if let data = data,
                    let response = try? JSONDecoder().decode(CounterResponse.self, from: data)
                {
                    DispatchQueue.main.async {
                        counter = response.personalCounter
                    }
                }
            }.resume()
        }
    }
}

struct CounterResponse: Codable {
    let personalCounter: Int
}

#Preview {
    ContentView()
}
