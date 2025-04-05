import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Profile & Goals")) {
                    NavigationLink("Profile details") {
                        Text("Profile Details Screen")
                            .navigationTitle("Profile details")
                    }
                    NavigationLink("Goal details") {
                        Text("Goal Details Screen")
                            .navigationTitle("Goal details")
                    }
                }

                Section(header: Text("Account & Connectivity")) {
                    NavigationLink("Accounts") {
                        Text("Accounts Screen")
                            .navigationTitle("Accounts")
                    }
                    NavigationLink("Notifications") {
                        Text("Notifications Screen")
                            .navigationTitle("Notifications")
                    }
                    NavigationLink("Connected devices") {
                        Text("Connected Devices Screen")
                            .navigationTitle("Connected devices")
                    }
                }

                Section(header: Text("Other")) {
                    NavigationLink("Terms of use") {
                        Text("Terms of Use Screen")
                            .navigationTitle("Terms of use")
                    }
                    NavigationLink("Privacy policy") {
                        Text("Privacy Policy Screen")
                            .navigationTitle("Privacy policy")
                    }
                    Button("Log out") {
                        // Handle log out action
                    }
                }
            }
            .navigationTitle("Settings")
            .listStyle(.insetGrouped)
            // Display version at the bottom
            .safeAreaInset(edge: .bottom) {
                Text("Version 1.0")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}

