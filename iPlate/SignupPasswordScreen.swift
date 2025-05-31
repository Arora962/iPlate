import SwiftUI
import FirebaseAuth
import Firebase
import FirebaseFirestore

struct SignupPasswordScreen: View {
    let email: String
    @State private var password = ""
    @State private var error = ""
    @AppStorage("isLoggedIn") var isLoggedIn = false

    var body: some View {
        VStack(spacing: 20) {
            SecureField("Set Password", text: $password)
                .textFieldStyle(.roundedBorder)

            if !error.isEmpty {
                Text(error)
                    .foregroundColor(.red)
            }

            Button("Create Account") {
                Auth.auth().createUser(withEmail: email, password: password) { result, err in
                    if let err = err {
                        error = err.localizedDescription
                        return
                    }
                    if let user = Auth.auth().currentUser {
                                let db = Firestore.firestore()
                                db.collection("users").document(user.uid).setData([
                                    "email": email,
                                    "password": password
                                ]) { firestoreError in
                                    if let firestoreError = firestoreError {
                                        print("Error saving user data to Firestore: \(firestoreError.localizedDescription)")
                                    }
                                }
                            }
                    isLoggedIn = true
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .navigationTitle("Set Password")
    }
}
