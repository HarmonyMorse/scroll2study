import FirebaseAuth
import SwiftUI

struct SignInView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isEmailValid = true
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 20) {
            // Email field
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.emailAddress)
                .autocapitalization(.none)
                .disabled(isLoading)
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
                .disabled(isLoading)

            // Sign In button
            Button(action: signIn) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Sign In")
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isValidForm ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(10)
            .disabled(!isValidForm || isLoading)
        }
        .padding(.horizontal)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {
                isLoading = false
            }
        } message: {
            Text(errorMessage)
        }
    }

    private var isValidForm: Bool {
        isEmailValid && !email.isEmpty && !password.isEmpty
    }

    private func signIn() {
        isLoading = true
        Task {
            do {
                try ValidationUtils.validateEmail(email)
                _ = try await authManager.signIn(email: email, password: password)
                // If we get here, authentication was successful
                isLoading = false
            } catch let error as ValidationError {
                showError = true
                errorMessage = error.localizedDescription
                isLoading = false
            } catch let error as AuthError {
                showError = true
                errorMessage = error.localizedDescription
                isLoading = false
            } catch {
                showError = true
                errorMessage = "An unexpected error occurred. Please try again."
                isLoading = false
            }
        }
    }
}

#Preview {
    SignInView()
}
