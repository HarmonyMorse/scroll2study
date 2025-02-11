import SwiftUI

// Import our custom Collection type and related views
struct CollectionsFullView: View {
    typealias CustomCollection = Collection  // Define an alias to avoid protocol conflict
    let collections: [CustomCollection]
    @ObservedObject var viewModel: LibraryViewModel

    var body: some View {
        ScrollView {
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
        .navigationTitle("Collections")
    }
}
