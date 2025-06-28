import SwiftUI
import FirebaseAuth

// MARK: - Wrapper to make UIImage Identifiable
struct CapturedImageWrapper: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct ScanCard: View {
    let title: String
    let systemImage: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.orange)
                    .frame(height: 120)
                VStack {
                    Image(systemName: systemImage)
                        .font(.largeTitle)
                        .foregroundColor(.white)
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
        }
    }
}

struct MealsView: View {
    struct LoggedMeal: Identifiable {
        let id = UUID()
        let name: String
        let calories: Int
        let serving: String
        let loggedDate: Date
        let image: UIImage?
    }

    @State private var previousMeals: [LoggedMeal] = []

    @State private var searchText = ""

    // MARK: Scan a Meal
    @State private var showCamera = false
    @State private var capturedWrapper: CapturedImageWrapper? = nil

    var filteredMeals: [LoggedMeal] {
        searchText.isEmpty ? previousMeals :
            previousMeals.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            VStack {
                // Search bar
                TextField("Search Meals", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                // “Scan a Meal” + “Scan a Barcode” buttons
                HStack(spacing: 16) {
                    ScanCard(title: "Scan a Meal", systemImage: "camera.fill") {
                        showCamera = true
                    }
                }
                .padding(.horizontal)

                // Meal list
                List(filteredMeals) { meal in
                    NavigationLink(destination: MealDetailView(meal: meal)) {
                        HStack {
                            if let image = meal.image {
                                Image(uiImage: image)
                                    .resizable()
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            VStack(alignment: .leading) {
                                Text("\(meal.name) - \(meal.calories) Cal")
                                    .font(.headline)
                                Text(meal.serving)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Meals")

            // 1) Camera sheet
            .sheet(isPresented: $showCamera) {
                ImagePicker(sourceType: .camera) { image in
                    showCamera = false
                    if let img = image {
                        uploadMealImage(img) { result in
                            switch result {
                            case .success(let (name, calories)):
                                let newMeal = LoggedMeal(
                                    name: name,
                                    calories: calories,
                                    serving: "1 serving (from server)",
                                    loggedDate: Date(),
                                    image: img
                                )
                                DispatchQueue.main.async {
                                    previousMeals.insert(newMeal, at: 0)
                                }
                            case .failure(let error):
                                print("Upload failed:", error)
                            }
                        }
                    }
                }
            }
        }
    }
}

func uploadMealImage(_ image: UIImage, completion: @escaping (Result<(String, Int), Error>) -> Void) {
    guard let url = URL(string: "http://192.168.1.11:5001/upload") else {
        completion(.failure(NSError(domain: "Invalid URL", code: -1)))
        return
    }

    // Step 1: Get Firebase token
    Auth.auth().currentUser?.getIDToken(completion: { token, error in
        guard let token = token, error == nil else {
            print("❌ Failed to get Firebase token:", error ?? "Unknown error")
            completion(.failure(error ?? NSError(domain: "Token error", code: -2)))
            return
        }

        // Step 2: Prepare request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        // Step 3: Build body
        var body = Data()

        if let imageData = image.jpegData(compressionQuality: 0.8) {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"image\"; filename=\"meal.jpg\"\r\n")
            body.append("Content-Type: image/jpeg\r\n\r\n")
            body.append(imageData)
            body.append("\r\n")
        }

        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"weights\"\r\n\r\n")
        body.append("100\r\n")
        body.append("--\(boundary)--\r\n")

        request.httpBody = body

        // Step 4: Send request
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: -1)))
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let summary = json["summary"] as? [String: Any],
                   let calories = summary["calories"] as? Double,
                   let foods = json["foods"] as? [[String: Any]],
                   let first = foods.first,
                   let foodName = first["food"] as? String {
                    completion(.success((foodName.capitalized, Int(calories))))
                } else {
                    completion(.failure(NSError(domain: "Invalid response", code: -2)))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    })
}
// MARK: - Helper to append data to Data
extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
