import SwiftUI

struct AICollectionView: View {
    @ObservedObject var viewModel: LibraryViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var goalText = ""
    @State private var errorMessage: String?
    @FocusState private var isTextFieldFocused: Bool
    
    private let exampleGoals = [
        "I want to be an astronaut",
        "I want to learn about quantum physics",
        "Help me become a data scientist",
        "I'm interested in neuroscience",
        "I want to understand climate change"
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 40))
                            .foregroundColor(.purple)
                        
                        Text("What's Your Goal?")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Tell me what you want to learn, and I'll create a personalized collection of videos to help you get there")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top)
                    
                    // Goal Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your learning goal")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        TextField("e.g. I want to be an astronaut", text: $goalText, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3)
                            .focused($isTextFieldFocused)
                        
                        if goalText.isEmpty {
                            Text("Try these examples:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                            
                            ForEach(exampleGoals, id: \.self) { goal in
                                Button(action: { goalText = goal }) {
                                    Text(goal)
                                        .font(.subheadline)
                                        .foregroundColor(.purple)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(Color.purple.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5)
                    .padding(.horizontal)
                    
                    // Create Button
                    Button(action: createAICollection) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .tint(.white)
                            } else {
                                Text("Create Learning Path")
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(goalText.isEmpty ? Color.gray : Color.purple)
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                    .disabled(goalText.isEmpty || isLoading)
                    
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.subheadline)
                            .padding()
                    }
                }
            }
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
        }
    }
    
    private func createAICollection() {
        guard !goalText.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        isTextFieldFocused = false
        
        // Here we would integrate with your AI service to create the collection
        // For now, we'll simulate the creation with a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            // TODO: Implement actual AI collection creation based on the goal
            isLoading = false
            dismiss()
        }
    }
}

#Preview {
    AICollectionView(viewModel: LibraryViewModel())
} 