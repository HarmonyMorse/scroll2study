import SwiftUI

struct FilterSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedSubject: String?
    let subjects: [String]

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Subject")) {
                    ForEach(subjects, id: \.self) { subject in
                        Button(action: {
                            selectedSubject = subject
                            dismiss()
                        }) {
                            HStack {
                                Text(subject)
                                Spacer()
                                if selectedSubject == subject {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filter Videos")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        selectedSubject = nil
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
