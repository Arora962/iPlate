import SwiftUI

struct MainRouterView: View {
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @State private var showCompleteSignIn = false

    var body: some View {
            ZStack {
                if isLoggedIn {
                    ContentView()
                } else {
                    WelcomeScreen()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .didReceiveEmailLink)) { _ in
                showCompleteSignIn = true
            }
            .sheet(isPresented: $showCompleteSignIn) {
                CompleteEmailSignInView()
            }
        }
    }

