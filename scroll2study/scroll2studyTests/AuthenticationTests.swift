import FirebaseAuth
import FirebaseFirestore
import XCTest

@testable import scroll2study

final class AuthenticationTests: XCTestCase {
    var authManager: AuthenticationManager!
    var userService: UserService!

    override func setUp() {
        super.setUp()
        authManager = AuthenticationManager.shared
        userService = UserService.shared
    }

    override func tearDown() {
        // Sign out after each test
        try? Auth.auth().signOut()
        authManager = nil
        userService = nil
        super.tearDown()
    }

    func testEmailPasswordSignUp() async throws {
        // Test data
        let email = "test\(Int.random(in: 1000...9999))@example.com"
        let password = "TestPassword123!"

        // Attempt sign up
        let user = try await authManager.signUp(email: email, password: password)

        // Verify user is created in Firebase Auth
        XCTAssertNotNil(user)
        XCTAssertEqual(user.email, email)

        // Verify user document is created in Firestore
        let userDoc = try await Firestore.firestore()
            .collection("users")
            .document(user.uid)
            .getDocument()

        XCTAssertTrue(userDoc.exists)

        // Verify authentication state
        XCTAssertTrue(authManager.isAuthenticated)
        XCTAssertNotNil(authManager.user)
    }
}
