//
//  AtlasSpeech.swift
//  Atlas learn
//

import AVFoundation
import Foundation

@MainActor
enum AtlasSpeech {
    private static let synthesizer = AVSpeechSynthesizer()
    private static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: "atlas.speechEnabled") as? Bool ?? true
    }

    static func speak(_ text: String, voice: SpeechVoiceOption) {
        speak(text, language: voice.languageCode)
    }

    static func speak(_ text: String, language: String = "en-US") {
        guard isEnabled else { return }

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language) ?? AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.46
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        synthesizer.speak(utterance)
    }
}
