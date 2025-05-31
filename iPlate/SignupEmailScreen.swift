import SwiftUI
import FirebaseAuth

func isValidEmail(_ email: String) -> Bool {
    let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
    return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email)
}

struct SignupEmailScreen: View {
    @State private var email = ""
    @State private var error = ""
    @State private var showPasswordSetup = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Enter your email")
                .font(.headline)

            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)

            if !error.isEmpty {
                Text(error)
                    .foregroundColor(.red)
            }

            Button("Verify Email") {
                if isValidEmail(email) {
                    showPasswordSetup = true
                } else {
                    error = "Please enter a valid email address."
                }

            }
            .buttonStyle(.borderedProminent)

            //NavigationLink("", destination: SignupPasswordScreen(email: email), isActive: $showPasswordSetup)
            .navigationDestination(isPresented: $showPasswordSetup) {
                SignupPasswordScreen(email: email)
            }

        }
        .padding()
        .navigationTitle("Sign Up")
    }
}
