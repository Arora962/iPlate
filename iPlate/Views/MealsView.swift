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
    @State private var isUploading = false

    @State private var showCamera = false
    @State private var capturedWrapper: CapturedImageWrapper? = nil
    
    @State private var errorMessage: String? = nil

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
                                if let image = meal.image, image.size.width > 0, image.size.height > 0 {
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
                
                if let message = errorMessage {
                    VStack {
                        Spacer()
                        Text(message)
                            .padding()
                            .background(Color.red.opacity(0.9))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.bottom, 40)
                            .transition(.opacity)
                    }
                    .animation(.easeInOut, value: errorMessage)
                }

                if isUploading {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    ProgressView("Analyzing meal...")
                        .foregroundColor(.primary)
                        .padding()
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(12)
                }
            }
            .navigationTitle("Meals")

            // Camera Sheet
            .sheet(isPresented: $showCamera) {
                ImagePicker(sourceType: .camera) { image in
                    showCamera = false
                    if let img = image {
                        capturedWrapper = CapturedImageWrapper(image: img)
                    }
                }
            }

            // Weight Entry Sheet
            .sheet(item: $capturedWrapper) { wrapper in
                if wrapper.image.size.width == 0 || wrapper.image.size.height == 0 {
                    Text("⚠️ Failed to load a valid image. Please try again.")
                        .foregroundColor(.red)
                        .padding()
                } else {
                    WeightEntryCard(image: wrapper.image) { weights in
                        DispatchQueue.main.async {
                            isUploading = true
                        }

                        uploadMealImage(wrapper.image, weights: weights) { result in
                            DispatchQueue.main.async {
                                isUploading = false
                                capturedWrapper = nil
                            }

                            switch result {
                            case .success(let (name, calories)):
                                let newMeal = LoggedMeal(
                                    name: name,
                                    calories: calories,
                                    serving: "1 serving (from server)",
                                    loggedDate: Date(),
                                    image: wrapper.image
                                )
                                DispatchQueue.main.async {
                                    previousMeals.insert(newMeal, at: 0)
                                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                                }
                            case .failure(let error):
                                DispatchQueue.main.async {
                                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                                    print("Upload failed:", error.localizedDescription)
                                }
                                errorMessage = error.localizedDescription
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    errorMessage = nil
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Weight Entry Card
struct WeightEntryCard: View {
    let image: UIImage
    var onSubmit: ([Double]) -> Void

    @Environment(\.dismiss) var dismiss
    @State private var w1 = ""
    @State private var w2 = ""
    @State private var w3 = ""
    @State private var w4 = ""
    @FocusState private var focusedField: Field?
    @State private var showValidationError = false

    enum Field: Hashable {
        case w1, w2, w3, w4
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Text("Enter Portion Weights")
                        .font(.title2.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                    if image.size.width > 0 && image.size.height > 0 {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal)
                    }

                    VStack(spacing: 16) {
                        labeledField("Portion 1 (g)", text: $w1, focus: .w1, next: .w2)
                        labeledField("Portion 2 (g)", text: $w2, focus: .w2, next: .w3)
                        labeledField("Portion 3 (g)", text: $w3, focus: .w3, next: .w4)
                        labeledField("Portion 4 (g)", text: $w4, focus: .w4, next: nil)
                    }
                    .padding(.horizontal)

                    if showValidationError {
                        Text("⚠️ Please enter all 4 weights.")
                            .foregroundColor(.red)
                            .font(.footnote)
                            .padding(.top, -8)
                    }

                    Button(action: {
                        let weights = [w1, w2, w3, w4].compactMap { Double($0) }
                        if weights.count == 4 && !weights.contains(0) {
                            focusedField = nil
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onSubmit(weights)
                            }
                        } else {
                            showValidationError = true
                        }
                    }) {
                        Text("Submit")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(radius: 2)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Weights")
            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    Button("Done") {
                        focusedField = nil
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    @ViewBuilder
    func labeledField(_ label: String, text: Binding<String>, focus: Field, next: Field?) -> some View {
        HStack {
            Text(label)
                .frame(width: 120, alignment: .leading)
                .font(.subheadline.bold())
            TextField("e.g. 120", text: text)
                .keyboardType(.decimalPad)
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .focused($focusedField, equals: focus)
                .submitLabel(next != nil ? .next : .done)
                .onSubmit {
                    focusedField = next
                }
        }
    }
}

// MARK: - Upload Function
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
                let json = try JSONSerialization.jsonObject(with: data)
                print("✅ Raw JSON:", json)

                guard let dict = json as? [String: Any] else {
                    completion(.failure(NSError(domain: "Invalid top-level object", code: -2)))
                    return
                }

                // ✅ Handle backend-side error gracefully
                if let serverError = dict["error"] as? String {
                    print("⚠️ Server error:", serverError)
                    completion(.failure(NSError(domain: serverError, code: -3)))
                    return
                }

                guard let summary = dict["summary"] as? [String: Any] else {
                    completion(.failure(NSError(domain: "Missing summary", code: -2)))
                    return
                }

                // ✅ Handle calories being a String or Double
                var calorieValue: Double? = nil
                if let calStr = summary["calories"] as? String {
                    calorieValue = Double(calStr)
                } else if let calDouble = summary["calories"] as? Double {
                    calorieValue = calDouble
                }

                guard let calories = calorieValue else {
                    completion(.failure(NSError(domain: "Calories missing or invalid", code: -2)))
                    return
                }

                guard let foods = dict["foods"] as? [[String: Any]],
                      let first = foods.first,
                      let foodName = first["food"] as? String else {
                    completion(.failure(NSError(domain: "Missing or invalid foods", code: -2)))
                    return
                }

                completion(.success((foodName.capitalized, Int(calories))))

            } catch {
                print("❌ JSON decode failed:", error)
                completion(.failure(error))
            }

        }.resume()
    })
}

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
