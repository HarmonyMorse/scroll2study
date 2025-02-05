import FirebaseAuth
import FirebaseCore
import SwiftUI

class AuthenticationManager: ObservableObject {
    @Published var user: FirebaseAuth.User?
    @Published var isAuthenticated = false
    @Published var authenticationState: AuthenticationState = .unauthenticated

    static let shared = AuthenticationManager()
    private let userService = UserService.shared
    private var authStateHandler: AuthStateDidChangeListenerHandle?

    init() {
        self.user = Auth.auth().currentUser
        self.isAuthenticated = user != nil
        setupAuthStateHandler()
    }

    private func setupAuthStateHandler() {
        if authStateHandler == nil {
            authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] _, user in
                DispatchQueue.main.async {
                    self?.user = user
                    self?.isAuthenticated = user != nil
                    self?.authenticationState = user != nil ? .authenticated : .unauthenticated
                }
            }
        }
    }

    deinit {
        if let handler = authStateHandler {
            Auth.auth().removeStateDidChangeListener(handler)
        }
    }
}

// MARK: - Authentication State
extension AuthenticationManager {
    enum AuthenticationState {
        case unauthenticated
        case authenticating
        case authenticated
    }
}

// MARK: - Authentication Methods
extension AuthenticationManager {
    func signIn(email: String, password: String) async throws -> FirebaseAuth.User {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        return result.user
    }

    func signUp(email: String, password: String) async throws -> FirebaseAuth.User {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        // Create user document in Firestore
        try await userService.createUserDocument(user: result.user)
        return result.user
    }

    func signInAnonymously() async throws -> FirebaseAuth.User {
        let result = try await Auth.auth().signInAnonymously()
        // Create user document in Firestore for anonymous users
        try await userService.createUserDocument(user: result.user)
        return result.user
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }
}
