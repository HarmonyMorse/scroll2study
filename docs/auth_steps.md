# Authentication Implementation Steps

## Overview
This document outlines the step-by-step process for implementing authentication in our scroll2study app using Firebase Auth and integrating it with our Firestore schema.

## 1. Firebase Auth Setup
- [x] Configure Firebase Auth in Firebase Console
  - [x] Enable Email/Password authentication
  - [x] Enable Anonymous authentication
  - [x] Enable Google Sign-In (optional for MVP)
  - [x] Add iOS app's bundle ID to OAuth 2.0 client IDs

## 2. iOS Project Configuration
- [x] Verify FirebaseAuth SPM dependency is properly imported
- [x] Add required OAuth redirects to Info.plist (not needed for MVP - only Email/Password and Anonymous auth)
- [x] Create AuthenticationManager class:
```swift
class AuthenticationManager: ObservableObject {
    @Published var user: FirebaseAuth.User?
    @Published var isAuthenticated = false
    
    static let shared = AuthenticationManager()
    
    init() {
        self.user = Auth.auth().currentUser
        self.isAuthenticated = user != nil
    }
}
```

## 3. User Authentication Models
- [x] Create User model matching Firestore schema:
```swift
struct User: Codable {
    let id: String            // Firebase Auth UID
    let lastActive: Date
    let role: UserRole
    var preferences: Preferences
    var profile: Profile
    var stats: Stats
    var settings: Settings
    let createdAt: Date
    let updatedAt: Date
    
    enum UserRole: String, Codable {
        case creator
        case consumer
    }
    
    struct Preferences: Codable {
        var selectedSubjects: [String]
        var preferredLevel: Int
        var contentType: [String]
    }
    
    struct Profile: Codable {
        var bio: String
        var avatarUrl: String
        var displayName: String
    }
    
    struct Stats: Codable {
        var totalWatchTime: TimeInterval
        var completedVideos: Int
        var lastLoginAt: Date
    }
    
    struct Settings: Codable {
        var notifications: Bool
        var autoplay: Bool
        var preferredLanguage: String
    }
}
```

## 4. Authentication Views
- [x] Create AuthenticationView (main auth container)
- [x] Create SignInView:
  ```swift
  struct SignInView: View {
      @State private var email = ""
      @State private var password = ""
      @State private var showError = false
      @State private var errorMessage = ""
  }
  ```
- [x] Create SignUpView
- [x] Create AnonymousSignInButton
- [x] Create AuthenticationStateView (handles auth state changes - implemented in AuthenticationView)

## 5. Authentication Methods Implementation
- [x] Implement Email/Password Sign In:
```swift
func signIn(email: String, password: String) async throws -> FirebaseAuth.User {
    let result = try await Auth.auth().signIn(withEmail: email, password: password)
    return result.user
}
```
- [x] Implement Email/Password Sign Up
- [x] Implement Anonymous Sign In
- [x] Implement Sign Out
- [x] Implement Auth State Listener

## 6. Firestore Integration
- [x] Create UserService for Firestore operations:
```swift
class UserService {
    func createUserDocument(user: FirebaseAuth.User, role: User.UserRole = .consumer) async throws {
        let now = Date()
        let userData = User(
            id: user.uid,
            lastActive: now,
            role: role,
            preferences: User.Preferences(
                selectedSubjects: [],
                preferredLevel: 1,
                contentType: []
            ),
            profile: User.Profile(
                bio: "",
                avatarUrl: user.photoURL?.absoluteString ?? "",
                displayName: user.displayName ?? "User"
            ),
            stats: User.Stats(
                totalWatchTime: 0,
                completedVideos: 0,
                lastLoginAt: now
            ),
            settings: User.Settings(
                notifications: true,
                autoplay: true,
                preferredLanguage: "en"
            ),
            createdAt: now,
            updatedAt: now
        )
        
        try await Firestore
            .firestore()
            .collection("users")
            .document(user.uid)
            .setData(from: userData)
    }
}
```
- [x] Implement user document creation on sign up
- [x] Implement user document updates
- [x] Implement user preferences sync

## 7. Auth State Management
- [x] Create AuthenticationState enum:
```swift
enum AuthenticationState {
    case unauthenticated
    case authenticating
    case authenticated
}
```
- [x] Implement auth state changes listener
- [x] Handle user session persistence
- [x] Implement automatic anonymous auth if needed

## 8. Error Handling
- [x] Create AuthenticationError enum (using Firebase's built-in error handling)
- [x] Implement error handling for all auth operations
- [x] Create user-friendly error messages
- [x] Implement error UI components

## 9. Testing
- [x] Test Email/Password Sign Up flow
- [x] Test Email/Password Sign In flow
- [x] Test Anonymous Sign In flow
- [x] Test Sign Out flow
- [x] Test Auth State persistence
- [x] Test Firestore user document creation
- [x] Test error scenarios

## 10. Security & Validation
- [x] Implement email validation
  - [x] RFC 5322 compliant regex pattern
  - [x] Length validation (3-254 characters)
  - [x] Domain presence check
  - [x] Real-time validation feedback
  - [x] Visual error indicators
- [x] Implement password strength requirements
- [x] Verify Firestore security rules for user collection
- [x] Implement rate limiting for auth attempts

## Implementation Order
1. Firebase Auth Setup
2. Basic AuthenticationManager
3. User Models
4. Basic Sign In/Up Views
5. Core Authentication Methods
6. Firestore Integration
7. Error Handling
8. Auth State Management
9. Testing
10. Security Hardening

## Notes
- Firebase Auth handles the authentication state and user credentials
- Firestore stores additional user data and preferences
- Anonymous auth allows immediate app access with later account upgrade
- Auth state changes should trigger appropriate UI updates
- User document in Firestore should be created immediately after successful auth
- Security rules are already configured in Firestore setup 