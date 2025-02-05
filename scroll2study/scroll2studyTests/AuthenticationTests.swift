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
        // Wait for auth state to update
        let expectation = XCTestExpectation(description: "Auth state updated in tearDown")
        let startTime = Date()
        while authManager.isAuthenticated && Date().timeIntervalSince(startTime) < 5 {
            Thread.sleep(forTimeInterval: 0.1)
        }
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

        // Wait for auth state to update
        try await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second

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

    func testEmailPasswordSignIn() async throws {
        // First create a test user
        let email = "test\(Int.random(in: 1000...9999))@example.com"
        let password = "TestPassword123!"

        // Sign up the test user
        let signUpUser = try await authManager.signUp(email: email, password: password)
        XCTAssertNotNil(signUpUser)

        // Sign out to prepare for sign in test
        try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<Void, Error>) in
            do {
                try Auth.auth().signOut()
                // Wait for auth state to update
                DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                    continuation.resume()
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }

        // Additional wait to ensure auth state is updated
        try await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second

        // Verify signed out state
        XCTAssertFalse(authManager.isAuthenticated, "User should be signed out")
        XCTAssertNil(authManager.user, "User should be nil after sign out")

        // Test sign in
        let signInUser = try await authManager.signIn(email: email, password: password)

        // Wait for auth state to update
        try await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second

        // Verify user is signed in
        XCTAssertNotNil(signInUser)
        XCTAssertEqual(signInUser.email, email)

        // Verify authentication state
        XCTAssertTrue(authManager.isAuthenticated, "User should be authenticated after sign in")
        XCTAssertNotNil(authManager.user, "User should not be nil after sign in")
        XCTAssertEqual(authManager.user?.email, email)
    }
}
