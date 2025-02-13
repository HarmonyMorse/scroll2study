import SwiftUI

// Use typealias to avoid naming conflict with Swift.Collection
typealias CustomCollection = Collection

// Import our custom Collection type
struct CollectionCard: View {
    let collection: CustomCollection
    let viewModel: LibraryViewModel

    var body: some View {
        NavigationLink(destination: CollectionDetailView(viewModel: viewModel, collection: collection)) {
            VStack(alignment: .leading) {
                ZStack {
                    gradientBackground

                    VStack(spacing: 4) {
                        Image(systemName: "folder.fill")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                        Text(collection.name)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 8)
                }
                .frame(width: 160, height: 90)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                Text("\(viewModel.getVideosForCollection(collection).count) videos")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 160)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var gradientBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
