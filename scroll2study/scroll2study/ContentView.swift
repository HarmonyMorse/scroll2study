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

enum APIError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case serverError(String)
}

class APIService {
    private let baseURL = "http://localhost:3000"
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "scroll2study",
        category: "APIService"
    )

    func incrementCounter(token: String) async throws -> Int {
        guard let url = URL(string: "\(baseURL)/incrementCounter") else {
            logger.error("❌ Invalid URL for increment counter")
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            logger.info("📡 Sending increment counter request")
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.networkError(NSError(domain: "", code: -1))
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIError.serverError("Server returned status code \(httpResponse.statusCode)")
            }

            let counterResponse = try JSONDecoder().decode(CounterResponse.self, from: data)
            logger.info("✅ Counter incremented successfully to: \(counterResponse.personalCounter)")
            return counterResponse.personalCounter
        } catch let error as APIError {
            throw error
        } catch {
            logger.error("❌ API request failed: \(error.localizedDescription)")
            throw APIError.networkError(error)
        }
    }
}

struct CounterResponse: Codable {
    let personalCounter: Int
}

struct ContentView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var selectedTab = 0

    var body: some View {
        Group {
            if authManager.isAuthenticated {
                ZStack(alignment: .bottom) {
                    TabView(selection: $selectedTab) {
                        NavigationView {
                            GridView()
                        }
                        .tabItem {
                            Label("Explore", systemImage: "square.grid.2x2")
                        }
                        .tag(0)

                        NavigationView {
                            VStack {
                                Text("Coming Soon")
                                    .font(.title)
                                    .foregroundColor(.secondary)
                            }
                            .navigationTitle("My Progress")
                        }
                        .tabItem {
                            Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                        }
                        .tag(1)
                    }
                    .onAppear {
                        // Set tab bar background to solid white
                        let tabBarAppearance = UITabBarAppearance()
                        tabBarAppearance.configureWithOpaqueBackground()
                        tabBarAppearance.backgroundColor = .systemBackground
                        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
                        UITabBar.appearance().standardAppearance = tabBarAppearance
                    }
                }
            } else {
                AuthenticationView()
            }
        }
    }
}

#Preview {
    ContentView()
}
