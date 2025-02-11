import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct NewCollectionSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: LibraryViewModel
    @State private var name = ""
    @State private var description = ""
    @State private var isCreating = false
    @State private var error: Error?

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Collection Name", text: $name)
                    TextField("Description", text: $description)
                }
            }
            .navigationTitle("New Collection")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createCollection()
                    }
                    .disabled(name.isEmpty || isCreating)
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

    private func createCollection() {
        isCreating = true
        Task {
            do {
                try await viewModel.createCollection(name: name, description: description)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                self.error = error
            }
            await MainActor.run {
                isCreating = false
            }
        }
    }
}
