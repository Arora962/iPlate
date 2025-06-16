import SwiftUI
import FirebaseAuth
import FirebaseFirestore
//import FirebaseStorage
import PhotosUI

struct ProfileDetailsView: View {
    @State private var displayName: String = ""
    @State private var email: String = ""
    @State private var photoURL: URL? = nil

    // Editable health details
    @State private var fullName = ""
    @State private var birthDate = Calendar.current.date(byAdding: .year, value: -20, to: Date())!
    @State private var calculatedAge = ""
    @State private var gender = ""
    @State private var selectedHeight: Int? = nil
    @State private var selectedWeight: Int? = nil

    // Profile image picker
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?

    @State private var isEditing = false
    @AppStorage("isLoggedIn") var isLoggedIn = false

    let genderOptions = ["F", "M", "Prefer not to say"]
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Profile picture
                ZStack {
                    if let uiImage = selectedImage {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } else if let url = photoURL {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView().frame(width: 100, height: 100)
                            case .success(let image):
                                image.resizable().scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            case .failure:
                                Image(systemName: "person.crop.circle.badge.exclamationmark")
                                    .resizable().scaledToFit()
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(.secondary)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.gray)
                    }

                    if isEditing {
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            Circle().strokeBorder(style: StrokeStyle(lineWidth: 2))
                                .frame(width: 100, height: 100)
                                .foregroundColor(.orange.opacity(0.7))
                        }
                        .onChange(of: selectedItem) {
                            Task {
                                if let data = try? await selectedItem?.loadTransferable(type: Data.self),
                                   let uiImage = UIImage(data: data) {
                                    selectedImage = uiImage
                                }
                            }
                        }
                    }
                }

                // Display Name
                
                HStack {
                    Text("Name:")
                        .font(.headline)
                    Spacer()
                    if isEditing {
                        TextField("Enter name", text: $displayName)
                            .multilineTextAlignment(.trailing)
                    } else {
                        Text(displayName.isEmpty ? "Not set" : displayName)
                            .foregroundColor(displayName.isEmpty ? .secondary : .primary)
                    }
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

                // Separator & Health Title
                Divider().padding(.horizontal)
                HStack {
                    Text("Health Details")
                        .font(.title2)
                        .bold()
                    Spacer()
                }
                .padding(.horizontal)

                // Full name
                fieldRow(title: "Full Name", binding: $fullName)

                // Birthdate (Age)
                HStack {
                    Text("Age:")
                        .font(.headline)
                    Spacer()
                    if isEditing {
                        DatePicker("", selection: $birthDate, in: ...Date(), displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .onChange(of: birthDate) {
                                calculatedAge = String(Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0)
                            }
                    } else {
                        Text(calculatedAge.isEmpty ? "Not set" : "\(calculatedAge) years old")
                            .foregroundColor(calculatedAge.isEmpty ? .secondary : .primary)
                    }
                }
                .padding(.horizontal)

                // Gender Picker
                HStack {
                    Text("Gender:")
                        .font(.headline)
                    Spacer()
                    if isEditing {
                        Picker("", selection: $gender) {
                            ForEach(genderOptions, id: \.self) { option in
                                Text(option).tag(option)
                            }
                        }
                        .pickerStyle(.menu)
                    } else {
                        Text(gender.isEmpty ? "Not set" : gender)
                            .foregroundColor(gender.isEmpty ? .secondary : .primary)
                    }
                }
                .padding(.horizontal)

                // Height Picker
                HStack {
                    Text("Height:")
                        .font(.headline)
                    Spacer()
                    if isEditing {
                        Picker("", selection: Binding(get: {
                            selectedHeight ?? 160
                        }, set: {
                            selectedHeight = $0
                        })) {
                            ForEach(100...220, id: \.self) { h in
                                Text("\(h) cm").tag(h)
                            }
                        }
                        .pickerStyle(.menu)
                    } else {
                        Text(selectedHeight != nil ? "\(selectedHeight!) cm" : "Not set")
                            .foregroundColor(selectedHeight == nil ? .secondary : .primary)
                    }
                }
                .padding(.horizontal)

                // Weight Picker
                HStack {
                    Text("Weight:")
                        .font(.headline)
                    Spacer()
                    if isEditing {
                        Picker("", selection: Binding(get: {
                            selectedWeight ?? 60
                        }, set: {
                            selectedWeight = $0
                        })) {
                            ForEach(30...150, id: \.self) { w in
                                Text("\(w) kg").tag(w)
                            }
                        }
                        .pickerStyle(.menu)
                    } else {
                        Text(selectedWeight != nil ? "\(selectedWeight!) kg" : "Not set")
                            .foregroundColor(selectedWeight == nil ? .secondary : .primary)
                    }
                }
                .padding(.horizontal)

                if isEditing {
                    Button("Save") {
                        saveProfileDetails()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.top)
                }
            }
            .padding()
            .navigationTitle("Profile Details")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isEditing.toggle()
                    } label: {
                        Image(systemName: isEditing ? "checkmark.circle" : "pencil")
                    }
                }
            }
            .onAppear {
                loadCurrentUser()
                loadHealthDetails()
            }
        }
    }

    // MARK: - Reusable Field
    func fieldRow(title: String, binding: Binding<String>) -> some View {
        HStack {
            Text("\(title):")
                .font(.headline)
            Spacer()
            if isEditing {
                TextField("Enter \(title.lowercased())", text: binding)
                    .multilineTextAlignment(.trailing)
            } else {
                Text(binding.wrappedValue.isEmpty ? "Not set" : binding.wrappedValue)
                    .foregroundColor(binding.wrappedValue.isEmpty ? .secondary : .primary)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Load Firebase Auth Info
    private func loadCurrentUser() {
        guard let user = Auth.auth().currentUser else {
            displayName = ""
            email = "Not signed in"
            photoURL = nil
            return
        }

        displayName = user.displayName ?? ""
        email = user.email ?? "No email"
        photoURL = user.photoURL
    }

    // MARK: - Load Health Info from Firestore
    private func loadHealthDetails() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let docRef = Firestore.firestore().collection("users").document(uid)

        docRef.getDocument { snapshot, error in
            if let data = snapshot?.data() {
                fullName = data["healthFullName"] as? String ?? ""
                gender = data["gender"] as? String ?? ""
                selectedHeight = Int(data["height"] as? String ?? "")
                selectedWeight = Int(data["weight"] as? String ?? "")
                if let ageStr = data["age"] as? String {
                    calculatedAge = ageStr
                }
            }
        }
    }

    // MARK: - Save Details to Firestore + Update Auth
    private func saveProfileDetails() {
        /*guard let user = Auth.auth().currentUser else { return }
         let uid = user.uid
         
         let db = Firestore.firestore()
         var data: [String: Any] = [
         "healthFullName": fullName,
         "age": age,
         "gender": gender,
         "height": height,
         "weight": weight
         ]
         
         // Upload profile image (optional)
         if let image = selectedImage,
         let imageData = image.jpegData(compressionQuality: 0.8) {
         let storageRef = Storage.storage().reference().child("profile_images/\(UUID().uuidString).jpg")
         storageRef.putData(imageData, metadata: nil) { _, err in
         if let err = err {
         print("Failed to upload image: \(err.localizedDescription)")
         return
         }
         storageRef.downloadURL { url, _ in
         if let url = url {
         photoURL = url
         data["profileImageUrl"] = url.absoluteString
         
         // Update Firebase Auth profile too
         let changeRequest = user.createProfileChangeRequest()
         changeRequest.displayName = displayName
         changeRequest.photoURL = url
         changeRequest.commitChanges { _ in }
         }
         db.collection("users").document(uid).setData(data, merge: true)
         }
         }
         } else {
         // No image upload, just update Firestore + Auth name
         let changeRequest = user.createProfileChangeRequest()
         changeRequest.displayName = displayName
         changeRequest.commitChanges { _ in }
         
         db.collection("users").document(uid).setData(data, merge: true)
         }
         
         isEditing = false
         }*/
        guard let user = Auth.auth().currentUser else { return }
        let uid = user.uid

        let db = Firestore.firestore()
        let data: [String: Any] = [
            "healthFullName": fullName,
            "age": calculatedAge,
            "gender": gender,
            "height": selectedHeight != nil ? "\(selectedHeight!)" : "",
            "weight": selectedWeight != nil ? "\(selectedWeight!)" : ""
        ]

        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = displayName
        changeRequest.commitChanges { _ in }

        db.collection("users").document(uid).setData(data, merge: true)
        isEditing = false
    }
}

struct ProfileDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ProfileDetailsView()
        }
    }
}
