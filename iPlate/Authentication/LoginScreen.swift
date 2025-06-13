import SwiftUI
import FirebaseAuth

struct LoginScreen: View {
    @State private var email = ""
    @State private var password = ""
    @State private var error = ""
    @AppStorage("isLoggedIn") var isLoggedIn = false

    var body: some View {
        VStack(spacing: 20) {
            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)

            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)

            if !error.isEmpty {
                Text(error)
                    .foregroundColor(.red)
            }

            Button("Login") {
                Auth.auth().signIn(withEmail: email, password: password) { result, err in
                    if let err = err {
                        error = err.localizedDescription
                        return
                    }
                    isLoggedIn = true
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .navigationTitle("Login")
    }
}
