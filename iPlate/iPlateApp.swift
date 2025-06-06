//
//  iPlateApp.swift
//  iPlate
//
//

import SwiftUI
import SwiftData
import Firebase
import FirebaseCore
import GoogleSignIn

@main
struct iPlateApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
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
class AppDelegate: NSObject, UIApplicationDelegate {
  func application(
      _ application: UIApplication,
      didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
  ) -> Bool {
      return true
  }

  // This method lets GoogleSignIn handle the redirect URL
  func application(
      _ app: UIApplication,
      open url: URL,
      options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
      return GIDSignIn.sharedInstance.handle(url)
  }
}
extension Notification.Name {
    static let didReceiveEmailLink = Notification.Name("didReceiveEmailLink")
}
