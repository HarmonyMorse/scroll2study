import FirebaseFirestore
import Foundation

class StudyNoteService {
    static let shared = StudyNoteService()
    private let db = Firestore.firestore()

    private init() {}

    // Create a new study note
    func createStudyNote(userId: String, videoId: String, originalText: String) async throws
        -> StudyNote
    {
        let note = StudyNote(
            userId: userId,
            videoId: videoId,
            originalText: originalText
        )

        try await db.collection("users")
            .document(userId)
            .collection("studyNotes")
            .document(note.id)
            .setData(note.dictionary)

        return note
    }

    // Get a specific study note
    func getStudyNote(id: String, userId: String) async throws -> StudyNote? {
        let snapshot = try await db.collection("users")
            .document(userId)
            .collection("studyNotes")
            .document(id)
            .getDocument()

        return StudyNote(document: snapshot)
    }

    // Get all study notes for a user
    func getUserStudyNotes(userId: String) async throws -> [StudyNote] {
        let snapshot = try await db.collection("users")
            .document(userId)
            .collection("studyNotes")
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { StudyNote(document: $0) }
    }

    // Get all notes for a specific video
    func getVideoStudyNotes(userId: String, videoId: String) async throws -> [StudyNote] {
        let snapshot = try await db.collection("users")
            .document(userId)
            .collection("studyNotes")
            .whereField("videoId", isEqualTo: videoId)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { StudyNote(document: $0) }
    }

    // Update the summary of a study note
    func updateNoteSummary(userId: String, noteId: String, summary: String) async throws {
        try await db.collection("users")
            .document(userId)
            .collection("studyNotes")
            .document(noteId)
            .updateData([
                "summary": summary,
                "updatedAt": Timestamp(date: Date()),
            ])
    }

    // Update a study note's content
    func updateNote(userId: String, noteId: String, newText: String) async throws {
        try await db.collection("users")
            .document(userId)
            .collection("studyNotes")
            .document(noteId)
            .updateData([
                "originalText": newText,
                "updatedAt": Timestamp(date: Date()),
            ])
    }

    // Delete a study note
    func deleteStudyNote(userId: String, id: String) async throws {
        try await db.collection("users")
            .document(userId)
            .collection("studyNotes")
            .document(id)
            .delete()
    }
}
