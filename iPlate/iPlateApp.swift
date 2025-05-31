//
//  iPlateApp.swift
//  iPlate
//
//

import SwiftUI
import SwiftData
import Firebase

@main
struct iPlateApp: App {
    init() {
            FirebaseApp.configure()
        }
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainRouterView()
        }
        .modelContainer(sharedModelContainer)
    }
}
