import FirebaseAuth
import SwiftUI

struct SignInView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isEmailValid = true

    var body: some View {
        VStack(spacing: 20) {
            // Email field
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.emailAddress)
                .autocapitalization(.none)
                .onChange(of: email) { newValue in
                    isEmailValid = ValidationUtils.isValidEmail(newValue)
                }
                .overlay(
                    !isEmailValid && !email.isEmpty
                        ? HStack {
                            Spacer()
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                                .padding(.trailing, 8)
                        } : nil
                )

            if !isEmailValid && !email.isEmpty {
                Text("Please enter a valid email address")
                    .font(.caption)
                    .foregroundColor(.red)
            }

            // Password field
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.password)

            // Sign In button
            Button(action: signIn) {
                Text("Sign In")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(!isValidForm)
        }
        .padding(.horizontal)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private var isValidForm: Bool {
        isEmailValid && !email.isEmpty && !password.isEmpty
    }

    private func signIn() {
        Task {
            do {
                try ValidationUtils.validateEmail(email)
                authManager.authenticationState = .authenticating
                _ = try await authManager.signIn(email: email, password: password)
            } catch let error as ValidationError {
                showError = true
                errorMessage = error.localizedDescription
                authManager.authenticationState = .unauthenticated
            } catch {
                showError = true
                errorMessage = error.localizedDescription
                authManager.authenticationState = .unauthenticated
            }
        }
    }
}

#Preview {
    SignInView()
}
