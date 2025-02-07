import FirebaseAuth
import FirebaseCore
import SwiftUI

// MARK: - Authentication Errors
enum AuthError: LocalizedError {
    case tooManyAttempts(remainingSeconds: Int)
    case authenticationFailed
    case userDocumentCreationFailed
    case networkError
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .tooManyAttempts(let seconds):
            return "Too many attempts. Please try again in \(seconds) seconds."
        case .authenticationFailed:
            return "Invalid email or password. Please check your credentials and try again."
        case .userDocumentCreationFailed:
            return "Failed to create your user profile. Please try again."
        case .networkError:
            return "Network error. Please check your connection and try again."
        case .unknown(let message):
            return message
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
                guard let self = self else { return }

                Task { @MainActor in
                    if let user = user {
                        // Check if user document exists
                        do {
                            if (try await self.userService.getUser(id: user.uid)) != nil {
                                self.user = user
                                self.isAuthenticated = true
                                self.authenticationState = .authenticated
                            } else {
                                // No user document found, sign out
                                try? Auth.auth().signOut()
                                self.user = nil
                                self.isAuthenticated = false
                                self.authenticationState = .unauthenticated
                                NotificationCenter.default.post(
                                    name: .init("AuthError"),
                                    object: AuthError.authenticationFailed
                                )
                            }
                        } catch {
                            // Error fetching user document, sign out
                            try? Auth.auth().signOut()
                            self.user = nil
                            self.isAuthenticated = false
                            self.authenticationState = .unauthenticated
                            NotificationCenter.default.post(
                                name: .init("AuthError"),
                                object: AuthError.networkError
                            )
                        }
                    } else {
                        self.user = nil
                        self.isAuthenticated = false
                        self.authenticationState = .unauthenticated
                    }
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
                throw AuthError.tooManyAttempts(remainingSeconds: remainingSeconds)
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

            // Check if user document exists, create if it doesn't
            if try await userService.getUser(id: result.user.uid) == nil {
                do {
                    try await userService.createUserDocument(user: result.user)
                } catch {
                    throw AuthError.userDocumentCreationFailed
                }
            }

            return result.user
        } catch let error as AuthError {
            throw error
        } catch let error as NSError {
            switch error.code {
            case AuthErrorCode.wrongPassword.rawValue,
                AuthErrorCode.invalidEmail.rawValue,
                AuthErrorCode.userNotFound.rawValue:
                throw AuthError.authenticationFailed
            case AuthErrorCode.networkError.rawValue:
                throw AuthError.networkError
            default:
                throw AuthError.authenticationFailed
            }
        }
    }

    func signUp(email: String, password: String) async throws -> FirebaseAuth.User {
        // Check rate limit before attempting sign up
        try checkRateLimit(for: email)

        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)

            // Create user document in Firestore
            do {
                try await userService.createUserDocument(user: result.user)
            } catch {
                // If document creation fails, delete the auth user and throw error
                try? await result.user.delete()
                throw AuthError.userDocumentCreationFailed
            }

            // Clear attempts on successful sign up
            authAttempts.removeAll { $0.email == email }
            return result.user
        } catch let error as AuthError {
            throw error
        } catch let error as NSError {
            switch error.code {
            case AuthErrorCode.emailAlreadyInUse.rawValue,
                AuthErrorCode.invalidEmail.rawValue,
                AuthErrorCode.weakPassword.rawValue:
                throw AuthError.authenticationFailed
            case AuthErrorCode.networkError.rawValue:
                throw AuthError.networkError
            default:
                throw AuthError.authenticationFailed
            }
        }
    }

    func signInAnonymously() async throws -> FirebaseAuth.User {
        do {
            let result = try await Auth.auth().signInAnonymously()
            // Create user document in Firestore
            do {
                try await userService.createUserDocument(user: result.user)
            } catch {
                // If document creation fails, delete the auth user and throw error
                try? await result.user.delete()
                throw AuthError.userDocumentCreationFailed
            }
            return result.user
        } catch let error as AuthError {
            throw error
        } catch let error as NSError {
            if error.code == AuthErrorCode.networkError.rawValue {
                throw AuthError.networkError
            }
            throw AuthError.authenticationFailed
        }
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }
}
