import SwiftUI
import FirebaseAuth
import GoogleSignIn
import GoogleSignInSwift
import Firebase

extension ActionCodeSettings {
    static func defaultSettings() -> ActionCodeSettings {
        let acs = ActionCodeSettings()
        // 1. This must match one of your “Authorized domains” in Firebase → Authentication → Sign-in methods
        acs.url = URL(string: "iplate.firebaseapp.com")
        
        // 2. Set handleCodeInApp = true so Firebase knows you'll catch the link in-app
        acs.handleCodeInApp = true
        
        // 3. The iOS bundle ID of your app (exact match)
        acs.setIOSBundleID(Bundle.main.bundleIdentifier!)
        
        // 4. If you want to use custom dynamic link domains, set them here. Otherwise, Firebase will use the default.
        // acs.dynamicLinkDomain = "YOUR_DYNAMIC_LINK_DOMAIN"
        
        return acs
    }
}


func isValidEmail(_ email: String) -> Bool {
    let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
    return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email)
}

struct SignupEmailScreen: View {
    @State private var email = ""
    @State private var errorMessage = ""
    @State private var showPasswordSetup = false
    @State private var showGoogleError = ""
    @AppStorage("isLoggedIn") var isLoggedIn = false
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: 1. Gradient Background
                LinearGradient(
                    colors: [Color.purple.opacity(0.9), Color.blue.opacity(0.9)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 30) {
                    // MARK: 2. Logo / Icon
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.top, 60)

                    // MARK: 3. Title + Subtitle
                    VStack(spacing: 8) {
                        Text("Create Your Account")
                            .font(.largeTitle)
                            .fontWeight(.black)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)

                        Text("Enter an email to get started")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }

                    // MARK: 4. Email Field
                    VStack(alignment: .leading, spacing: 6) {
                        TextField("Email address", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(colorScheme == .dark
                                          ? Color.white.opacity(0.1)
                                          : Color.white.opacity(0.7))
                            )
                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)

                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red.opacity(0.9))
                                .padding(.horizontal, 4)
                        }
                    }
                    .padding(.horizontal, 40)

                    // MARK: 5. “Verify Email” Button
                    Button(action: {
                        errorMessage = ""
                        guard isValidEmail(email) else {
                            errorMessage = "Please enter a valid email address."
                            return
                        }
                        // Attempt to send verification link (wired up in Step 3)
                        sendEmailVerificationLink(to: email)
                    }) {
                        Text("Verify Email")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.green.opacity(0.9))
                            )
                            .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)
                    }
                    .padding(.horizontal, 40)

                    // MARK: 6. OR Separator
                    HStack {
                        Rectangle()
                            .fill(Color.white.opacity(0.6))
                            .frame(height: 1)
                            .cornerRadius(0.5)
                        Text("OR")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        Rectangle()
                            .fill(Color.white.opacity(0.6))
                            .frame(height: 1)
                            .cornerRadius(0.5)
                    }
                    .padding(.horizontal, 40)
                    GoogleSignInButton {
                        signInWithGoogle()
                    }
                    .frame(height: 50)
                    .padding(.horizontal, 40)

                    // MARK: 7. “Sign in with Google” Button
                    /*Button(action: {
                        errorMessage = ""
                        signInWithGoogle()
                    }) {
                        HStack {
                            Image(systemName: "globe") // placeholder; you could use a custom Google logo
                                .font(.title2)
                            Text("Sign in with Google")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.red.opacity(0.9))
                        )
                        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)
                    }
                    .padding(.horizontal, 40)*/

                    if !showGoogleError.isEmpty {
                        Text(showGoogleError)
                            .font(.caption)
                            .foregroundColor(.red.opacity(0.9))
                            .padding(.horizontal, 40)
                    }

                    Spacer()

                    // MARK: 8. NavigationLink to Password Setup (if you still want a separate password screen)
                    }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                        /*.navigationDestination(isPresented: $showPasswordSetup) {
                            SignupPasswordScreen(email: email)
                        }*/
                        .navigationBarBackButtonHidden(true)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button(action: {
                                    // Action to go back
                                    dismiss()
                                }) {
                                    HStack {
                                        Image(systemName: "chevron.left")
                                        Text("Back")
                                    }
                                }
                                .foregroundColor(.white)
                            }
                        }
                }
            }

    // MARK: 9. Email Link Sending Logic (see Step 3)
    private func sendEmailVerificationLink(to email: String) {
        let acs = ActionCodeSettings.defaultSettings()
            
            Auth.auth().sendSignInLink(toEmail: email, actionCodeSettings: acs) { error in
                if let error = error {
                    errorMessage = "Failed to send link: \(error.localizedDescription)"
                    return
                }
                
                // Success! Tell the user to check their email:
                errorMessage = "📧 Check your email for a sign-in link. Once you tap it, you’ll return to the app."
                
                // Save the email locally so we can complete sign-in after the link is tapped.
                UserDefaults.standard.set(email, forKey: "EmailForSignIn")
            }
    }

    // MARK: 10. Google Sign-In Logic
    private func signInWithGoogle() {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            showGoogleError = "Unable to find client ID."
            return
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            showGoogleError = "Cannot find root view controller."
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { result, error in
            if let error = error {
                showGoogleError = error.localizedDescription
                return
            }

            guard let result = result else {
                showGoogleError = "Google sign-in failed."
                return
            }

            
            let idToken = result.user.idToken?.tokenString
            let accessToken = result.user.accessToken.tokenString

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken!,
                accessToken: accessToken
            )

            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    showGoogleError = error.localizedDescription
                    return
                }

                showPasswordSetup = true
                isLoggedIn = true
            }
        }
    }

}
