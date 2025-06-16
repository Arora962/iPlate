import SwiftUI
import FirebaseAuth
import Firebase
import GoogleSignIn
import GoogleSignInSwift

struct LoginScreen: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isPasswordVisible = false
    @AppStorage("isLoggedIn") var isLoggedIn = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()

                // Title
                VStack(spacing: 6) {
                    Text("Login to your account")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Welcome back! Please enter your details.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                // Email Field
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)

                // Password Field
                HStack {
                    Group {
                        if isPasswordVisible {
                            TextField("Enter your password", text: $password)
                        } else {
                            SecureField("Enter your password", text: $password)
                        }
                    }
                    .textContentType(.password)
                    .padding()

                    Button(action: {
                        isPasswordVisible.toggle()
                    }) {
                        Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.gray)
                    }
                }
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)

                // Forgot Password
                HStack {
                    Spacer()
                    Button("Forgot Password") {
                        // Optional: implement password reset later
                    }
                    .foregroundColor(.orange)
                }

                // Error Message
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }

                // Login Button
                Button {
                    loginWithEmailPassword()
                } label: {
                    Text("Login now")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.orange)
                        .cornerRadius(20)
                }

                // Google Sign-In Button
                GoogleSignInButton(action: signInWithGoogle)
                    .frame(height: 44)

                // Sign Up Redirect
                HStack {
                    Text("Don't have an account ?")
                    NavigationLink("Sign up", destination: SignupScreen())
                        .foregroundColor(.orange)
                }
                .font(.footnote)
                .padding(.top)

                Spacer()
            }
            .padding()
        }
    }

    // MARK: - Firebase Email Login
    private func loginWithEmailPassword() {
        errorMessage = ""
        Auth.auth().signIn(withEmail: email, password: password) { result, err in
            if let err = err {
                errorMessage = err.localizedDescription
                return
            }
            isLoggedIn = true
        }
    }

    // MARK: - Google Sign-In
    private func signInWithGoogle() {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage = "Missing Client ID"
            return
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            errorMessage = "Cannot find root view controller"
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
                return
            }

            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                errorMessage = "Failed to get token"
                return
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: user.accessToken.tokenString
            )

            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    errorMessage = error.localizedDescription
                    return
                }
                isLoggedIn = true
            }
        }
    }
}
