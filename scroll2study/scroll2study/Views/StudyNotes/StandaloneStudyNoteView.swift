import FirebaseAuth
import Foundation
import SwiftUI
import os

private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "scroll2study",
    category: "StandaloneStudyNoteView"
)

// Add a configuration struct to handle API keys
struct Configuration {
    static var openAIKey: String {
        logger.debug("Checking EnvVars.plist")
        if let path = Bundle.main.path(forResource: "EnvVars", ofType: "plist") {
            logger.debug("Found EnvVars.plist at path: \(path)")
            if let dict = NSDictionary(contentsOfFile: path) {
                logger.debug("Loaded EnvVars.plist dictionary")
                if let key = dict["OPENAI_API_KEY"] as? String {
                    logger.debug("Found API key in EnvVars.plist")
                    return key
                } else {
                    logger.error("No OPENAI_API_KEY found in EnvVars.plist")
                }
            } else {
                logger.error("Failed to load EnvVars.plist as dictionary")
            }
        } else {
            logger.error("EnvVars.plist not found in bundle")
            // Print all resources in bundle for debugging
            if let resourcePath = Bundle.main.resourcePath {
                let fileManager = FileManager.default
                if let files = try? fileManager.contentsOfDirectory(atPath: resourcePath) {
                    logger.debug("Bundle contents: \(files.joined(separator: ", "))")
                }
            }
        }

        logger.error("No API key found in EnvVars.plist")
        return ""
    }
}

struct StandaloneStudyNoteView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var noteText: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var isSummarizing: Bool = false

    private let studyNoteService = StudyNoteService.shared
    @Web private var web

    var body: some View {
        NavigationView {
            VStack {
                // Text editor for new notes
                TextEditor(text: $noteText)
                    .frame(height: 200)
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .padding()

                // Action buttons
                HStack {
                    Button(action: saveNote) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Save Note")
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                    }
                    .disabled(noteText.isEmpty || isLoading)

                    Button(action: summarizeAndSave) {
                        if isSummarizing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Summarize & Save")
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.green)
                                .cornerRadius(8)
                        }
                    }
                    .disabled(noteText.isEmpty || isSummarizing)
                }
                .padding()

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding()
                }

                Spacer()
            }
            .navigationTitle("New Study Note")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }

    private func saveNote() {
        guard !noteText.isEmpty, let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        errorMessage = nil

        Task {
            do {
                _ = try await studyNoteService.createStudyNote(
                    userId: userId,
                    videoId: "",  // No video associated
                    originalText: noteText
                )

                await MainActor.run {
                    noteText = ""
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to save note: \(error.localizedDescription)"
                }
            }

            await MainActor.run {
                isLoading = false
            }
        }
    }

    private func summarizeAndSave() {
        guard !noteText.isEmpty, let userId = Auth.auth().currentUser?.uid else { return }
        isSummarizing = true
        errorMessage = nil

        Task {
            do {
                // Use the Configuration struct to get the API key
                let apiKey = Configuration.openAIKey
                if apiKey.isEmpty {
                    throw NSError(
                        domain: "", code: -1,
                        userInfo: [
                            NSLocalizedDescriptionKey:
                                "OpenAI API key not found. Please add it to Config.plist or set OPENAI_API_KEY in environment variables."
                        ])
                }

                let response = try await web.post(
                    "https://api.openai.com/v1/chat/completions",
                    headers: [
                        "Authorization": "Bearer \(apiKey)",
                        "Content-Type": "application/json",
                    ],
                    body: [
                        "model": "gpt-4",
                        "messages": [
                            [
                                "role": "system",
                                "content":
                                    "You are a helpful AI that creates concise summaries of study notes. Keep summaries clear and focused on key points.",
                            ],
                            [
                                "role": "user",
                                "content":
                                    "Please summarize the following study notes in a concise paragraph:\n\n\(noteText)",
                            ],
                        ],
                    ]
                )

                guard let summary = response["choices"]["0"]["message"]["content"].string else {
                    throw NSError(
                        domain: "", code: -1,
                        userInfo: [
                            NSLocalizedDescriptionKey:
                                "Failed to parse summary from OpenAI response"
                        ])
                }

                let note = try await studyNoteService.createStudyNote(
                    userId: userId,
                    videoId: "",  // No video associated
                    originalText: noteText
                )

                try await studyNoteService.updateNoteSummary(
                    userId: userId,
                    noteId: note.id,
                    summary: summary
                )

                await MainActor.run {
                    noteText = ""
                    dismiss()
                }
            } catch let error as WebError {
                await MainActor.run {
                    errorMessage = "OpenAI API Error: \(error.localizedDescription)"
                }
            } catch {
                await MainActor.run {
                    errorMessage =
                        "Failed to summarize and save note: \(error.localizedDescription)"
                }
            }

            await MainActor.run {
                isSummarizing = false
            }
        }
    }
}

#Preview {
    StandaloneStudyNoteView()
}
