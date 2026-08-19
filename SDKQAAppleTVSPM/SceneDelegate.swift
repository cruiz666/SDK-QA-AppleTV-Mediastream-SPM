//
//  SceneDelegate.swift
//  SDKQAAppleTVSPM
//
//  Ciclo de vida por UIScene.
//
//  No es cosmético ni preparación para el futuro: en tvOS 26 una app que no adopta UIScene
//  no reproduce. AVFoundation consulta el estado de la aplicación a través de
//  FigApplicationStateMonitor para decidir si puede cargar media, y sin escenas no logra
//  confirmar que la app esté activa en primer plano. El síntoma es brutal por lo silencioso:
//  el AVPlayerItem se queda en `.unknown` para siempre, sin error, así que la pantalla queda
//  negra y no se dispara ni un evento. En el log aparecen las dos pistas juntas:
//
//    `UIScene` lifecycle will soon be required. Failure to adopt will result in an assert...
//    <<<< FigApplicationStateMonitor >>>> signalled err=-19431
//

import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        let nav = UINavigationController(rootViewController: ViewController())
        window.rootViewController = nav
        window.makeKeyAndVisible()
        self.window = window

        // Abrir un caso directo, sin control remoto: `--case <indice>`.
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "--case"),
           i + 1 < args.count,
           let index = Int(args[i + 1]),
           TestCase.all.indices.contains(index) {
            nav.pushViewController(PlayerViewController(testCase: TestCase.all[index]), animated: false)
        }
    }
}
