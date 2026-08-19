//
//  AppDelegate.swift
//  SDKQAAppleTVSPM
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        let nav = UINavigationController(rootViewController: ViewController())
        window?.rootViewController = nav

        // Abrir un caso directo, sin control remoto: `--case <indice>`.
        //
        // Existe para poder verificar un caso de forma desatendida —desde un script, o en
        // un simulador donde no hay con qué navegar— y para que un reporte de bug pueda
        // decir exactamente cómo reproducirlo en un comando.
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "--case"),
           i + 1 < args.count,
           let index = Int(args[i + 1]),
           TestCase.all.indices.contains(index) {
            nav.pushViewController(PlayerViewController(testCase: TestCase.all[index]), animated: false)
        }
        window?.makeKeyAndVisible()
        return true
    }
}
