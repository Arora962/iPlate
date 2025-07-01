import SwiftUI

struct MealDetailView: View {
    let meal: MealsView.LoggedMeal

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let image = meal.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(12)
                        .padding()
                }

                Text(meal.name)
                    .font(.largeTitle)
                    .bold()

                Text("Logged on: \(formattedDate(meal.loggedDate))")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("🔢 Total Nutrition Summary")
                        .font(.headline)
                    Text("• Calories: \(meal.summary.calories, specifier: "%.1f") kcal")
                    Text("• Protein: \(meal.summary.protein, specifier: "%.1f") g")
                    Text("• Carbs: \(meal.summary.carbs, specifier: "%.1f") g")
                    Text("• Fat: \(meal.summary.fat, specifier: "%.1f") g")
                    Text("• Fiber: \(meal.summary.fiber, specifier: "%.1f") g")
                    Text("• Energy: \(meal.summary.energy, specifier: "%.1f") kJ")
                }

                Divider()

                VStack(alignment: .leading, spacing: 10) {
                    Text("🍽️ Detected Items")
                        .font(.headline)
                    ForEach(meal.foods) { food in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• \(food.name) (\(food.quantity, specifier: "%.0f")g)")
                                .bold()
                            Text("   - Calories: \(food.calories, specifier: "%.1f")")
                            Text("   - Protein: \(food.protein, specifier: "%.2f")g")
                            Text("   - Carbs: \(food.carbs, specifier: "%.2f")g")
                            Text("   - Fat: \(food.fat, specifier: "%.2f")g")
                            Text("   - Fiber: \(food.fiber, specifier: "%.2f")g")
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Meal Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
