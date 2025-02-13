import FirebaseAuth
import FirebaseFirestore
import OpenAI
import SwiftUI

struct AICollectionGeneratorView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: LibraryViewModel
    @State private var prompt = ""
    @State private var isGenerating = false
    @State private var error: Error?

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("What kind of collection would you like to create?")) {
                    TextField("E.g., I want to become an astronaut", text: $prompt)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }

                Section(
                    footer: Text(
                        "The AI will analyze your prompt and create a collection of relevant educational videos."
                    )
                ) {
                    Button(action: generateCollection) {
                        if isGenerating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Generate Collection")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(prompt.isEmpty || isGenerating)
                }
            }
            .navigationTitle("AI Collection Generator")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: .constant(error != nil)) {
                Button("OK", role: .cancel) {
                    error = nil
                }
            } message: {
                if let error = error {
                    Text(error.localizedDescription)
                }
            }
        }
    }

    private func generateCollection() {
        isGenerating = true

        Task {
            do {
                let apiKey = Configuration.openAIKey
                if apiKey.isEmpty {
                    throw NSError(
                        domain: "", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "OpenAI API key not found in EnvVars.plist"])
                }
                let openAI = OpenAI(apiToken: apiKey)

                // Get all available videos from the grid service
                let allVideos = viewModel.gridService.videos

                // Create a prompt for GPT to analyze the videos and create a collection
                let systemPrompt = """
                    You are an educational content curator. Given a user's learning goal and a list of available educational videos, 
                    select the most relevant videos that would help them achieve their goal. 
                    Return ONLY a raw JSON object without any markdown formatting or code blocks. The response must be exactly in this format:
                    {"name":"Collection name","description":"Collection description","videoIds":["id1","id2"]}
                    Do not include any other text, explanation, or formatting in your response.
                    """

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

                let userPrompt = """
                    User goal: \(prompt)

                    Available videos:
                    [\(videosContext)]

                    Create a collection that helps achieve this goal.
                    """

                let query = ChatQuery(
                    messages: [
                        .init(role: .system, content: systemPrompt)!,
                        .init(role: .user, content: userPrompt)!
                    ],
                    model: .gpt4_turbo_preview
                )

                let result = try await openAI.chats(query: query)

                if let content = result.choices.first?.message.content,
                   let jsonData = content.string?.data(using: .utf8),
                   let collection = try? JSONDecoder().decode(AICollectionResponse.self, from: jsonData)
                {
                    // Create the collection
                    try await viewModel.createCollection(
                        name: collection.name,
                        description: collection.description
                    )

                    // Get the created collection's ID (it will be the most recent one)
                    if let newCollection = viewModel.collections.first {
                        // Add videos to the collection
                        for videoId in collection.videoIds {
                            try await viewModel.addVideoToCollection(
                                videoId, collectionId: newCollection.id)
                        }
                    }

                    await MainActor.run {
                        dismiss()
                    }
                } else {
                    throw NSError(
                        domain: "AICollectionGenerator", code: -1,
                        userInfo: [
                            NSLocalizedDescriptionKey: "Failed to parse AI response"
                        ])
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isGenerating = false
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
    AICollectionGeneratorView(viewModel: LibraryViewModel())
}
