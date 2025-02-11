import SwiftUI

struct CollectionCard: View {
    let collection: Collection
    let viewModel: LibraryViewModel

    var body: some View {
        VStack(alignment: .leading) {
            if !collection.thumbnailUrl.isEmpty {
                AsyncImage(url: URL(string: collection.thumbnailUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay(
                            Image(systemName: "folder.fill")
                                .foregroundColor(.gray)
                                .font(.largeTitle)
                        )
                }
                .frame(width: 160, height: 90)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 160, height: 90)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        Image(systemName: "folder.fill")
                            .foregroundColor(.gray)
                            .font(.largeTitle)
                    )
            }

            Text(collection.name)
                .font(.caption)
                .lineLimit(2)
                .foregroundColor(.primary)

            Text("\(viewModel.getVideosForCollection(collection).count) videos")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(width: 160)
    }
}
