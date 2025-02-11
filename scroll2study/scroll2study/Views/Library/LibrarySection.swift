import SwiftUI

struct LibrarySection<Content: View>: View {
    let title: String
    let icon: String
    let count: Int
    let content: Content
    let onHeaderTap: () -> Void

    init(
        title: String,
        icon: String,
        count: Int,
        onHeaderTap: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.count = count
        self.content = content()
        self.onHeaderTap = onHeaderTap
    }

    var body: some View {
        VStack(alignment: .leading) {
            Button(action: onHeaderTap) {
                HStack {
                    Label(title, systemImage: icon)
                        .font(.headline)
                    Spacer()
                    Text("\(count)")
                        .foregroundColor(.gray)
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .buttonStyle(PlainButtonStyle())

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    content
                }
                .padding(.horizontal)
            }
        }
    }
}
