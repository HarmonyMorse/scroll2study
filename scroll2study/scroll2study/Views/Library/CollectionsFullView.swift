import SwiftUI

// Import our custom Collection type and related views
struct CollectionsFullView: View {
    typealias CustomCollection = Collection  // Define an alias to avoid protocol conflict
    let collections: [CustomCollection]
    @ObservedObject var viewModel: LibraryViewModel
    @State private var showingNewCollectionSheet = false

    var body: some View {
        ScrollView {
            if collections.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("No Collections Yet")
                        .font(.headline)
                    Text("Create your first collection to organize your study materials")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Button(action: { showingNewCollectionSheet = true }) {
                        Text("Create Collection")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.top)
                }
                .padding()
                .frame(maxWidth: .infinity)
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.adaptive(minimum: 160), spacing: 16)
                    ], spacing: 16
                ) {
                    ForEach(collections) { collection in
                        NavigationLink(
                            destination: CollectionDetailView(
                                viewModel: viewModel, collection: collection)
                        ) {
                            CollectionCard(collection: collection, viewModel: viewModel)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Collections")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingNewCollectionSheet = true }) {
                    Image(systemName: "folder.badge.plus")
                }
            }
        }
        .sheet(isPresented: $showingNewCollectionSheet) {
            NewCollectionOptionsSheet(viewModel: viewModel)
        }
    }
}
