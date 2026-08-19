//
//  ControlVC.swift
//  SDKQAAppleTVSPM
//
//  Control de aislamiento: AVKit puro, sin una línea del SDK.
//
//  Reproduce el stream HLS de prueba de Apple con un `AVPlayerViewController` presentado a
//  pantalla completa. No sirve para probar el SDK; sirve para saber si el problema está
//  antes que el SDK. Si esto reproduce y el SDK no, la causa es nuestra. Si esto tampoco
//  reproduce, es el equipo o esa versión de tvOS y no hay nada que arreglar en el SDK.
//
//  Se activa con el argumento --applehls.
//

import UIKit
import AVKit
import AVFoundation

final class ControlVC: UIViewController {

    /// Stream público de Apple, HLS multivariante, H.264 + AAC-LC.
    private static let appleHLS =
        "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"

    private var observation: NSKeyValueObservation?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        // `--mdstrm <url>` para comparar el mismo camino con nuestro stream. El punto es
        // que la única variable que cambia entre las dos corridas es la URL.
        let args = ProcessInfo.processInfo.arguments
        let override = args.firstIndex(of: "--mdstrm").flatMap { i in
            i + 1 < args.count ? args[i + 1] : nil
        }
        let url = URL(string: override ?? Self.appleHLS)!
        print("CONTROL_URL \(url.absoluteString)")
        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)

        observation = item.observe(\.status, options: [.new, .initial]) { item, _ in
            let names = [".unknown", ".readyToPlay", ".failed"]
            let name = names.indices.contains(item.status.rawValue) ? names[item.status.rawValue] : "?"
            print("CONTROL_APPLE status=\(item.status.rawValue) (\(name)) "
                + "error=\(item.error?.localizedDescription ?? "none")")
        }

        let vc = AVPlayerViewController()
        vc.player = player
        addChild(vc)
        vc.view.frame = view.bounds
        vc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(vc.view)
        vc.didMove(toParent: self)

        player.play()

        for t in [5.0, 15.0, 30.0] {
            DispatchQueue.main.asyncAfter(deadline: .now() + t) {
                print("CONTROL_APPLE t=\(t) rate=\(player.rate) "
                    + "time=\(CMTimeGetSeconds(player.currentTime())) "
                    + "status=\(item.status.rawValue)")
            }
        }
    }
}
