//
//  AppDelegate.swift
//  SDKQAAppleTVSPM
//
//  La ventana y la navegación viven en SceneDelegate: ver el comentario de ese archivo,
//  porque en tvOS 26 no adoptar UIScene es la diferencia entre reproducir y no reproducir.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let config = UISceneConfiguration(name: "Default", sessionRole: connectingSceneSession.role)
        config.delegateClass = SceneDelegate.self
        return config
    }
}
