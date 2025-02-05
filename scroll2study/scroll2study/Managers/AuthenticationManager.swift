import FirebaseAuth
import FirebaseCore
import SwiftUI

// MARK: - Rate Limiting
enum RateLimitError: LocalizedError {
    case tooManyAttempts(remainingSeconds: Int)

    var errorDescription: String? {
        switch self {
        case .tooManyAttempts(let seconds):
            return "Too many attempts. Please try again in \(seconds) seconds."
        }
    }
}

class AuthenticationManager: ObservableObject {
    @Published var user: FirebaseAuth.User?
    @Published var isAuthenticated = false
    @Published var authenticationState: AuthenticationState = .unauthenticated

    // Rate limiting properties
    private var authAttempts: [(date: Date, email: String)] = []
    private let maxAttempts = 5
    private let timeWindow: TimeInterval = 300  // 5 minutes

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

// MARK: - Rate Limiting Methods
extension AuthenticationManager {
    private func checkRateLimit(for email: String) throws {
        let now = Date()

        // Remove attempts older than the time window
        authAttempts = authAttempts.filter { now.timeIntervalSince($0.date) < timeWindow }

        // Count attempts for this email
        let recentAttempts = authAttempts.filter { $0.email == email }

        if recentAttempts.count >= maxAttempts {
            if let oldestAttempt = recentAttempts.first {
                let remainingSeconds = Int(timeWindow - now.timeIntervalSince(oldestAttempt.date))
                throw RateLimitError.tooManyAttempts(remainingSeconds: remainingSeconds)
            }
        }

        // Record this attempt
        authAttempts.append((date: now, email: email))
    }
}

// MARK: - Authentication Methods
extension AuthenticationManager {
    func signIn(email: String, password: String) async throws -> FirebaseAuth.User {
        // Check rate limit before attempting sign in
        try checkRateLimit(for: email)

        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            // Clear attempts on successful sign in
            authAttempts.removeAll { $0.email == email }
            return result.user
        } catch {
            // Keep the failed attempt recorded
            throw error
        }
    }

    func signUp(email: String, password: String) async throws -> FirebaseAuth.User {
        // Check rate limit before attempting sign up
        try checkRateLimit(for: email)

        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            // Create user document in Firestore
            try await userService.createUserDocument(user: result.user)
            // Clear attempts on successful sign up
            authAttempts.removeAll { $0.email == email }
            return result.user
        } catch {
            // Keep the failed attempt recorded
            throw error
        }
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
