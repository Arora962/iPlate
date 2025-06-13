import SwiftUI

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

    @State private var previousMeals: [LoggedMeal] = [
        LoggedMeal(name: "Idly", calories: 214, serving: "1 serving (128 g)", loggedDate: Date().addingTimeInterval(-3600), image: nil),
        LoggedMeal(name: "Appam", calories: 214, serving: "1 serving (128 g)", loggedDate: Date().addingTimeInterval(-7200), image: nil),
        LoggedMeal(name: "Dosa", calories: 214, serving: "1 serving (128 g)", loggedDate: Date().addingTimeInterval(-10800), image: nil),
        LoggedMeal(name: "Upma", calories: 214, serving: "1 serving (128 g)", loggedDate: Date().addingTimeInterval(-14400), image: nil)
    ]

    @State private var searchText = ""

    // MARK: Scan a Meal
    @State private var showCamera = false
    @State private var capturedWrapper: CapturedImageWrapper? = nil

    // Barcode scanner (if needed)
    @State private var isShowingScanner = false
    @State private var scannerPurpose = ""
    @State private var scannedCode = ""

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

                    /*ScanCard(title: "Scan a Barcode", systemImage: "barcode.viewfinder") {
                        scannerPurpose = "barcode"
                        isShowingScanner = true
                    }*/
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
                        // Wrap in Identifiable struct
                        DispatchQueue.main.async {
                            capturedWrapper = CapturedImageWrapper(image: img)
                        }
                    }
                }
            }

            // 2) Meal entry sheet using `.sheet(item:)`
            .sheet(item: $capturedWrapper) { wrapper in
                MealEntrySheet(image: wrapper.image) { name, calories in
                    let newMeal = LoggedMeal(
                        name: name,
                        calories: calories,
                        serving: "1 serving (custom)",
                        loggedDate: Date(),
                        image: wrapper.image
                    )
                    previousMeals.insert(newMeal, at: 0)
                    capturedWrapper = nil
                }
            }
        }
    }
}
