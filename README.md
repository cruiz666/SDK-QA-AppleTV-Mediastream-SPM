# SDK QA Apple TV — Swift Package Manager

App de QA del **Mediastream Platform SDK para Apple TV**, consumiéndolo desde su **nueva
distribución por Swift Package Manager**.

Es el equivalente de
[SDK-QA-AppleTV-Mediastream](https://github.com/cruiz666/SDK-QA-AppleTV-Mediastream), que
consume el SDK viejo por CocoaPods. Esta arranca con tres casos a propósito: la idea es que
QA la complemente con el resto de las casuísticas.

## Correrla

```bash
ruby project.rb          # genera el .xcodeproj
open SDKQAAppleTVSPM.xcodeproj
```

**No hay `pod install` ni workspace.** Xcode resuelve el SDK desde GitHub al abrir el
proyecto. Elegí un simulador de Apple TV o un dispositivo y corré.

El `.xcodeproj` **no está versionado**: se genera con `project.rb`. La razón es la misma que
en el repo del SDK — un `pbxproj` versionado convierte cada archivo agregado en un conflicto
entre ramas, y acá se van a agregar casos.

Requiere Xcode 15+ y tvOS 15 o superior. El piso de tvOS 15 no es una preferencia: lo exige
el paquete de IMA para tvOS desde 4.16.0.

## Qué trae

| Caso | Contenido |
|---|---|
| **VOD** | `6a5aa6b6bc4d1eb8a5da60c5` — tráiler de ~96 s, con preroll de IMA |
| **Live** | `6a50036532aaea1c582f160e` — RTMP Live |
| **VOD con UI custom** | El mismo VOD con `customUI = true` |

Los tres con `playerId` fijado a `6a7f45b004e80f98bf07f88a`, que es un player con **Youbora
habilitado**. Sin ese id se resuelve el player por defecto de la cuenta, y si ese no tiene
Youbora configurado el SDK no reporta analítica — cosa que no es evidente y cuesta un rato
descubrir.

El caso de **UI custom** merece una nota: es el que carga los nibs, el `Assets.car` y los
`.lproj` desde el bundle del framework. Con la migración a SPM esos recursos pasaron de un
bundle anidado a la raíz del `.framework`, así que ese caso es el que verifica que el cambio
no rompió nada. Si los recursos no resolvieran, se vería como controles en blanco o sin
texto.

## El registro de eventos

Cada caso abre una pantalla con el player a la izquierda y el **registro de eventos del SDK**
a la derecha, en vivo y con marca de tiempo.

El layout es lado a lado y no apilado como en la app de iOS porque la pantalla es 16:9
apaisada: un player arriba y una lista abajo desperdicia el ancho y deja el log en una franja
de pocas líneas.

**El panel de eventos no es enfocable, y eso es deliberado.** En tvOS quien tiene el foco
recibe el control remoto, así que una tabla enfocable al lado del player se lo roba: a partir
de ahí no se puede dar play, pausar ni navegar, y con `customUI` la UI del SDK no vuelve a
aparecer nunca. El log no necesita foco porque se auto-desplaza al último evento. El foco es
siempre del player.

Los casos con `customUI` se presentan **a pantalla completa**, sin el panel al costado: la UI
custom del SDK se ancla a los bordes de la vista del player, así que en un contenedor al 62%
del ancho queda apretada y no se comporta como en una app real. Se marca con
`fullscreen: true` en el caso.

Se escuchan **todos** los eventos que publica el SDK de tvOS, aunque un caso concreto dispare
solo unos pocos: un evento ausente es tan reportable como uno incorrecto. La excepción es
`currentTimeUpdate`, que se emite varias veces por segundo y tapa el resto; está comentado en
`SDKEventListeners.swift` y se activa si hace falta.

La lista **no es la del SDK de iOS**. Se enumeró desde el propio SDK de tvOS, que publica 34
eventos y difiere en cosas que importan: acá los de red se llaman `connectionStablished` y
`connectionLost` —en iOS les falta una n—, hay eventos de ads más granulares (`onAdPlay`,
`onAdPause`, `onAdResume`, `onAdEnded`, `onAdSkipped`), existe `onError` además de `error`, y
no hay nada de PiP, AirPlay ni CarPlay porque en tvOS no aplican.

Los eventos salen además por consola, por dos canales: `NSLog` para el log unificado de macOS
y `print` para stdout, que es lo único que captura `devicectl --console` contra un Apple TV
real. Con uno solo, el log se ve en el simulador y no en el dispositivo, o al revés.

## Agregar un caso

Un caso es un dato, no un ViewController. Se agrega una entrada a `TestCase.all` y aparece
solo en la lista:

```swift
TestCase(title: "VOD con DVR",
         detail: "Ventana de DVR sobre VOD",
         category: .video) { config in
    base(config)
    config.id = Media.vod
    config.type = .VOD
    config.dvr = true
},
```

No hay que crear archivos ni tocar la navegación. Después de agregarlo, `ruby project.rb`
solo si creaste un archivo nuevo. Si un caso necesita algo que no se puede expresar
configurando el `config` —por ejemplo manipular el player después del `setup`, o probar
`reloadPlayer`— ahí sí conviene un ViewController propio.

Para una categoría nueva, agregar el `case` a `TestCase.Category` y la lista se reorganiza
sola.

## Modo pantalla completa

```bash
xcrun devicectl device process launch --device <dev> am.mediastre.SDKQAAppleTVSPM --case 0 --fullscreen
```

Saca el panel de eventos y deja el player ocupando toda la pantalla. Existe porque en tvOS
`AVPlayerViewController` —que es lo que el SDK usa por dentro— está pensado para pantalla
completa, así que sirve para separar "el SDK no reproduce" de "el layout no le sirve al
player". En las pruebas de la migración quedó descartado que el layout fuera el problema:
con el player a `(0, 0, 1920, 1080)` el resultado es el mismo. Ver las limitaciones más
abajo para lo que sí resultó ser.

## Abrir un caso sin control remoto

```bash
xcrun simctl launch <sim> am.mediastre.SDKQAAppleTVSPM --case 0
```

El índice es la posición en `TestCase.all`. Sirve para verificar un caso de forma
desatendida, y para que un reporte de bug diga exactamente cómo reproducirlo en un comando.

## Qué versión del SDK usa

Está fijada a **`2.1.0-dev.2`**, un build del canal de desarrollo. La versión que la app
muestra al pie de la lista y en cada caso sale de `getVersion()`, que la lee del bundle del
framework — no de una constante — así que siempre corresponde al binario que se está
probando. Eso vale al reportar: el número es verificable, no de memoria.

Para cambiarla, en Xcode: **Package Dependencies → MediastreamPlatformSDKAppleTV-spm →
Version**, o editando `project.rb`.

| Cuándo | Qué poner |
|---|---|
| Validar un build de desarrollo puntual | `Exact` `2.1.0-dev.N` |
| Seguir siempre el último de desarrollo | `Branch` `develop` |
| Validar un candidato a producción | `Exact` `2.2.0-rc.N` |
| Producción | `Up to Next Major` desde `2.1.0` |

Cuando 2.1.0 se publique a producción, conviene mover esta app a `Up to Next Major`.

## Limitaciones conocidas del entorno

- **Simulador de tvOS:** el VOD reproduce el preroll de IMA y los eventos llegan, pero el
  contenido principal puede fallar con `CoreMediaErrorDomain -66681`, porque el simulador no
  decodifica HE-AAC (`mp4a.40.5`), que es el audio que sirve el CDN.
- **tvOS 26 (corregido en `2.1.0-dev.2`).** Hasta esa versión el SDK no reproducía en
  tvOS 26: pantalla negra, sin un evento ni un error. Desde tvOS 26, un `AVPlayerItem` cuyo
  `AVPlayer` no tiene una salida adjunta a la jerarquía de vistas nunca sale de `.unknown`,
  y el SDK creaba el `AVPlayerViewController` recién al recibir `.readyToPlay`: le pedía al
  item que cargara sin darle nunca una pantalla.

  No lo introdujo la migración. El código anterior a ella falla igual en tvOS 26.6 y
  funciona en tvOS 17.2: la variable es la versión del sistema.

  Verificado en un Apple TV 4K con tvOS 26.6 consumiendo `2.1.0-dev.2` desde el paquete:
  reproduce contenido y ads (`onAdsLoaderInitialize`, `onAdLoaded`, `onAdPlay`, `onAdEnded`).

  `ControlVC` (`--applehls`) quedó como herramienta: reproduce un HLS con AVKit puro y la
  vista adjunta, sin nada del SDK. Es lo que permite descartar dispositivo, versión de tvOS,
  red y stream antes de sospechar del SDK.

- **Simulador de tvOS:** el VOD reproduce el preroll de IMA, pero el contenido principal
  puede fallar con `CoreMediaErrorDomain -66681` porque el simulador no decodifica HE-AAC
  (`mp4a.40.5`), que es el audio que sirve el CDN. En dispositivo no pasa.

## Documentación del SDK

Todo público, no hace falta acceso al repo privado del SDK:

- [Guía de instalación e integración](https://github.com/mediastream/MediastreamPlatformSDKAppleTV-spm#readme)
  — instalación, rangos de dependencias, canales de pre-release y tabla de compatibilidad.

## Chromecast

No aplica. Un Apple TV es un *receptor* de Cast, no un emisor, y el SDK emisor de Google no
se distribuye para tvOS.
