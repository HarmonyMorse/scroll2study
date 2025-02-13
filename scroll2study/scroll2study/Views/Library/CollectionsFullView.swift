import SwiftUI

// Import our custom Collection type and related views
struct CollectionsFullView: View {
    let collections: [Collection]
    let viewModel: LibraryViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingNewCollectionSheet = false
    @State private var showingAICollectionSheet = false

    var body: some View {
        VStack {
            if collections.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No collections yet")
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    Text("Create collections to organize your videos by topic or subject")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        Button(action: { showingNewCollectionSheet = true }) {
                            Label("Create Collection", systemImage: "folder.badge.plus")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: 280)
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        
                        Button(action: { showingAICollectionSheet = true }) {
                            Label("Smart Collection with AI", systemImage: "sparkles")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: 280)
                                .background(Color.purple)
                                .cornerRadius(10)
                        }
                    }
                }
                .padding()
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(
                        columns: [
                            GridItem(.adaptive(minimum: 160), spacing: 16)
                        ], spacing: 16
                    ) {
                        ForEach(collections) { collection in
                            CollectionCard(collection: collection, viewModel: viewModel)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Collections")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingNewCollectionSheet = true }) {
                        Label("New Collection", systemImage: "folder.badge.plus")
                    }
                    Button(action: { showingAICollectionSheet = true }) {
                        Label("Smart Collection", systemImage: "sparkles")
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewCollectionSheet) {
            NewCollectionSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showingAICollectionSheet) {
            AICollectionView(viewModel: viewModel)
        }
    }
}
