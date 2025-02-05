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

    func testAnonymousSignIn() async throws {
        // Test anonymous sign in
        let user = try await authManager.signInAnonymously()

        // Wait for auth state to update
        try await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second

        // Verify anonymous user is created in Firebase Auth
        XCTAssertNotNil(user)
        XCTAssertTrue(user.isAnonymous, "User should be anonymous")
        XCTAssertNil(user.email, "Anonymous user should not have an email")

        // Verify user document is created in Firestore
        let userDoc = try await Firestore.firestore()
            .collection("users")
            .document(user.uid)
            .getDocument()

        XCTAssertTrue(userDoc.exists, "Firestore document should exist for anonymous user")

        // Verify authentication state
        XCTAssertTrue(authManager.isAuthenticated, "User should be authenticated")
        XCTAssertNotNil(authManager.user, "User should not be nil")
        XCTAssertTrue(
            authManager.user?.isAnonymous ?? false, "AuthManager should show user as anonymous")
    }

    func testSignOut() async throws {
        // First sign in a user (using anonymous auth for simplicity)
        let user = try await authManager.signInAnonymously()

        // Wait for auth state to update
        try await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second

        // Verify we're signed in
        XCTAssertTrue(authManager.isAuthenticated, "User should be authenticated before sign out")
        XCTAssertNotNil(authManager.user, "User should not be nil before sign out")

        // Store the user ID for later verification
        let userId = user.uid

        // Test sign out
        try authManager.signOut()

        // Wait for auth state to update
        try await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second

        // Verify authentication state after sign out
        XCTAssertFalse(
            authManager.isAuthenticated, "User should not be authenticated after sign out")
        XCTAssertNil(authManager.user, "User should be nil after sign out")

        // Verify we can't access the user's Firestore document (should get permission denied)
        do {
            _ = try await Firestore.firestore()
                .collection("users")
                .document(userId)
                .getDocument()
            XCTFail("Should not be able to access user document after sign out")
        } catch {
            // Expected error - permission denied
            XCTAssertTrue(true, "Successfully denied access to user document after sign out")
        }
    }

    func testAuthStatePersistence() async throws {
        // First sign in a user
        let user = try await authManager.signInAnonymously()
        let userId = user.uid

        // Wait for auth state to update
        try await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second

        // Verify initial state
        XCTAssertTrue(authManager.isAuthenticated, "User should be authenticated initially")
        XCTAssertNotNil(authManager.user, "User should not be nil initially")
        XCTAssertEqual(authManager.user?.uid, userId, "User ID should match")

        // Create a new instance of AuthenticationManager
        let newAuthManager = AuthenticationManager()

        // Wait for auth state to update in new instance
        try await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second

        // Verify state persists in new instance
        XCTAssertTrue(newAuthManager.isAuthenticated, "Auth state should persist in new instance")
        XCTAssertNotNil(newAuthManager.user, "User should not be nil in new instance")
        XCTAssertEqual(newAuthManager.user?.uid, userId, "User ID should persist in new instance")

        // Verify both instances reflect the same state
        XCTAssertEqual(
            authManager.user?.uid,
            newAuthManager.user?.uid,
            "Both instances should have same user"
        )
        XCTAssertEqual(
            authManager.isAuthenticated,
            newAuthManager.isAuthenticated,
            "Both instances should have same auth state"
        )

        // Sign out using new instance
        try newAuthManager.signOut()

        // Wait for auth state to update
        try await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second

        // Verify both instances reflect signed out state
        XCTAssertFalse(authManager.isAuthenticated, "Original instance should reflect sign out")
        XCTAssertFalse(newAuthManager.isAuthenticated, "New instance should reflect sign out")
        XCTAssertNil(authManager.user, "Original instance user should be nil")
        XCTAssertNil(newAuthManager.user, "New instance user should be nil")
    }
}
