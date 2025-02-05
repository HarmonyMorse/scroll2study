import FirebaseAuth
import SwiftUI

struct AuthenticationView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var showSignUp = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Logo or App Title
                Text("scroll2study")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                if authManager.authenticationState == .authenticating {
                    ProgressView()
                } else {
                    if !showSignUp {
                        SignInView()
                    } else {
                        SignUpView()
                    }

                    // Toggle between sign in and sign up
                    Button(action: {
                        withAnimation {
                            showSignUp.toggle()
                        }
                    }) {
                        Text(
                            showSignUp
                                ? "Already have an account? Sign In"
                                : "Don't have an account? Sign Up"
                        )
                        .foregroundColor(.blue)
                    }

                    // Anonymous Sign In
                    AnonymousSignInButton()
                }
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    AuthenticationView()
}
