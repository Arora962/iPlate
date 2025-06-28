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

struct WeightEntryCard: View {
    let image: UIImage
    var onSubmit: ([Double]) -> Void

    @Environment(\.dismiss) var dismiss
    @State private var w1 = ""
    @State private var w2 = ""
    @State private var w3 = ""
    @State private var w4 = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Enter Portion Weights")
                        .font(.title2)
                        .bold()

                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                    VStack(spacing: 12) {
                        HStack {
                            Text("Portion 1 (g):")
                            TextField("e.g. 120", text: $w1)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                        }
                        HStack {
                            Text("Portion 2 (g):")
                            TextField("e.g. 80", text: $w2)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                        }
                        HStack {
                            Text("Portion 3 (g):")
                            TextField("e.g. 60", text: $w3)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                        }
                        HStack {
                            Text("Portion 4 (g):")
                            TextField("e.g. 100", text: $w4)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    .padding()

                    Button(action: {
                        let weights: [Double] = [
                            Double(w1) ?? 0,
                            Double(w2) ?? 0,
                            Double(w3) ?? 0,
                            Double(w4) ?? 0
                        ]
                        onSubmit(weights)
                    }) {
                        Text("Submit")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.top)
                }
                .padding()
            }
            .navigationTitle("Weights")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
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
    @State private var isUploading = false

    @State private var showCamera = false
    @State private var pendingImage: UIImage? = nil
    @State private var showWeightEntry = false

    var filteredMeals: [LoggedMeal] {
        searchText.isEmpty ? previousMeals :
            previousMeals.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    TextField("Search Meals", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)

                    HStack(spacing: 16) {
                        ScanCard(title: "Scan a Meal", systemImage: "camera.fill") {
                            showCamera = true
                        }
                    }
                    .padding(.horizontal)

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

                if isUploading {
                    ZStack {
                        Color.black.opacity(0.4).ignoresSafeArea()
                        ProgressView("Analyzing meal...")
                            .foregroundColor(.primary)
                            .padding()
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(12)
                    }
                }
            }
            .navigationTitle("Meals")

            // Camera Sheet
            .sheet(isPresented: $showCamera) {
                ImagePicker(sourceType: .camera) { image in
                    showCamera = false
                    if let img = image {
                        pendingImage = img
                        showWeightEntry = true
                    }
                }
            }

            // Weight Entry Sheet
            .sheet(isPresented: $showWeightEntry) {
                if let img = pendingImage {
                    WeightEntryCard(image: img) { weights in
                        isUploading = true
                        uploadMealImage(img, weights: weights) { result in
                            isUploading = false
                            showWeightEntry = false
                            pendingImage = nil

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
                                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                                }
                            case .failure(let error):
                                UINotificationFeedbackGenerator().notificationOccurred(.error)
                                print("Upload failed:", error)
                            }
                        }
                    }
                }
            }
        }
    }
}
func uploadMealImage(_ image: UIImage, weights: [Double], completion: @escaping (Result<(String, Int), Error>) -> Void) {
    guard let url = URL(string: "http://192.168.1.11:5001/upload") else {
        completion(.failure(NSError(domain: "Invalid URL", code: -1)))
        return
    }

    Auth.auth().currentUser?.getIDToken(completion: { token, error in
        guard let token = token, error == nil else {
            completion(.failure(error ?? NSError(domain: "Token error", code: -2)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        var body = Data()

        if let imageData = image.jpegData(compressionQuality: 0.8) {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"image\"; filename=\"meal.jpg\"\r\n")
            body.append("Content-Type: image/jpeg\r\n\r\n")
            body.append(imageData)
            body.append("\r\n")
        }

        let weightsString = weights.map { String($0) }.joined(separator: ",")

        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"weights\"\r\n\r\n")
        body.append("\(weightsString)\r\n")
        body.append("--\(boundary)--\r\n")

        request.httpBody = body

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

// MARK: - Helper to append string to Data
extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
