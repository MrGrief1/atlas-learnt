//
//  AtlasSpeechRecognition.swift
//  Atlas learn
//

import AVFoundation
import Combine
import Foundation
import Speech

enum AtlasSpeechRecognitionState: Equatable {
    case idle
    case requestingPermission
    case recording
    case recognized
    case denied
    case unavailable
    case failed(String)
}

@MainActor
final class AtlasSpeechRecognition: ObservableObject {
    @Published private(set) var state: AtlasSpeechRecognitionState = .idle
    @Published private(set) var transcript = ""

    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var stopTask: Task<Void, Never>?
    private var hasInputTap = false

    var canSkip: Bool {
        switch state {
        case .denied, .unavailable, .failed:
            true
        case .idle, .requestingPermission, .recording, .recognized:
            false
        }
    }

    func startRecording(localeIdentifier: String = "en-US", duration: TimeInterval = 3.4) {
        stopRecording(keepTranscript: false)
        transcript = ""
        state = .requestingPermission

        Task {
            let speechAllowed = await Self.requestSpeechAuthorization()
            let micAllowed = await Self.requestMicrophoneAuthorization()

            guard speechAllowed, micAllowed else {
                state = .denied
                return
            }

            beginRecording(localeIdentifier: localeIdentifier, duration: duration)
        }
    }

    func stopRecording(keepTranscript: Bool = true) {
        stopTask?.cancel()
        stopTask = nil

        if audioEngine.isRunning {
            audioEngine.stop()
        }

        if hasInputTap {
            audioEngine.inputNode.removeTap(onBus: 0)
            hasInputTap = false
        }

        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil

        if !keepTranscript {
            transcript = ""
            state = .idle
        } else if !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            state = .recognized
        } else if state == .recording || state == .requestingPermission {
            state = .idle
        }

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func reset() {
        stopRecording(keepTranscript: false)
    }

    private func beginRecording(localeIdentifier: String, duration: TimeInterval) {
        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: localeIdentifier))
        guard let recognizer, recognizer.isAvailable else {
            state = .unavailable
            return
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: [.duckOthers])
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let inputNode = audioEngine.inputNode
            let format = inputNode.outputFormat(forBus: 0)
            if hasInputTap {
                inputNode.removeTap(onBus: 0)
            }
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak request] buffer, _ in
                request?.append(buffer)
            }
            hasInputTap = true

            recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
                Task { @MainActor in
                    guard let self else { return }

                    if let result {
                        self.transcript = result.bestTranscription.formattedString
                        if result.isFinal {
                            self.state = .recognized
                        }
                    }

                    if let error, self.transcript.isEmpty {
                        self.state = .failed(error.localizedDescription)
                        self.stopRecording(keepTranscript: true)
                    }
                }
            }

            audioEngine.prepare()
            try audioEngine.start()
            state = .recording

            stopTask = Task { [weak self] in
                let nanoseconds = UInt64(duration * 1_000_000_000)
                try? await Task.sleep(nanoseconds: nanoseconds)
                self?.stopRecording(keepTranscript: true)
            }
        } catch {
            state = .failed(error.localizedDescription)
            stopRecording(keepTranscript: true)
        }
    }

    private static func requestSpeechAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    private static func requestMicrophoneAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            if #available(iOS 17.0, *) {
                AVAudioApplication.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            } else {
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
    }
}
