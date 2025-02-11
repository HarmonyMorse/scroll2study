import SwiftUI

struct VideoThumbnailView: View {
    let title: String
    let duration: TimeInterval
    let onPlayTapped: () -> Void
    @State private var isLoading = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Animated gradient background
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]
                    ),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Centered content
                VStack(spacing: 24) {
                    // Video metadata
                    VStack(spacing: 4) {
                        Text(title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                        Text(formatDuration(duration))
                            .font(.title3)
                            .foregroundColor(.white)
                            .monospacedDigit()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(12)

                    // Play button
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
                .offset(y: -20)  // Shift up slightly from center
            }
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    VideoThumbnailView(
        title: "Understanding SwiftUI Basics",
        duration: 325,  // 5:25
        onPlayTapped: {}
    )
    .frame(width: 300, height: 200)
}
