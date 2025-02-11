import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct AddToCollectionSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: LibraryViewModel
    let videoId: String
    @State private var isAdding = false
    @State private var error: Error?
    @State private var showingNewCollectionSheet = false

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.collections) { collection in
                    Button(action: { addToCollection(collection.id) }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(collection.name)
                                    .font(.headline)
                                Text("\(collection.videoIds.count) videos")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if collection.videoIds.contains(videoId) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .disabled(isAdding || collection.videoIds.contains(videoId))
                }

                Button(action: { showingNewCollectionSheet = true }) {
                    Label("Create New Collection", systemImage: "folder.badge.plus")
                }
            }
            .navigationTitle("Add to Collection")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingNewCollectionSheet) {
                NewCollectionSheet(viewModel: viewModel)
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

    private func addToCollection(_ collectionId: String) {
        isAdding = true
        Task {
            do {
                try await viewModel.addVideoToCollection(videoId, collectionId: collectionId)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                self.error = error
            }
            await MainActor.run {
                isAdding = false
            }
        }
    }
}
