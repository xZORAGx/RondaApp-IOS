//
//  CustomTextFieldModifier.swift
//  RondaApp
//
//  Created by David Roger Alvarez on 13/7/25.
//

// Fichero: RondaApp/Shared/Views/Modifiers/CustomTextFieldModifier.swift

import SwiftUI

struct CustomTextFieldModifier: ViewModifier {
    let icon: String? // Lo hacemos opcional para que funcione en ambas vistas

    func body(content: Content) -> some View {
        HStack {
            if let iconName = icon {
                Image(systemName: iconName)
                    .foregroundColor(.secondary)
            }
            content
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3, y: 1)
    }
}
