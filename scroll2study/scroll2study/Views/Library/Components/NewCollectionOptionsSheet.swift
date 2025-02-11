import SwiftUI

struct NewCollectionOptionsSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: LibraryViewModel
    @State private var showingManualSheet = false
    @State private var showingAISheet = false

    var body: some View {
        NavigationView {
            List {
                Button(action: { showingManualSheet = true }) {
                    HStack {
                        Image(systemName: "folder.badge.plus")
                            .foregroundColor(.blue)
                            .font(.title2)
                        VStack(alignment: .leading) {
                            Text("Create Manually")
                                .font(.headline)
                            Text("Create a collection and add videos yourself")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Button(action: { showingAISheet = true }) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.purple)
                            .font(.title2)
                        VStack(alignment: .leading) {
                            Text("AI Collection Generator")
                                .font(.headline)
                            Text("Let AI create a collection based on your learning goals")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("New Collection")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingManualSheet) {
                NewCollectionSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showingAISheet) {
                AICollectionGeneratorView(viewModel: viewModel)
            }
        }
    }
}

#Preview {
    NewCollectionOptionsSheet(viewModel: LibraryViewModel())
}
