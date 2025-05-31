import SwiftUI

struct MainRouterView: View {
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false

    var body: some View {
        if isLoggedIn {
            ContentView() // Your existing home screen
        } else {
            WelcomeScreen()
        }
    }
}

