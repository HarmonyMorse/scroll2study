//
//  ContentView.swift
//  scroll2study
//
//  Created by Harm on 2/3/25.
//

import FirebaseAuth
import SwiftUI
import os

class VideoSelectionState: ObservableObject {
    @Published var selectedVideo: Video?
    @Published var shouldNavigateToVideo = false
}

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

struct SplashScreenView: View {
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            Image("pexels-glasses")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                .clipped()
                .edgesIgnoringSafeArea(.all)
                .overlay(
                    Color.black.opacity(0.3)
                        .edgesIgnoringSafeArea(.all)
                )
            VStack {
                Text("Scroll2Study")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(radius: 10)
                Text("Learn at your own pace")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                    .shadow(radius: 5)
            }
        }
    }
}

struct ContentView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var videoSelection = VideoSelectionState()
    @State private var selectedTab = 0
    @State private var isShowingSplash = true
    @State private var showingProgressMenu = false
    @State private var selectedProgressView: ProgressViewType = .grid

    private func handleTabSelection(_ tab: Int) {
        if tab == 1 {  // Progress tab
            showingProgressMenu = true
        } else {
            selectedTab = tab
        }
    }

    var body: some View {
        Group {
            if isShowingSplash {
                SplashScreenView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation(.easeOut(duration: 0.5)) {
                                isShowingSplash = false
                            }
                        }
                    }
            } else if authManager.isAuthenticated {
                ZStack(alignment: .bottom) {
                    TabView(
                        selection: Binding(
                            get: { selectedTab },
                            set: { handleTabSelection($0) }
                        )
                    ) {
                        NavigationView {
                            GridView()
                        }
                        .tabItem {
                            Label("Explore", systemImage: "square.grid.2x2")
                        }
                        .tag(0)

                        NavigationView {
                            VideoProgressView(selectedView: $selectedProgressView)
                        }
                        .tabItem {
                            Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                        }
                        .tag(1)

                        NavigationView {
                            LibraryView()
                        }
                        .tabItem {
                            Label("Library", systemImage: "books.vertical")
                        }
                        .tag(2)

                        NavigationView {
                            ProfileView()
                        }
                        .tabItem {
                            Label("Profile", systemImage: "person.circle")
                        }
                        .tag(3)
                    }
                    .onChange(of: videoSelection.shouldNavigateToVideo) { shouldNavigate in
                        if shouldNavigate {
                            selectedTab = 0  // Switch to Explore tab
                            videoSelection.shouldNavigateToVideo = false
                        }
                    }
                    .environmentObject(videoSelection)
                    .onAppear {
                        // Set tab bar background to solid white
                        let tabBarAppearance = UITabBarAppearance()
                        tabBarAppearance.configureWithOpaqueBackground()
                        tabBarAppearance.backgroundColor = .systemBackground
                        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
                        UITabBar.appearance().standardAppearance = tabBarAppearance
                    }
                }
                .sheet(isPresented: $showingProgressMenu) {
                    ProgressMenuView(
                        isPresented: $showingProgressMenu,
                        selectedView: $selectedProgressView
                    )
                    .presentationDetents([.height(350)])
                    .onDisappear {
                        selectedTab = 1  // Switch to Progress tab after selection
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
