// Fichero: AnimatedScoreView.swift

import SwiftUI

struct AnimatedScoreView: View {
    let score: Int

    var body: some View {
        Text("\(score)")
            .font(.system(size: 36, weight: .heavy, design: .rounded))
            .foregroundColor(.white)
            // ✅ LA SOLUCIÓN ESTABLE: Reemplazamos .contentTransition por una transición que no falla.
            .transition(.asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity),
                removal: .move(edge: .top).combined(with: .opacity)
            ))
            .id(score) // El .id() sigue siendo FUNDAMENTAL para que la animación se active.
    }
}
