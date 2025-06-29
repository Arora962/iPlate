//
//  MealDetailView.swift
//  iPlate
//
//  Created by Kriti Arora on 16/04/25.
//

import SwiftUI

struct MealDetailView: View {
    let meal: MealsView.LoggedMeal

    var body: some View {
        VStack(spacing: 20) {
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
            Text("\(meal.calories) Calories")
                .font(.title2)
            Text(meal.serving)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("Logged on: \(formattedDate(meal.loggedDate))")
                .font(.footnote)
                .foregroundColor(.gray)

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                Text("Detected Items:")
                    .font(.headline)
                ForEach(meal.foodList, id: \.self) { item in
                    Text("• \(item.capitalized)")
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
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
