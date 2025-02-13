import SwiftUI
import OpenAI
import FirebaseAuth
import FirebaseFirestore

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
        print("🚀 Starting createAICollection")
        print("Goal text: \(goalText)")
        
        guard !goalText.isEmpty else {
            print("❌ Goal text is empty, returning early")
            return
        }
        
        print("✅ Goal text validation passed")
        isLoading = true
        print("🔄 Set isLoading to true")
        errorMessage = nil
        print("🧹 Cleared error message")
        isTextFieldFocused = false
        print("⌨️ Unfocused text field")
        
        Task {
            do {
                let apiKey = Configuration.openAIKey
                if apiKey.isEmpty {
                    throw NSError(
                        domain: "", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "OpenAI API key not found in EnvVars.plist"])
                }
                let openAI = OpenAI(apiToken: apiKey)
                
                print("📚 Preparing video context for AI")
                // Create a context of available videos for the AI
                let allVideos = viewModel.gridService.videos
                let videosContext = allVideos.map { video in
                    """
                    {
                        "id": "\(video.id)",
                        "title": "\(video.title)",
                        "description": "\(video.description)",
                        "subject": "\(video.subject)",
                        "complexityLevel": \(video.complexityLevel)
                    }
                    """
                }.joined(separator: ",\n")
                
                print("🤖 Setting up AI system prompt")
                let systemPrompt = """
                    You are an educational content curator. Given a user's learning goal and a list of available educational videos, 
                    select the most relevant videos that would help them achieve their goal. 
                    Return ONLY a raw JSON object without any markdown formatting or code blocks. The response must be exactly in this format:
                    {"name":"Collection name","description":"Collection description","videoIds":["id1","id2"]}
                    Do not include any other text, explanation, or formatting in your response.
                    """
                
                print("🎯 Creating user prompt with goal: \(goalText)")
                let userPrompt = """
                    User goal: \(goalText)

                    Available videos:
                    [\(videosContext)]

                    Create a collection that helps achieve this goal.
                    """
                
                print("📡 Sending request to OpenAI")
                let query = ChatQuery(
                    messages: [
                        .init(role: .system, content: systemPrompt)!,
                        .init(role: .user, content: userPrompt)!
                    ],
                    model: .gpt4_turbo_preview
                )

                let result = try await openAI.chats(query: query)
                print("✅ Received response from OpenAI")

                if let content = result.choices.first?.message.content,
                   let jsonData = content.string?.data(using: .utf8),
                   let collection = try? JSONDecoder().decode(AICollectionResponse.self, from: jsonData)
                {
                    print("📦 Creating collection: \(collection.name)")
                    // Create the collection
                    try await viewModel.createCollection(
                        name: collection.name,
                        description: collection.description
                    )

                    // Get the created collection's ID (it will be the most recent one)
                    if let newCollection = viewModel.collections.first {
                        print("🎥 Adding \(collection.videoIds.count) videos to collection")
                        // Add videos to the collection
                        for videoId in collection.videoIds {
                            try await viewModel.addVideoToCollection(
                                videoId, collectionId: newCollection.id)
                        }
                    }

                    await MainActor.run {
                        isLoading = false
                        print("✋ Set isLoading back to false")
                        print("🚪 Attempting to dismiss view")
                        dismiss()
                        print("🏁 createAICollection completed")
                    }
                } else {
                    throw NSError(
                        domain: "AICollectionGenerator",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to parse AI response"]
                    )
                }
            } catch {
                await MainActor.run {
                    print("❌ Error creating collection: \(error.localizedDescription)")
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

// Helper struct for decoding AI response
private struct AICollectionResponse: Codable {
    let name: String
    let description: String
    let videoIds: [String]
}

#Preview {
    AICollectionView(viewModel: LibraryViewModel())
} 