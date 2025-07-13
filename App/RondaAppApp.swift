//
//  RondaAppApp.swift
//  RondaApp
//
//  Created by David Roger Alvarez on 10/7/25.
//

import SwiftUI
import FirebaseCore // 1. Importar Firebase

// 2. Creamos un AppDelegate para configurar Firebase
class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}

@main
struct RondaAppApp: App {
    // 3. Registramos el AppDelegate para que sea utilizado por SwiftUI
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            // De momento mantenemos la ContentView, que más adelante será el LoginView
            RootView()
        }
    }
}
