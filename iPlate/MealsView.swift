import SwiftUI

struct LoggedMeal: Identifiable {
    let id = UUID()
    let name: String
    let calories: Int
    let serving: String
    let loggedDate: Date
}

struct MealsView: View {
    // Sample data for previous meals (logged meals)
    @State private var previousMeals: [LoggedMeal] = [
        LoggedMeal(name: "Idly", calories: 214, serving: "1 serving (128 g)", loggedDate: Date().addingTimeInterval(-3600)),
        LoggedMeal(name: "Appam", calories: 214, serving: "1 serving (128 g)", loggedDate: Date().addingTimeInterval(-7200)),
        LoggedMeal(name: "Dosa", calories: 214, serving: "1 serving (128 g)", loggedDate: Date().addingTimeInterval(-10800)),
        LoggedMeal(name: "Upma", calories: 214, serving: "1 serving (128 g)", loggedDate: Date().addingTimeInterval(-14400))
    ]
    
    @State private var searchText: String = ""
    
    // For presenting alerts when scanning
    @State private var showingScanAlert = false
    @State private var scanAlertMessage = ""
    
    // Compute filtered meals based on search text
    var filteredMeals: [LoggedMeal] {
        if searchText.isEmpty {
            return previousMeals
        } else {
            return previousMeals.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Functional Search Bar
                TextField("Search Meals", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                // Scan Cards with functional buttons
                HStack(spacing: 16) {
                    ScanCard(title: "Scan a Meal", systemImage: "camera.fill") {
                        scanAlertMessage = "Scan a Meal functionality is not implemented yet."
                        showingScanAlert = true
                    }
                    ScanCard(title: "Scan a Barcode", systemImage: "barcode.viewfinder") {
                        scanAlertMessage = "Scan a Barcode functionality is not implemented yet."
                        showingScanAlert = true
                    }
                }
                .padding(.horizontal)
                
                // List of previous meals
                List(filteredMeals) { meal in
                    NavigationLink(destination: MealDetailView(meal: meal, onAddToMeal: {
                        // Simulate adding meal action (you can integrate your data update code here)
                        print("\(meal.name) added to your meal")
                    })) {
                        VStack(alignment: .leading) {
                            Text("\(meal.name) - \(meal.calories) Cal")
                                .font(.headline)
                            Text(meal.serving)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Meals")
            // Alert for scan buttons
            .alert(isPresented: $showingScanAlert) {
                Alert(title: Text("Info"), message: Text(scanAlertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
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

struct MealDetailView: View {
    let meal: LoggedMeal
    // Callback when the user taps "Add to Meal"
    var onAddToMeal: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text(meal.name)
                .font(.largeTitle)
                .bold()
            Text("\(meal.calories) Calories")
                .font(.title2)
            Text(meal.serving)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("Logged on: \(formattedDate(meal.loggedDate))")
                .font(.footnote)
                .foregroundColor(.gray)
            
            Button(action: onAddToMeal) {
                Text("Add to Meal")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            Spacer()
        }
        .padding()
        .navigationTitle("Meal Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    // Helper function to format the logged date.
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct MealsView_Previews: PreviewProvider {
    static var previews: some View {
        MealsView()
    }
}

