//
//  LiquidGlassStyle.swift
//  Tech.AI
//
//  Liquid Glass styling helpers with graceful fallback to Materials.
//  The project's deployment target (iOS 18.2) predates Liquid Glass
//  (iOS 26), so every glass API is gated behind #available and falls
//  back to a Material treatment on older systems.
//

import SwiftUI

extension View {

    // A capsule input surface: Liquid Glass where available, otherwise
    // an ultra-thin material capsule.
    @ViewBuilder
    func inputSurface() -> some View {
        if #available(iOS 26, *) {
            self.glassEffect(in: .capsule)
        } else {
            self.background(.ultraThinMaterial, in: Capsule())
        }
    }

    // Secondary glass button (voice, clear). Falls back to `.bordered`.
    @ViewBuilder
    func glassButtonStyle(tint: Color) -> some View {
        if #available(iOS 26, *) {
            self.buttonStyle(.glass).tint(tint)
        } else {
            self.buttonStyle(.bordered).tint(tint)
        }
    }

    // Prominent glass button for the primary action (send). Falls back
    // to `.borderedProminent`.
    @ViewBuilder
    func prominentGlassButtonStyle(tint: Color) -> some View {
        if #available(iOS 26, *) {
            self.buttonStyle(.glassProminent).tint(tint)
        } else {
            self.buttonStyle(.borderedProminent).tint(tint)
        }
    }
}
