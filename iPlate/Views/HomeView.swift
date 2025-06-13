import SwiftUI

enum CalorieOperation {
    case addition, subtraction
}

struct MealCategory: Identifiable, Codable {
    var id = UUID()
    let name: String
    let target: Int
    var consumed: Int
    let iconName: String
}

// For tracking selected meal + index (needed for sheet)
struct MealSheetItem: Identifiable {
    let id = UUID()
    let index: Int
    let meal: MealCategory
}

// Small reusable view for macro progress
struct NutrientRow: View {
    let name: String
    let percentage: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(name)
                    .font(.caption)
                    .foregroundColor(.white)
                Spacer()
                Text("\(percentage)%")
                    .font(.caption)
                    .foregroundColor(.white)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 4)
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: geo.size.width * CGFloat(percentage) / 100, height: 4)
                }
            }
            .frame(height: 4)
        }
    }
}

struct HomeView: View {
    @State private var selectedDate = Date()
    @State private var mealData: [String: [MealCategory]] = [:]
    @State private var selectedMealItem: MealSheetItem? = nil
    @State private var selectedAmount = 0
    @State private var selectedOperation: CalorieOperation = .addition

    // Helper to format date keys
    func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    var defaultMealCategories: [MealCategory] {
        [
            MealCategory(name: "Breakfast", target: 504, consumed: 0, iconName: "breakfast_icon"),
            MealCategory(name: "Lunch", target: 504, consumed: 0, iconName: "lunch_icon"),
            MealCategory(name: "Snacks", target: 168, consumed: 0, iconName: "snacks_icon"),
            MealCategory(name: "Dinner", target: 504, consumed: 0, iconName: "dinner_icon")
        ]
    }

    func initializeMealDataIfNeeded() {
        let key = dateKey(for: selectedDate)
        if mealData[key] == nil {
            mealData[key] = defaultMealCategories
        }
    }

    var currentMealCategories: Binding<[MealCategory]> {
        let key = dateKey(for: selectedDate)
        return Binding(
            get: { mealData[key] ?? defaultMealCategories },
            set: { mealData[key] = $0 }
        )
    }

    var overallProgress: Double {
        let meals = currentMealCategories.wrappedValue
        let consumed = meals.reduce(0) { $0 + $1.consumed }
        let target = meals.reduce(0) { $0 + $1.target }
        return target == 0 ? 0 : Double(consumed) / Double(target)
    }

    let nutrientProgress: [(String, Int)] = [
        ("Protein", 60), ("Carbs", 70), ("Fats", 50), ("Fiber", 80)
    ]

    var displayDate: String {
        if Calendar.current.isDateInToday(selectedDate) {
            return "Today"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: selectedDate)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Welcome to iPlate")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top)

                // Orange Card
                HStack {
                    VStack {
                        ZStack {
                            Circle()
                                .trim(from: 0, to: CGFloat(overallProgress))
                                .stroke(Color.white, lineWidth: 12)
                                .frame(width: 80, height: 80)
                                .rotationEffect(.degrees(-90))
                            Text("\(Int(overallProgress * 100))%")
                                .foregroundColor(.white)
                                .bold()
                        }
                        Text("Total Intake")
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(nutrientProgress, id: \.0) { name, percent in
                            NutrientRow(name: name, percentage: percent)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding()
                .background(Color.orange)
                .cornerRadius(16)
                .shadow(radius: 4)
                .padding(.horizontal)

                // Date
                HStack {
                    Text(displayDate)
                        .font(.headline)
                    Spacer()
                    DatePicker("", selection: $selectedDate, displayedComponents: [.date])
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .onChange(of: selectedDate) { _, _ in
                            initializeMealDataIfNeeded()
                        }
                }
                .padding(.horizontal)

                // Meal List
                List {
                    ForEach(currentMealCategories.wrappedValue.indices, id: \.self) { index in
                        let mealBinding = Binding<MealCategory>(
                            get: { currentMealCategories.wrappedValue[index] },
                            set: {
                                var updated = currentMealCategories.wrappedValue
                                updated[index] = $0
                                currentMealCategories.wrappedValue = updated
                            }
                        )

                        MealRow(meal: mealBinding, onAdd: {
                            selectedAmount = 0
                            selectedOperation = .addition
                            selectedMealItem = MealSheetItem(index: index, meal: mealBinding.wrappedValue)
                        })
                        .swipeActions(edge: .leading) {
                            Button(role: .destructive) {
                                selectedAmount = 0
                                selectedOperation = .subtraction
                                selectedMealItem = MealSheetItem(index: index, meal: mealBinding.wrappedValue)
                            } label: {
                                Label("Subtract", systemImage: "minus.circle.fill")
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .onAppear { initializeMealDataIfNeeded() }
            .navigationTitle("Home")
            .sheet(item: $selectedMealItem) { item in
                AdjustCaloriesSheet(
                    mealName: item.meal.name,
                    operation: selectedOperation,
                    selectedAmount: $selectedAmount,
                    onCancel: { selectedMealItem = nil },
                    onOk: {
                        if selectedOperation == .addition {
                            currentMealCategories.wrappedValue[item.index].consumed += selectedAmount
                        } else {
                            currentMealCategories.wrappedValue[item.index].consumed = max(0, currentMealCategories.wrappedValue[item.index].consumed - selectedAmount)
                        }
                        selectedMealItem = nil
                    }
                )
            }
        }
    }
}

// MARK: Meal Row

struct MealRow: View {
    @Binding var meal: MealCategory
    var onAdd: () -> Void

    var body: some View {
        HStack {
            Group {
                if let image = UIImage(named: meal.iconName) {
                    Image(uiImage: image).resizable()
                } else {
                    Image(systemName: "photo").resizable()
                }
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())

            VStack(alignment: .leading) {
                Text(meal.name)
                    .font(.headline)
                Text("\(meal.consumed) / \(meal.target) Cal")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundColor(.blue)
            }
        }
    }
}

// MARK: Calorie Sheet

struct AdjustCaloriesSheet: View {
    let mealName: String
    let operation: CalorieOperation
    @Binding var selectedAmount: Int
    var onCancel: () -> Void
    var onOk: () -> Void

    let amounts = Array(stride(from: 0, through: 500, by: 10))

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("\(operation == .addition ? "Add" : "Subtract") Calories for \(mealName)")) {
                    Picker("Calories", selection: $selectedAmount) {
                        ForEach(amounts, id: \.self) { amount in
                            Text("\(amount) Cal").tag(amount)
                        }
                    }
                    .pickerStyle(.wheel)
                }
            }
            .navigationTitle("\(operation == .addition ? "Add" : "Subtract") Calories")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK", action: onOk)
                }
            }
        }
    }
}
