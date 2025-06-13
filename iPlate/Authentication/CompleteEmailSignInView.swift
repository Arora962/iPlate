import SwiftUI
import FirebaseAuth

struct CompleteEmailSignInView: View {
    @State private var message = "Completing sign-in..."
    @Environment(\.openURL) var openURL

    var body: some View {
        VStack(spacing: 20) {
            Text(message)
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding()
            Spacer()
        }
        .onAppear {
            handleIncomingLink()
        }
    }

    private func handleIncomingLink() {
        // 1. Grab the link that opened the app (from the URL context)
        guard let fullURL = URLContext.urlToOpen else {
            message = "No link detected."
            return
        }

        // 2. Check if it’s a sign-in with email link
        if Auth.auth().isSignIn(withEmailLink: fullURL.absoluteString) {
            // 3. Retrieve the email we stored earlier
            guard let email = UserDefaults.standard.string(forKey: "EmailForSignIn") else {
                message = "Email not found; please retry."
                return
            }

            // 4. Complete sign-in
            Auth.auth().signIn(withEmail: email, link: fullURL.absoluteString) { result, error in
                if let error = error {
                    message = "Failed to sign in: \(error.localizedDescription)"
                    return
                }
                // Success!
                message = "✅ You’re now signed in!"
                // e.g. navigate to your HomeView or set App state to “logged in”
            }
        } else {
            message = "Invalid sign-in link."
        }
    }
}

// A small helper to store the incoming URL context statically—so SwiftUI can read it.
// In a real app, you might store this in an @StateObject on the Scene, but this is simplest.
enum URLContext {
    static var urlToOpen: URL?
}
