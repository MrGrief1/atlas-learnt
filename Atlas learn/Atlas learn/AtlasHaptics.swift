//
//  AtlasHaptics.swift
//  Atlas learn
//

import SwiftUI
import UIKit

enum AtlasHaptics {
    static func tap() {
        impact(.light)
    }

    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

extension Animation {
    static var atlasSpring: Animation {
        .spring(response: 0.36, dampingFraction: 0.84)
    }

    static var atlasSoftSpring: Animation {
        .spring(response: 0.48, dampingFraction: 0.9)
    }
}

extension View {
    func atlasMotion<Value: Equatable>(_ value: Value) -> some View {
        animation(.atlasSpring, value: value)
    }

    func atlasSoftMotion<Value: Equatable>(_ value: Value) -> some View {
        animation(.atlasSoftSpring, value: value)
    }
}
