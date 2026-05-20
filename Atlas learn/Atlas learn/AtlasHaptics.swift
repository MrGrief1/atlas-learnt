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

    static func prepare() {
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
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
    }

    static func success() {
        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare()
    }

    static func warning() {
        notificationGenerator.notificationOccurred(.warning)
        notificationGenerator.prepare()
    }

    static func error() {
        notificationGenerator.notificationOccurred(.error)
        notificationGenerator.prepare()
    }

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
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
