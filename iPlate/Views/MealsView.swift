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
            let summary: MealSummary
            let foods: [FoodItem]
            let serving: String
            let loggedDate: Date
            let image: UIImage?
        }

        struct MealSummary {
            let calories: Double
            let carbs: Double
            let fat: Double
            let fiber: Double
            let protein: Double
            let energy: Double
        }

        struct FoodItem: Identifiable {
            let id: UUID
            let name: String
            let quantity: Double
            let calories: Double
            let carbs: Double
            let fat: Double
            let fiber: Double
            let protein: Double

            init(name: String, quantity: Double, calories: Double, carbs: Double, fat: Double, fiber: Double, protein: Double) {
                self.id = UUID()
                self.name = name
                self.quantity = quantity
                self.calories = calories
                self.carbs = carbs
                self.fat = fat
                self.fiber = fiber
                self.protein = protein
            }
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
                                    Text("\(meal.name) - \(meal.summary.calories, specifier: "%.0f") Cal")
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
                    if let img = image, img.size.width > 0 && img.size.height > 0 {
                        capturedWrapper = CapturedImageWrapper(image: img)
                    } else {
                        errorMessage = "Invalid image captured. Please try again."
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            errorMessage = nil
                        }
                    }
                }
            }

            // Weight Entry Sheet
            .sheet(item: $capturedWrapper) { wrapper in
                WeightEntryCard(image: wrapper.image) { name, weights in
                    DispatchQueue.main.async {
                        isUploading = true
                    }

                    uploadMealImage(wrapper.image, weights: weights) { result in
                        DispatchQueue.main.async {
                            isUploading = false
                            capturedWrapper = nil
                        }

                        switch result {
                        case .success(let (summary, foods)):
                            let newMeal = LoggedMeal(
                                name: name,
                                summary: summary,
                                foods: foods,
                                serving: "1 serving",
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
                                errorMessage = error.localizedDescription
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                errorMessage = nil
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
    var onSubmit: (_ mealName: String, _ weights: [Double]) -> Void

    @Environment(\.dismiss) var dismiss
    @State private var mealName: String = ""
    @State private var weights = ["", "", "", ""]
    @FocusState private var focusedField: Int?
    @State private var showValidationError = false
    @State private var showNameError = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Meal Name")) {
                    TextField("Enter meal name", text: $mealName)
                    .submitLabel(.done)
                        .onSubmit {
                            focusedField = 0 // move to first weight field, or call submitAction() if you prefer
                        }
                }

                Section(header: Text("Captured Meal")) {
                    if image.size.width > 0 && image.size.height > 0 {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .cornerRadius(12)
                            .padding(.vertical, 8)
                    }
                }
                
                Section(header: Text("Portion Weights (grams)").font(.headline)) {
                    ForEach(0..<4, id: \.self) { index in
                        HStack {
                        Text("Portion \(index + 1):")
                            .fontWeight(.medium)
                        TextField("0", text: $weights[index])
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: index)
                            .submitLabel(index == 3 ? .done : .next)
                            .onSubmit {
                                if index < 3 {
                                    focusedField = index + 1
                                } else {
                                    focusedField = nil
                                }
                            }
                        }
                        .tag(index)
                    }
                }
                
                if showValidationError {
                    Text("⚠️ Please enter valid weights for all portions")
                        .foregroundColor(.red)
                        .font(.footnote)
                }
                if showNameError {
                    Text("⚠️ Meal name cannot be empty.")
                        .foregroundColor(.red)
                        .font(.footnote)
                }
                
                Section {
                    Button(action: submitAction) {
                        Text("Submit Analysis")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
            .navigationTitle("Meal Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                }
            }
        }
    }
    
    private func submitAction() {
        let validWeights = weights.compactMap { Double($0) }
        let trimmedName = mealName.trimmingCharacters(in: .whitespacesAndNewlines)
        if validWeights.count == 4, validWeights.allSatisfy({ $0 > 0 }), !trimmedName.isEmpty {
            focusedField = nil
            dismiss()
            onSubmit(trimmedName, validWeights)
        } else {
            if trimmedName.isEmpty{
                showNameError = true
            }
            else{
                showNameError = false
                showValidationError = true
            }
            withAnimation {
                focusedField = weights.firstIndex(where: { Double($0) == nil || Double($0) == 0 }) ?? 0
            }
        }
    }
}

// MARK: - Upload Function
func uploadMealImage(_ image: UIImage, weights: [Double], completion: @escaping (Result<(MealsView.MealSummary, [MealsView.FoodItem]), Error>) -> Void){
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
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                print("📦 Full Server JSON Response:\n", json ?? [:])

                guard let summaryDict = json?["summary"] as? [String: Any],
                      let foodsArray = json?["foods"] as? [[String: Any]] else {
                    completion(.failure(NSError(domain: "Missing fields", code: -99)))
                    return
                }

                let summary = MealsView.MealSummary(
                    calories: parseDouble(summaryDict["calories"]),
                    carbs: parseDouble(summaryDict["carbs"]),
                    fat: parseDouble(summaryDict["fat"]),
                    fiber: parseDouble(summaryDict["fiber"]),
                    protein: parseDouble(summaryDict["protein"]),
                    energy: parseDouble(summaryDict["energy"])
                )

                let foods = foodsArray.compactMap { food -> MealsView.FoodItem? in
                    guard let name = food["food"] as? String else { return nil }
                    return MealsView.FoodItem(
                        name: name.capitalized,
                        quantity: parseDouble(food["quantity_grams"]),
                        calories: parseDouble(food["calories"]),
                        carbs: parseDouble(food["carbs"]),
                        fat: parseDouble(food["fat"]),
                        fiber: parseDouble(food["fiber"]),
                        protein: parseDouble(food["protein"])
                    )
                }

                completion(.success((summary, foods)))

            } catch {
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
func parseDouble(_ value: Any?) -> Double {
    if let str = value as? String, let dbl = Double(str) { return dbl }
    if let dbl = value as? Double { return dbl }
    if let int = value as? Int { return Double(int) }
    return 0
}
