//
//  RondaAppApp.swift
//  RondaApp
//
//  Created by David Roger Alvarez on 10/7/25.
//

import SwiftUI
import FirebaseCore
import FirebaseAppCheck // ✅ 1. Importar App Check

// Usamos un AppDelegate para configurar los servicios de Firebase al arrancar.
class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    
    // ✅ 2. Configuración de App Check para MODO DEPURACIÓN (DEBUG)
    // Este bloque le dice a Firebase que confíe en tu simulador.
    #if DEBUG
    let providerFactory = AppCheckDebugProviderFactory()
    AppCheck.setAppCheckProviderFactory(providerFactory)
    #endif

    // 3. Configuración estándar de Firebase. Se ejecuta después de App Check.
    FirebaseApp.configure()
    
    return true
  }
}

@main
struct RondaAppApp: App {
    // Registramos nuestro AppDelegate para que SwiftUI lo utilice.
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            // RootView es el punto de entrada que decide qué pantalla mostrar.
            RootView()
        }
    }
}
