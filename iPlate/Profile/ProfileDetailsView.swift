import SwiftUI
import FirebaseAuth

struct ProfileDetailsView: View {
    // We will observe Auth.auth().currentUser via this @StateObject
    @State private var displayName: String = ""
    @State private var email: String = ""
    @State private var photoURL: URL? = nil

    // If you want to reload whenever the view appears:
    var body: some View {
        VStack(spacing: 24) {
            // Profile picture (if available)
            if let url = photoURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 100, height: 100)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    case .failure:
                        Image(systemName: "person.crop.circle.badge.exclamationmark")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.secondary)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                // Fallback if no photoURL
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.gray)
            }

            // Display Name
            HStack {
                Text("Name:")
                    .font(.headline)
                Spacer()
                Text(displayName.isEmpty ? "Not set" : displayName)
                    .foregroundColor(displayName.isEmpty ? .secondary : .primary)
            }
            .padding(.horizontal)

            // Email
            HStack {
                Text("Email:")
                    .font(.headline)
                Spacer()
                Text(email)
                    .foregroundColor(.primary)
            }
            .padding(.horizontal)

            Spacer()
        }
        .navigationTitle("Profile details")
        .padding(.top, 32)
        .onAppear {
            loadCurrentUser()
        }
    }

    /// Read from FirebaseAuth.currentUser and populate local state.
    private func loadCurrentUser() {
        guard let user = Auth.auth().currentUser else {
            // No user is signed in; you can handle this case differently if needed.
            displayName = ""
            email = "Not signed in"
            photoURL = nil
            return
        }

        // If you set displayName / photoURL on your Auth user, you can read them here:
        displayName = user.displayName ?? ""
        email = user.email ?? "No email"
        photoURL = user.photoURL
    }
}

struct ProfileDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ProfileDetailsView()
        }
    }
}

