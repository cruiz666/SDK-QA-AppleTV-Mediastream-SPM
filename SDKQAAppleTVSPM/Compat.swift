//
//  Compat.swift
//  SDKQAAppleTVSPM
//
//  Colores y tipografía de la app, en un solo lugar.
//

import UIKit

extension UIColor {
    static var qaBackground: UIColor { .black }
    static var qaSecondaryLabel: UIColor { .lightGray }
    /// Fondo del panel de eventos. Un gris muy oscuro y no negro puro, para que el panel se
    /// distinga del video sin competir con él.
    static var qaPanel: UIColor { UIColor(white: 0.08, alpha: 1.0) }
}

extension UIFont {
    /// Monoespaciada para el log: las marcas de tiempo se leen en columna.
    static func qaMono(_ size: CGFloat) -> UIFont {
        .monospacedSystemFont(ofSize: size, weight: .regular)
    }
}
