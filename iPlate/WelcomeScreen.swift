import SwiftUI

struct WelcomeScreen: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Welcome to iPlate")
                    .font(.largeTitle)
                    .bold()

                NavigationLink("Login", destination: LoginScreen())
                    .buttonStyle(.borderedProminent)

                NavigationLink("Sign Up", destination: SignupEmailScreen())
                    .buttonStyle(.bordered)
            }
            .padding()
        }
    }
}
