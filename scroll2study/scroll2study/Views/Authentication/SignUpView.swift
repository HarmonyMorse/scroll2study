import FirebaseAuth
import SwiftUI

struct SignUpView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isEmailValid = true
    @State private var passwordValidation: (isValid: Bool, message: String?) = (true, nil)
    @State private var showPasswordRequirements = false

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
                .textContentType(.newPassword)
                .onChange(of: password) { newValue in
                    passwordValidation = ValidationUtils.isValidPassword(newValue)
                    showPasswordRequirements = !newValue.isEmpty
                }
                .overlay(
                    !passwordValidation.isValid && !password.isEmpty
                        ? HStack {
                            Spacer()
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                                .padding(.trailing, 8)
                        } : nil
                )

            if showPasswordRequirements {
                VStack(alignment: .leading, spacing: 4) {
                    if let message = passwordValidation.message {
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.red)
                    } else {
                        Text("Password meets all requirements")
                            .font(.caption)
                            .foregroundColor(.green)
                    }

                    Text("Password must:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Group {
                        requirementText(
                            "Be 8-64 characters long", password.count >= 8 && password.count <= 64)
                        requirementText(
                            "Contain at least one uppercase letter",
                            password.contains(where: { $0.isUppercase }))
                        requirementText(
                            "Contain at least one lowercase letter",
                            password.contains(where: { $0.isLowercase }))
                        requirementText(
                            "Contain at least one number", password.contains(where: { $0.isNumber })
                        )
                        requirementText(
                            "Contain at least one special character (!@#$%^&*()_+-=[]{}|;:,.<>?)",
                            password.rangeOfCharacter(
                                from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?"))
                                != nil)
                    }
                }
                .padding(.horizontal)
            }

            // Confirm Password field
            SecureField("Confirm Password", text: $confirmPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.newPassword)

            // Sign Up button
            Button(action: signUp) {
                Text("Sign Up")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isValidForm ? Color.blue : Color.gray)
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

    private func requirementText(_ requirement: String, _ isMet: Bool) -> some View {
        HStack {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isMet ? .green : .secondary)
            Text(requirement)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var isValidForm: Bool {
        isEmailValid && !email.isEmpty && passwordValidation.isValid && !password.isEmpty
            && password == confirmPassword
    }

    private func signUp() {
        Task {
            do {
                try ValidationUtils.validateEmail(email)
                try ValidationUtils.validatePassword(password)
                authManager.authenticationState = .authenticating
                _ = try await authManager.signUp(email: email, password: password)
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
    SignUpView()
}
