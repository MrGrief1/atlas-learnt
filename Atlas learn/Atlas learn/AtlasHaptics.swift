//
//  AtlasHaptics.swift
//  Atlas learn
//

import SwiftUI
import UIKit

enum AtlasHaptics {
    private static let lightImpactGenerator = UIImpactFeedbackGenerator(style: .light)
    private static let mediumImpactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private static let softImpactGenerator = UIImpactFeedbackGenerator(style: .soft)
    private static let selectionGenerator = UISelectionFeedbackGenerator()
    private static let notificationGenerator = UINotificationFeedbackGenerator()
    private static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: "atlas.hapticsEnabled") as? Bool ?? true
    }

    static func prepare() {
        guard isEnabled else { return }

        lightImpactGenerator.prepare()
        mediumImpactGenerator.prepare()
        softImpactGenerator.prepare()
        selectionGenerator.prepare()
        notificationGenerator.prepare()
    }

    static func tap() {
        impact(.light)
    }

    static func selection() {
        guard isEnabled else { return }

        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
    }

    static func success() {
        guard isEnabled else { return }

        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare()
    }

    static func warning() {
        guard isEnabled else { return }

        notificationGenerator.notificationOccurred(.warning)
        notificationGenerator.prepare()
    }

    static func error() {
        guard isEnabled else { return }

        notificationGenerator.notificationOccurred(.error)
        notificationGenerator.prepare()
    }

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        guard isEnabled else { return }

        let generator: UIImpactFeedbackGenerator

        switch style {
        case .light:
            generator = lightImpactGenerator
        case .soft:
            generator = softImpactGenerator
        default:
            generator = mediumImpactGenerator
        }

        generator.impactOccurred()
        generator.prepare()
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
