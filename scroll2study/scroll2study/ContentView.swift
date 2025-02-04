//
//  ContentView.swift
//  scroll2study
//
//  Created by Harm on 2/3/25.
//

import FirebaseAuth
import SwiftUI
import os

private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "scroll2study", category: "ContentView")

class ViewState: ObservableObject {
    @Published var isLoggedIn = false
    @Published var counter = 0
    @Published var errorMessage = ""
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var isLoading = false
    @Published var isSignUp = false

    init() {
        logger.info("📊 ViewState initialized")
    }

    func signInAnonymously() async {
        logger.info("🔑 Attempting anonymous sign in")
        do {
            let result = try await Auth.auth().signInAnonymously()
            logger.info("✅ Anonymous sign in successful - UID: \(result.user.uid)")
            await MainActor.run {
                isLoggedIn = true
                errorMessage = ""
            }
        } catch {
            logger.error("❌ Sign in failed: \(error.localizedDescription)")
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }

    func signOut() async {
        logger.info("🚪 Attempting sign out")
        do {
            try await Auth.auth().signOut()
            logger.info("✅ Sign out successful")
            await MainActor.run {
                isLoggedIn = false
                counter = 0
                errorMessage = ""
            }
        } catch {
            logger.error("❌ Sign out failed: \(error.localizedDescription)")
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }

    func incrementCounter() async {
        guard let user = Auth.auth().currentUser else {
            logger.error("❌ Increment counter failed: No authenticated user")
            await MainActor.run {
                errorMessage = "Not logged in"
            }
            return
        }

        logger.info("🔢 Attempting to increment counter for user: \(user.uid)")
        do {
            let token = try await user.getIDToken()
            logger.debug("🎫 Successfully obtained ID token")

            guard let url = URL(string: "http://localhost:3000/incrementCounter") else {
                logger.error("❌ Invalid URL for increment counter")
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            logger.info("📡 Sending increment counter request")
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(CounterResponse.self, from: data)
            logger.info("✅ Counter incremented successfully to: \(response.personalCounter)")

            await MainActor.run {
                counter = response.personalCounter
                errorMessage = ""
            }
        } catch {
            logger.error("❌ Counter increment failed: \(error.localizedDescription)")
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }

    func signInWithEmail() async {
        logger.info("🔑 Attempting email sign in")
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            logger.info("✅ Email sign in successful - UID: \(result.user.uid)")
            await MainActor.run {
                isLoggedIn = true
                errorMessage = ""
                // Clear sensitive data
                email = ""
                password = ""
            }
        } catch {
            logger.error("❌ Email sign in failed: \(error.localizedDescription)")
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }

    func signUp() async {
        logger.info("🔑 Attempting to create new account")
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            logger.info("✅ Account creation successful - UID: \(result.user.uid)")
            await MainActor.run {
                isLoggedIn = true
                errorMessage = ""
                // Clear sensitive data
                email = ""
                password = ""
                confirmPassword = ""
            }
        } catch {
            logger.error("❌ Account creation failed: \(error.localizedDescription)")
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }

    func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
        errorMessage = ""
    }
}

struct AuthHeaderView: View {
    @ObservedObject var state: ViewState

    var body: some View {
        VStack(spacing: 10) {
            Text("Welcome to Scroll2Study")
                .font(.largeTitle)
                .fontWeight(.bold)

            Picker("", selection: $state.isSignUp) {
                Text("Sign In").tag(false)
                Text("Sign Up").tag(true)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
        }
    }
}

struct SignUpView: View {
    @ObservedObject var state: ViewState

    var body: some View {
        VStack(spacing: 15) {
            TextField("Email", text: $state.email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.emailAddress)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)

            SecureField("Password", text: $state.password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.newPassword)

            SecureField("Confirm Password", text: $state.confirmPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.newPassword)

            Button(action: {
                Task {
                    await state.signUp()
                }
            }) {
                if state.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Text("Create Account")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(
                state.email.isEmpty || state.password.isEmpty || state.confirmPassword.isEmpty
                    || state.isLoading)

            Divider()
                .padding(.vertical)

            Button("Continue as Guest") {
                Task {
                    await state.signInAnonymously()
                }
            }
            .buttonStyle(.bordered)
            .disabled(state.isLoading)
        }
        .padding(.horizontal)
    }
}

struct SignInView: View {
    @ObservedObject var state: ViewState

    var body: some View {
        VStack(spacing: 15) {
            TextField("Email", text: $state.email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.emailAddress)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)

            SecureField("Password", text: $state.password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.password)

            Button(action: {
                Task {
                    await state.signInWithEmail()
                }
            }) {
                if state.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Text("Sign In")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(state.email.isEmpty || state.password.isEmpty || state.isLoading)

            Divider()
                .padding(.vertical)

            Button("Continue as Guest") {
                Task {
                    await state.signInAnonymously()
                }
            }
            .buttonStyle(.bordered)
            .disabled(state.isLoading)
        }
        .padding(.horizontal)
    }
}

struct AuthView: View {
    @ObservedObject var state: ViewState

    var body: some View {
        VStack(spacing: 20) {
            AuthHeaderView(state: state)

            if state.isSignUp {
                SignUpView(state: state)
            } else {
                SignInView(state: state)
            }

            if !state.errorMessage.isEmpty {
                Text(state.errorMessage)
                    .foregroundColor(.red)
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
        .padding()
        .onChange(of: state.isSignUp) { _ in
            state.clearForm()
        }
    }
}

struct ContentView: View {
    @StateObject private var state = ViewState()

    var body: some View {
        if state.isLoggedIn {
            VStack(spacing: 20) {
                Text("Personal Counter: \(state.counter)")
                    .font(.title)

                Button("Increment Counter") {
                    Task {
                        await state.incrementCounter()
                    }
                }
                .buttonStyle(.borderedProminent)

                Button("Sign Out") {
                    Task {
                        await state.signOut()
                    }
                }
                .buttonStyle(.bordered)

                if !state.errorMessage.isEmpty {
                    Text(state.errorMessage)
                        .foregroundColor(.red)
                        .font(.callout)
                }
            }
            .padding()
        } else {
            AuthView(state: state)
        }
    }
}

struct CounterResponse: Codable {
    let personalCounter: Int
}

#Preview {
    ContentView()
}
