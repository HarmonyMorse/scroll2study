import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading achievements...")
                .foregroundColor(.secondary)
                .padding(.top)
        }
    }
}

struct MainAchievementsContent: View {
    @ObservedObject var viewModel: AchievementsViewModel
    @Binding var selectedCategory: AchievementCategory
    let filteredAchievements: [Achievement]
    let completedCount: Int
    let totalCount: Int
    let percentage: Int
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Category Selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(AchievementCategory.allCases, id: \.self) { category in
                            Button(action: {
                                withAnimation {
                                    selectedCategory = category
                                }
                            }) {
                                CategoryButton(
                                    category: category,
                                    isSelected: selectedCategory == category
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                // Stats Overview
                StatsOverview(
                    completedCount: completedCount,
                    totalCount: totalCount,
                    percentage: percentage
                )
                
                if filteredAchievements.isEmpty {
                    EmptyStateView()
                } else {
                    AchievementsList(achievements: filteredAchievements)
                }
            }
            .padding(.vertical)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .refreshable {
            viewModel.setupUserListener()
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            Text("No achievements in this category yet")
                .font(.headline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct AchievementsList: View {
    let achievements: [Achievement]
    
    var body: some View {
        LazyVStack(spacing: 16) {
            ForEach(achievements) { achievement in
                AchievementCard(achievement: achievement)
            }
        }
        .padding(.horizontal)
    }
}

struct AchievementsView: View {
    @StateObject private var viewModel = AchievementsViewModel()
    @State private var selectedCategory: AchievementCategory = .videos
    @State private var showError = false
    
    private var filteredAchievements: [Achievement] {
        viewModel.achievements.filter { $0.category == selectedCategory }
    }
    
    private var totalAchievements: Int {
        viewModel.achievements.count
    }
    
    private var completedAchievements: Int {
        viewModel.achievements.filter { $0.progress >= 1.0 }.count
    }
    
    private var completionPercentage: Int {
        guard totalAchievements > 0 else { return 0 }
        return Int((Double(completedAchievements) / Double(totalAchievements)) * 100)
    }
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView()
            } else {
                MainAchievementsContent(
                    viewModel: viewModel,
                    selectedCategory: $selectedCategory,
                    filteredAchievements: filteredAchievements,
                    completedCount: completedAchievements,
                    totalCount: totalAchievements,
                    percentage: completionPercentage
                )
            }
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK", role: .cancel) {
                viewModel.error = nil
            }
            Button("Retry", role: .none) {
                viewModel.setupUserListener()
            }
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
    }
}

#Preview {
    AchievementsView()
} 