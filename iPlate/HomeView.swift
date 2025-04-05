import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Title
                Text("Welcome to iPlate")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top)

                // Orange Card (Calorie & Macro Info)
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.orange)
                        .frame(height: 200)
                        .shadow(radius: 4)
                    
                    VStack {
                        // Circular progress display (example: 70%)
                        ZStack {
                            Circle()
                                .trim(from: 0, to: 0.7)
                                .stroke(Color.white.opacity(0.3), lineWidth: 12)
                                .frame(width: 80, height: 80)
                                .rotationEffect(.degrees(-90))
                            Text("70%")
                                .foregroundColor(.white)
                                .bold()
                        }
                        Text("Calorie Intake")
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal)

                // Date Selector
                HStack {
                    Button {
                        // Previous day action
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    Spacer()
                    Text("Today")
                        .font(.headline)
                    Spacer()
                    Button {
                        // Next day action
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                }
                .padding(.horizontal)

                // Meal Categories List
                List {
                    MealRow(mealName: "Breakfast", calories: 504)
                    MealRow(mealName: "Lunch", calories: 600)
                    MealRow(mealName: "Snacks", calories: 300)
                    MealRow(mealName: "Dinner", calories: 700)
                }
                .listStyle(.plain)
            }
            .navigationTitle("Home")
        }
    }
}

/// A row representing a single meal category
struct MealRow: View {
    let mealName: String
    let calories: Int
    
    var body: some View {
        HStack {
            Image(systemName: "fork.knife.circle.fill")
                .font(.title2)
                .foregroundColor(.orange)
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading) {
                Text(mealName)
                    .font(.headline)
                Text("0 / \(calories) Cal")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button {
                // Action to add meal
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundColor(.blue)
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}

