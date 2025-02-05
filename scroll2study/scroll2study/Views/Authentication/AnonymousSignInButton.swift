import FirebaseAuth
import SwiftUI

struct AnonymousSignInButton: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        Button(action: signInAnonymously) {
            Text("Continue as Guest")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.2))
                .foregroundColor(.primary)
                .cornerRadius(10)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private func signInAnonymously() {
        Task {
            do {
                authManager.authenticationState = .authenticating
                _ = try await authManager.signInAnonymously()
            } catch {
                showError = true
                errorMessage = error.localizedDescription
                authManager.authenticationState = .unauthenticated
            }
        }
    }
}

#Preview {
    AnonymousSignInButton()
}
