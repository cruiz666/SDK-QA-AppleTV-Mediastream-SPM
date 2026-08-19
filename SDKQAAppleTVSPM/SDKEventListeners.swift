//
//  SDKEventListeners.swift
//  SDKQAAppleTVSPM
//
//  Se suscribe a todos los eventos que publica el SDK de Apple TV y los manda al EventLog.
//
//  La lista está completa a propósito, aunque un caso concreto solo dispare unos pocos: el
//  valor para QA es ver qué llega y qué no. Un evento ausente es tan reportable como uno
//  incorrecto.
//
//  No es la lista del SDK de iOS. Se enumeró desde las llamadas a `trigger(eventName:)` del
//  SDK de tvOS, que publica 34 eventos y difiere en cosas que importan: acá los de red se
//  llaman `connectionStablished` y `connectionLost` —en iOS les falta una n—, hay eventos de
//  ads más granulares (`onAdPlay`, `onAdPause`, `onAdResume`, `onAdEnded`, `onAdSkipped`),
//  existe `onError` además de `error`, y no hay nada de PiP, AirPlay ni CarPlay porque en
//  tvOS no aplican.
//

import Foundation
import MediastreamPlatformSDKAppleTV

enum SDKEventListeners {

    static func attachAll(to events: EventManager) {
        let log = EventLog.shared

        // Reproducción
        events.listenTo(eventName: "play") { log.record("play") }
        events.listenTo(eventName: "pause") { log.record("pause") }
        events.listenTo(eventName: "finish") { log.record("finish") }
        events.listenTo(eventName: "seek") { (info: Any?) in log.record("seek", info: info) }
        events.listenTo(eventName: "ready") { log.record("ready") }
        events.listenTo(eventName: "buffering") { (info: Any?) in log.record("buffering", info: info) }
        events.listenTo(eventName: "durationUpdated") { (info: Any?) in log.record("durationUpdated", info: info) }

        // Red
        events.listenTo(eventName: "connectionStablished") { log.record("connectionStablished") }
        events.listenTo(eventName: "connectionLost") { log.record("connectionLost") }

        // Ads
        events.listenTo(eventName: "onAdsLoaderInitialize") { log.record("onAdsLoaderInitialize") }
        events.listenTo(eventName: "onAdLoaded") { (info: Any?) in log.record("onAdLoaded", info: info) }
        events.listenTo(eventName: "onAdEvent") { (info: Any?) in log.record("onAdEvent", info: info) }
        events.listenTo(eventName: "onAdPlay") { log.record("onAdPlay") }
        events.listenTo(eventName: "onAdPause") { log.record("onAdPause") }
        events.listenTo(eventName: "onAdResume") { log.record("onAdResume") }
        events.listenTo(eventName: "onAdEnded") { (info: Any?) in log.record("onAdEnded", info: info) }
        events.listenTo(eventName: "onAdSkipped") { (info: Any?) in log.record("onAdSkipped", info: info) }
        events.listenTo(eventName: "onAdError") { (info: Any?) in log.record("onAdError", info: info) }
        events.listenTo(eventName: "onAdLoadingError") { (info: Any?) in log.record("onAdLoadingError", info: info) }
        events.listenTo(eventName: "onDAIAdEvent") { (info: Any?) in log.record("onDAIAdEvent", info: info) }

        // Fuentes y errores
        events.listenTo(eventName: "newsourceadded") { (info: Any?) in log.record("newsourceadded", info: info) }
        events.listenTo(eventName: "localsourceadded") { (info: Any?) in log.record("localsourceadded", info: info) }
        events.listenTo(eventName: "error") { (info: Any?) in log.record("error", info: info) }
        events.listenTo(eventName: "onError") { (info: Any?) in log.record("onError", info: info) }

        // UI
        events.listenTo(eventName: "onFullscreen") { log.record("onFullscreen") }
        events.listenTo(eventName: "offFullscreen") { log.record("offFullscreen") }
        events.listenTo(eventName: "onDismissButton") { log.record("onDismissButton") }
        events.listenTo(eventName: "onSDKRequestDismiss") { log.record("onSDKRequestDismiss") }
        events.listenTo(eventName: "onnextwidget") { (info: Any?) in log.record("onnextwidget", info: info) }
        events.listenTo(eventName: "onprevwidget") { (info: Any?) in log.record("onprevwidget", info: info) }

        // Episodios y audio en vivo
        events.listenTo(eventName: "nextEpisodeIncoming") { (info: Any?) in log.record("nextEpisodeIncoming", info: info) }
        events.listenTo(eventName: "nextEpisodeLoadRequested") { (info: Any?) in log.record("nextEpisodeLoadRequested", info: info) }
        events.listenTo(eventName: "onLiveAudioCurrentSongChanged") { (info: Any?) in log.record("onLiveAudioCurrentSongChanged", info: info) }

        // `currentTimeUpdate` se emite varias veces por segundo: en el log tapa todo lo
        // demás. Se deja comentado y se activa solo si un caso lo necesita.
        // events.listenTo(eventName: "currentTimeUpdate") { (info: Any?) in log.record("currentTimeUpdate", info: info) }
    }
}
