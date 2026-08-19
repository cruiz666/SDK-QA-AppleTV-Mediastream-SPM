//
//  EventLog.swift
//  SDKQAAppleTVSPM
//
//  Registro de eventos del SDK, en pantalla.
//
//  La suite anterior los mandaba a la consola de Xcode. Para QA eso no sirve: la persona
//  que prueba no tiene Xcode abierto, y "el evento no llegó" es exactamente el tipo de
//  hallazgo que hay que poder reportar con evidencia. Acá se ven en el dispositivo y se
//  pueden copiar de un toque.
//

import Foundation

final class EventLog {

    static let shared = EventLog()

    struct Entry {
        let timestamp: Date
        let name: String
        let info: String?
    }

    private(set) var entries: [Entry] = []
    /// Se dispara en el hilo principal cada vez que entra un evento.
    var onChange: (() -> Void)?

    private let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f
    }()

    func record(_ name: String, info: Any? = nil) {
        let text: String?
        switch info {
        case nil:                 text = nil
        case let s as String:     text = s
        case let d as [String: Any]: text = d.isEmpty ? nil : "\(d)"
        default:                  text = "\(info!)"
        }

        let entry = Entry(timestamp: Date(), name: name, info: text)
        DispatchQueue.main.async {
            self.entries.append(entry)
            self.onChange?()
        }
        // Los dos canales a propósito. NSLog va al log unificado, que es donde lo busca
        // quien abre la consola de macOS; print va a stdout, que es lo único que captura
        // `devicectl --console` contra un Apple TV. Con uno solo, el log se ve en el
        // simulador y no en el dispositivo, o al revés.
        let line = "[SDK] \(name)\(text.map { " — \($0)" } ?? "")"
        NSLog("%@", line)
        print(line)
    }

    func clear() {
        entries.removeAll()
        onChange?()
    }

    /// Texto plano para compartir en un reporte de bug.
    var plainText: String {
        entries.map { e in
            "\(formatter.string(from: e.timestamp))  \(e.name)\(e.info.map { "  \($0)" } ?? "")"
        }.joined(separator: "\n")
    }

    func line(at index: Int) -> String {
        let e = entries[index]
        return "\(formatter.string(from: e.timestamp))  \(e.name)\(e.info.map { "  —  \($0)" } ?? "")"
    }
}
