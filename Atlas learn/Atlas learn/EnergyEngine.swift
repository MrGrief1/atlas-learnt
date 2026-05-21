//
//  EnergyEngine.swift
//  Atlas learn
//

import Foundation

enum EnergyEngine {
    static let maxEnergy = 25

    static func clamped(_ value: Int) -> Int {
        min(max(value, 0), maxEnergy)
    }

    static func lessonStartEnergy(from currentEnergy: Int) -> Int {
        clamped(currentEnergy - 1)
    }

    static func delta(isCorrect: Bool, didNotKnow: Bool, comboAfterAnswer: Int) -> Int {
        if didNotKnow {
            return 0
        }

        if isCorrect {
            return comboAfterAnswer > 0 && comboAfterAnswer.isMultiple(of: 3) ? 1 : 0
        }

        return -1
    }
}

