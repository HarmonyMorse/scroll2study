import SwiftUI

struct GridView: View {
    @StateObject private var gridService = GridService()

    var body: some View {
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
                    HStack(alignment: .top, spacing: 20) {
                        ForEach(gridService.subjects) { subject in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(subject.name)
                                    .font(.headline)
                                    .padding(.bottom, 5)

                                ScrollView(.vertical, showsIndicators: true) {
                                    VStack(spacing: 15) {
                                        ForEach(gridService.complexityLevels) { level in
                                            GridCell(subject: subject, level: level)
                                        }
                                    }
                                }
                            }
                            .frame(width: 250)
                            .padding()
                            .background(.background)
                            .cornerRadius(10)
                            .shadow(radius: 2)
                        }
                    }
                    .padding()
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
        VStack(alignment: .leading, spacing: 8) {
            Text("\(subject.name) - \(level.name)")
                .font(.subheadline)
                .fontWeight(.medium)

            Text(level.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.secondary.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    GridView()
}
