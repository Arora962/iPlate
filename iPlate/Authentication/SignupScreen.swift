//
//  SignupScreen.swift
//  iPlate
//
//


import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import GoogleSignInSwift
import AuthenticationServices

struct SignupScreen: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var agreeToTerms = false
    @State private var isPasswordVisible = false
    @AppStorage("isLoggedIn") var isLoggedIn = false
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    @State private var navigateToOTP = false
    @State private var generatedPassword = ""
    @State private var generatedOTP = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()

                // Heading
                VStack(spacing: 8) {
                    Text("Create an account")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text("Join us and explore new possibilities!")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                // Email
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
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

                // Error Message
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Forgot Password (for now just UI)
                HStack {
                    Spacer()
                    Button("Forgot Password") {
                        // Can be implemented later
                    }
                    .foregroundColor(.orange)
                }

                // Create Account Button
                Button(action: registerWithEmailPassword) {
                    Text("Create account")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(agreeToTerms ? Color.orange : Color.gray)
                        .cornerRadius(20)
                }
                .disabled(!agreeToTerms)

                // Terms and Conditions
                HStack(spacing: 4) {
                    Button(action: {
                        agreeToTerms.toggle()
                    }) {
                        Image(systemName: agreeToTerms ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(.orange)
                    }

                    Text("I agree to the ")
                    + Text("Privacy Policy").foregroundColor(.orange)
                    + Text(" and ")
                    + Text("Terms of Service").foregroundColor(.orange)
                }
                .font(.footnote)
                .multilineTextAlignment(.center)

                // OR separator
                HStack {
                    Rectangle().frame(height: 1).foregroundColor(.gray)
                    Text("OR")
                        .font(.footnote)
                        .foregroundColor(.gray)
                    Rectangle().frame(height: 1).foregroundColor(.gray)
                }

                // Google Sign-in
                GoogleSignInButton(action: signInWithGoogle)
                    .frame(height: 44)

                // Apple Sign-in
                SignInWithAppleButton(
                    .signUp,
                    onRequest: { request in
                        request.requestedScopes = [.email, .fullName]
                    },
                    onCompletion: handleAppleSignIn
                )
                .frame(height: 44)
                .signInWithAppleButtonStyle(
                    colorScheme == .dark ? .white : .black
                )

                // Already have an account
                HStack {
                    Text("Already have an account?")
                    Button("Log in") {
                        // Navigate back
                        dismiss()
                    }
                    .foregroundColor(.orange)
                }
                .font(.footnote)
                .padding(.top)

                Spacer()
            }
            .padding()
            .navigationDestination(isPresented: $navigateToOTP) {
                OTPScreen(email: email, generatedOTP: generatedOTP, originalPassword: generatedPassword)
            }
        }
    }

    // MARK: Register with Firebase
    private func registerWithEmailPassword() {
        errorMessage = ""
        guard isValidEmail(email), password.count >= 6 else {
            errorMessage = "Please enter a valid email and password (min 6 characters)."
            return
        }

        // Generate 6-digit OTP
            let otp = String(format: "%06d", Int.random(in: 0...999999))
            generatedOTP = otp

            // Simulate sending email (just print to console for now)
            print("OTP for \(email) is \(otp)")  // In real app, you'd call backend here

            // Navigate to OTP screen with this OTP
            generatedPassword = password
            navigateToOTP = true
    }

    // MARK: Google Sign-in
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

    // MARK: Apple Sign-in (Basic Handler)
    private func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authResults):
            guard let appleIDCredential = authResults.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = appleIDCredential.identityToken,
                  let tokenString = String(data: tokenData, encoding: .utf8) else {
                errorMessage = "Failed to get Apple identity token"
                return
            }

            let credential = OAuthProvider.credential(
                providerID: .apple,
                idToken: tokenString,
                rawNonce: "",
                accessToken: ""
            )

            Auth.auth().signIn(with: credential) { result, error in
                if let error = error {
                    errorMessage = error.localizedDescription
                } else {
                    isLoggedIn = true
                }
            }

        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    // MARK: Email Validator
    private func isValidEmail(_ email: String) -> Bool {
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email)
    }
}
