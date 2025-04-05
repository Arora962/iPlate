import SwiftUI

struct MealsView: View {
    // Sample data
    let previousMeals = [
        "Idly - 214 Cal (1 serving 128 g)",
        "Appam - 214 Cal (1 serving 128 g)",
        "Dosa - 214 Cal (1 serving 128 g)",
        "Upma - 214 Cal (1 serving 128 g)"
    ]
    
    var body: some View {
        NavigationStack {
            VStack {
                // Search field (if desired)
                TextField("Search", text: .constant(""))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                // Scan Cards (optional)
                HStack(spacing: 16) {
                    ScanCard(title: "Scan a Meal", systemImage: "camera.fill")
                    ScanCard(title: "Scan a Barcode", systemImage: "barcode.viewfinder")
                }
                .padding(.horizontal)

                // List of previous meals
                List(previousMeals, id: \.self) { meal in
                    NavigationLink(destination: Text(meal)) {
                        Text(meal)
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Meals")
        }
    }
}

/// A reusable orange card for scanning
struct ScanCard: View {
    let title: String
    let systemImage: String

    var body: some View {
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

struct MealsView_Previews: PreviewProvider {
    static var previews: some View {
        MealsView()
    }
}

