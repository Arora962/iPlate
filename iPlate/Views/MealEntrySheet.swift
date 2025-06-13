//
//  MealEntrySheet.swift
//  iPlate
//
//  Created by Kriti Arora on 16/04/25.
//


import SwiftUI

struct MealEntrySheet: View {
    let image: UIImage
    var onSave: (_ name: String, _ calories: Int) -> Void

    @Environment(\.dismiss) var dismiss
    @State private var name: String = ""
    @State private var calories: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(12)
                }

                Section(header: Text("Meal Details")) {
                    TextField("Meal Name", text: $name)
                    TextField("Calories", text: $calories)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Add Meal")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let cal = Int(calories) ?? 0
                        onSave(name.isEmpty ? "Untitled Meal" : name, cal)
                    }
                }
            }
        }
    }
}
