import SwiftUI

struct GridView: View {
    @StateObject private var gridService = GridService()
    @State private var scrollProxy: ScrollViewProxy? = nil

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if gridService.isLoading {
                    ProgressView()
                } else if let error = gridService.error {
                    VStack {
                        Text("Error loading grid")
                            .font(.headline)
                        Text(error.localizedDescription)
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        ScrollViewReader { horizontalProxy in
                            LazyHStack(spacing: 0) {
                                ForEach(gridService.subjects) { subject in
                                    ScrollView(.vertical, showsIndicators: false) {
                                        ScrollViewReader { verticalProxy in
                                            LazyVStack(spacing: 0) {
                                                ForEach(gridService.complexityLevels) { level in
                                                    GridCell(subject: subject, level: level)
                                                        .id("\(subject.id)_\(level.id)")
                                                        .frame(
                                                            width: geometry.size.width,
                                                            height: geometry.size.height)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .edgesIgnoringSafeArea(.all)
                }
            }
        }
        .task {
            await gridService.fetchGridData()
        }
    }
}

struct GridCell: View {
    let subject: Subject
    let level: ComplexityLevel

    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Text(subject.name)
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Level: \(level.name)")
                .font(.title2)
                .foregroundColor(.secondary)

            Text(level.description)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Text(subject.description)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }
}

#Preview {
    GridView()
}
