import SwiftUI

struct WelcomeScreen: View {
    var body: some View {
        NavigationStack {
            ZStack {
                // 1. Background gradient
                LinearGradient(
                    colors: [Color.orange.opacity(0.9), Color.red.opacity(0.9)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 30) {
                    // 2. Logo / icon at top
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.top, 60)

                    // 3. Main title
                    Text("Welcome to iPlate")
                        .font(.largeTitle)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)

                    // 4. Tagline
                    Text("Track your meals and calories, stay healthy.")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    Spacer()

                    // 5. Login button
                    NavigationLink {
                        LoginScreen()
                    } label: {
                        Text("Login")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue.opacity(0.9))
                            )
                            .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)
                    }
                    .padding(.horizontal, 40)

                    // 6. Sign Up button
                    NavigationLink {
                        SignupEmailScreen()
                    } label: {
                        Text("Sign Up")
                            .font(.headline)
                            .foregroundColor(.orange)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.9))
                            )
                            .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 3)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 60)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}
