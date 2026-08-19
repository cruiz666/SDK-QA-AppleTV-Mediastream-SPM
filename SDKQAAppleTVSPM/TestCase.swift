//
//  TestCase.swift
//  SDKQAAppleTVSPM
//
//  Catálogo de casos de prueba.
//
//  Un caso es un dato: título, categoría y un closure que configura el player. Agregar un
//  caso nuevo es agregar una entrada a `all` — no hay que crear archivos ni tocar la
//  navegación. Cuando un caso necesite algo que no se pueda expresar configurando el
//  config (por ejemplo manipular el player después del setup, o probar un reload), ahí sí
//  conviene un ViewController propio.
//

import Foundation
import MediastreamPlatformSDKAppleTV

struct TestCase {

    enum Category: String, CaseIterable {
        case video = "Video"
    }

    let title: String
    let detail: String
    let category: Category
    /// Se ejecuta sobre un `MediastreamPlayerConfig` nuevo antes del `setup`.
    let configure: (MediastreamPlayerConfig) -> Void

    // MARK: - Contenido

    private enum Media {
        static let vod = "6a5aa6b6bc4d1eb8a5da60c5"
        static let live = "6a50036532aaea1c582f160e"

        /// Youbora se habilita en la configuración del *player*, no del media. Sin este id
        /// se resuelve el player por defecto de la cuenta, y si ese no tiene Youbora
        /// configurado la API devuelve `enabled: false` y el SDK no reporta nada.
        /// Este player reporta a la cuenta `caracoltvdev`.
        static let playerId = "6a7f45b004e80f98bf07f88a"
    }

    /// Base común a todos los casos. Un caso puede sobrescribir lo que necesite.
    private static func base(_ config: MediastreamPlayerConfig) {
        config.playerId = Media.playerId
        config.appName = "SDKQAAppleTVSPM"
        config.appVersion = "1.0.0"
        config.debug = true
        config.autoplay = true
        config.showControls = true
    }

    // MARK: - Catálogo

    static let all: [TestCase] = [

        TestCase(title: "VOD",
                 detail: "Video on demand, controles nativos",
                 category: .video) { config in
            base(config)
            config.id = Media.vod
            config.type = .VOD
        },

        TestCase(title: "Live",
                 detail: "Transmisión en vivo, controles nativos",
                 category: .video) { config in
            base(config)
            config.id = Media.live
            config.type = .LIVE
        },

        // La UI custom es la que carga los nibs, el Assets.car y los .lproj del framework.
        // Con la migración a SPM esos recursos pasaron de un bundle anidado a la raíz del
        // .framework, así que este caso es el que verifica que ese cambio no rompió nada:
        // si los recursos no resuelven, acá se ve como controles en blanco o sin texto.
        TestCase(title: "VOD con UI custom",
                 detail: "Ejercita nibs, imágenes y traducciones del framework",
                 category: .video) { config in
            base(config)
            config.id = Media.vod
            config.type = .VOD
            config.customUI = true
        },
    ]

    static func cases(in category: Category) -> [TestCase] {
        all.filter { $0.category == category }
    }
}
