//
//  Color.swift
//  RondaApp
//
//  Created by David Roger Alvarez on 22/7/25.
//

// Fichero: RondaApp/Core/Utils/Color+Extensions.swift

import SwiftUI

// Esta extensión le enseña a SwiftUI cómo entender códigos de color hexadecimales (hex)
extension Color {
    init?(hex: String) {
        let r, g, b: Double
        let start = hex.hasPrefix("#") ? hex.index(hex.startIndex, offsetBy: 1) : hex.startIndex
        let hexColor = String(hex[start...])

        if hexColor.count == 6 {
            let scanner = Scanner(string: hexColor)
            var hexNumber: UInt64 = 0

            if scanner.scanHexInt64(&hexNumber) {
                r = Double((hexNumber & 0xff0000) >> 16) / 255
                g = Double((hexNumber & 0x00ff00) >> 8) / 255
                b = Double(hexNumber & 0x0000ff) / 255
                self.init(red: r, green: g, blue: b)
                return
            }
        }
        return nil
    }
}
