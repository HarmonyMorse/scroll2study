import SwiftUI

struct VideoThumbnailView: View {
    let thumbnailUrl: String
    let onPlayTapped: () -> Void
    @State private var isLoading = false
    @State private var loadError: Error?

    private var decodedUrl: URL? {
        print("DEBUG: Original thumbnail URL: \(thumbnailUrl)")

        // First try: Direct URL creation
        if let url = URL(string: thumbnailUrl) {
            print("DEBUG: Direct URL creation successful: \(url.absoluteString)")
            return url
        }

        // Second try: Replace %2F with forward slash
        let decodedPath = thumbnailUrl.replacingOccurrences(of: "%2F", with: "/")
        if let url = URL(string: decodedPath) {
            print("DEBUG: URL creation after slash replacement successful: \(url.absoluteString)")
            return url
        }

        // Third try: Full percent decoding
        if let decodedString = thumbnailUrl.removingPercentEncoding,
            let url = URL(string: decodedString)
        {
            print("DEBUG: URL creation after full decoding successful: \(url.absoluteString)")
            return url
        }

        // If all attempts fail, encode the entire string
        let encodedString = thumbnailUrl.addingPercentEncoding(
            withAllowedCharacters: .urlQueryAllowed)
        if let encodedString = encodedString,
            let url = URL(string: encodedString)
        {
            print("DEBUG: URL creation after encoding successful: \(url.absoluteString)")
            return url
        }

        print("DEBUG: All URL creation attempts failed")
        return nil
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .center) {
                // Background color
                Color.black

                // Thumbnail image
                if let url = decodedUrl {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            placeholderView
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .clipped()
                        case .failure(let error):
                            errorView(error: error, url: url)
                        @unknown default:
                            placeholderView
                        }
                    }
                } else {
                    invalidUrlView
                }

                // Semi-transparent overlay for better button visibility
                Color.black.opacity(0.3)

                // Play button overlay
                Button(action: onPlayTapped) {
                    ZStack {
                        Circle()
                            .fill(Color.black.opacity(0.6))
                            .frame(width: 80, height: 80)

                        Circle()
                            .fill(Color.white)
                            .frame(width: 76, height: 76)

                        Image(systemName: "play.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.black)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .onAppear {
            print("DEBUG: VideoThumbnailView appeared")
            print("DEBUG: Thumbnail URL: \(thumbnailUrl)")
        }
    }

    private var placeholderView: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .overlay(
                ProgressView()
                    .scaleEffect(1.5)
            )
    }

    private func errorView(error: Error, url: URL) -> some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .overlay(
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                    Text("Failed to load image")
                        .font(.caption)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
            )
            .onAppear {
                print("DEBUG: Thumbnail loading failed")
                print("DEBUG: URL: \(url)")
                print("DEBUG: Error: \(error.localizedDescription)")
            }
    }

    private var invalidUrlView: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .overlay(
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                    Text("Invalid URL")
                        .foregroundColor(.white)
                }
            )
    }
}

#Preview {
    VideoThumbnailView(
        thumbnailUrl:
            "https://storage.googleapis.com/scroll2study.firebasestorage.app/pics/test.jpg",
        onPlayTapped: {}
    )
    .frame(width: 300, height: 200)
}
