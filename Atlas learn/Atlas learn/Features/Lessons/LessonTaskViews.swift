//
//  LessonTaskViews.swift
//  Atlas learn
//

import SwiftUI

struct LessonFeedbackState: Equatable {
    let isCorrect: Bool
    let didNotKnow: Bool
    let title: String
    let detail: String
    let correctAnswer: String
    let xp: Int
}

struct LessonPlayerHeader: View {
    let language: AppLanguage
    let mode: LessonMode
    let progress: Double
    let energy: Int
    let xp: Int
    let combo: Int
    let questionPosition: Int
    let questionCount: Int
    let dismiss: () -> Void

    var body: some View {
        VStack(spacing: 11) {
            HStack(spacing: 12) {
                Button {
                    AtlasHaptics.tap()
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(.black)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(.white.opacity(0.82)))
                        .overlay(Circle().stroke(.black.opacity(0.86), lineWidth: 2))
                }
                .buttonStyle(.plain)

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.black.opacity(0.1))

                        Capsule()
                            .fill(LinearGradient(colors: [AtlasColors.green, AtlasColors.mint], startPoint: .leading, endPoint: .trailing))
                            .frame(width: proxy.size.width * min(max(progress, 0), 1))
                    }
                }
                .frame(height: 12)

                CapsuleMetric(icon: "bolt.heart.fill", title: "\(energy)")
                    .frame(width: 78)
            }

            HStack(spacing: 8) {
                CapsuleMetric(icon: mode.icon, title: mode.title(for: language))
                CapsuleMetric(icon: "bolt.fill", title: "+\(xp) XP")
                CapsuleMetric(icon: "flame.fill", title: "\(combo)")
                Spacer()
                Text("\(questionPosition)/\(max(questionCount, 1))")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(.black.opacity(0.58))
            }
        }
        .foregroundStyle(.black)
        .padding(.horizontal, AtlasLayout.screenPadding)
        .padding(.top, 12)
        .padding(.bottom, 7)
    }
}

struct LessonTaskRail: View {
    let tasks: [LessonTask]
    let currentIndex: Int

    var body: some View {
        HStack(spacing: 7) {
            ForEach(Array(tasks.prefix(12).enumerated()), id: \.element.id) { index, task in
                let isActive = index == min(currentIndex, 11)
                let isDone = index < currentIndex

                Image(systemName: task.type.icon)
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(isActive ? .white : .black.opacity(isDone ? 0.72 : 0.36))
                    .frame(maxWidth: .infinity)
                    .frame(height: 30)
                    .background(isActive ? AtlasColors.ink : (isDone ? AtlasColors.mint.opacity(0.58) : Color.white.opacity(0.62)))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(.black.opacity(isActive ? 0.84 : 0.18), lineWidth: 1.4)
                    )
            }
        }
    }
}

struct LessonIntroCardView: View {
    let task: LessonTask
    let word: WordEntry
    let language: AppLanguage
    let playAction: () -> Void

    private var contextLines: [String] {
        (task.context ?? "")
            .split(separator: "\n")
            .map(String.init)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            LessonExerciseTitle(title: task.type.title(for: language), subtitle: language.text(ru: "Сначала пойми слово, потом будем проверять.", en: "Understand the word first, then we will test it."))

            HStack(alignment: .top, spacing: 13) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(word.english)
                        .font(.system(size: word.english.count > 13 ? 34 : 42, weight: .black, design: .serif))
                        .lineLimit(1)
                        .minimumScaleFactor(0.58)

                    Text("\(word.russian) · \(word.ipa)")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(.black.opacity(0.65))
                }

                Spacer()

                Button(action: playAction) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(.black)
                        .frame(width: 54, height: 54)
                        .background(Circle().fill(.white))
                        .overlay(Circle().stroke(.black, lineWidth: 2))
                        .shadow(color: .black.opacity(0.34), radius: 0, y: 4)
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 9) {
                ForEach(Array(contextLines.prefix(5).enumerated()), id: \.offset) { index, line in
                    Text(line)
                        .font(.system(size: index < 2 ? 15 : 14, weight: index < 2 ? .black : .semibold, design: .rounded))
                        .foregroundStyle(index < 2 ? .black : .black.opacity(0.68))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .lineSpacing(4)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.82))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.black.opacity(0.18), lineWidth: 1.4)
            )
        }
        .lessonPlayerSurface()
    }
}

struct LessonChoiceTaskView: View {
    let task: LessonTask
    let language: AppLanguage
    let selectedChoice: String?
    let isLocked: Bool
    let playAction: (() -> Void)?
    let choose: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            LessonExerciseTitle(title: task.type.title(for: language), subtitle: task.prompt)

            if let playAction {
                LessonPlayButton(title: language.text(ru: "Прослушать", en: "Listen"), subtitle: task.context ?? "", action: playAction)
            } else if let context = task.context, !context.isEmpty {
                Text(context)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.black.opacity(0.62))
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 10) {
                ForEach(task.options, id: \.self) { choice in
                    LessonChoiceRow(
                        choice: choice,
                        correctAnswer: task.correctAnswer,
                        selectedChoice: selectedChoice,
                        isLocked: isLocked
                    ) {
                        choose(choice)
                    }
                }
            }
        }
        .lessonPlayerSurface()
    }
}

struct LessonTileTaskView: View {
    let task: LessonTask
    let language: AppLanguage
    let selectedTiles: [String]
    let remainingTiles: [String]
    let isLocked: Bool
    let playAction: (() -> Void)?
    let chooseTile: (String, Int) -> Void
    let removeTile: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            LessonExerciseTitle(title: task.type.title(for: language), subtitle: task.prompt)

            if let playAction {
                LessonPlayButton(title: "Play", subtitle: task.context ?? "", action: playAction)
            } else if let context = task.context {
                Text(context)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.black.opacity(0.58))
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 10) {
                if selectedTiles.isEmpty {
                    Text(language.text(ru: "Нажимай плитки", en: "Tap tiles"))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.black.opacity(0.38))
                        .frame(maxWidth: .infinity, minHeight: 82, alignment: .topLeading)
                } else {
                    LessonIndexedTileWrap(items: selectedTiles) { index, tile in
                        LessonTileButton(title: tile, fill: AtlasColors.mint.opacity(0.52)) {
                            removeTile(index)
                        }
                        .disabled(isLocked)
                    }
                    .frame(maxWidth: .infinity, minHeight: 82, alignment: .topLeading)
                }
            }
            .padding(13)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(AtlasColors.line, lineWidth: 2)
            )

            LessonIndexedTileWrap(items: remainingTiles) { index, tile in
                LessonTileButton(title: tile, fill: .white) {
                    chooseTile(tile, index)
                }
                .disabled(isLocked)
            }
        }
        .lessonPlayerSurface()
    }
}

struct LessonInputTaskView: View {
    let task: LessonTask
    let language: AppLanguage
    @Binding var answer: String
    let isLocked: Bool
    let playAction: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            LessonExerciseTitle(title: task.type.title(for: language), subtitle: task.prompt)

            if let playAction {
                LessonPlayButton(title: language.text(ru: "Прослушать", en: "Listen"), subtitle: task.context ?? "", action: playAction)
            } else if let context = task.context {
                Text(context)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.black.opacity(0.62))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AtlasColors.mint.opacity(0.28))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(.black.opacity(0.28), lineWidth: 1.5)
                    )
            }

            TextField(language.text(ru: "Ответ", en: "Answer"), text: $answer, axis: .vertical)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .lineLimit(task.type == .sentenceWriting ? 2...4 : 1...2)
                .padding(14)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(AtlasColors.line, lineWidth: 2)
                )
                .disabled(isLocked)
        }
        .lessonPlayerSurface()
    }
}

struct LessonSpeechTaskView: View {
    let task: LessonTask
    let word: WordEntry
    let language: AppLanguage
    @ObservedObject var speech: AtlasSpeechRecognition
    let isLocked: Bool
    let playAction: () -> Void
    let recordAction: () -> Void
    let stopAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            LessonExerciseTitle(title: task.type.title(for: language), subtitle: task.prompt)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(task.correctAnswer)
                        .font(.system(size: task.correctAnswer.count > 16 ? 30 : 40, weight: .black, design: .serif))
                        .lineLimit(1)
                        .minimumScaleFactor(0.58)

                    Text(task.context ?? word.exampleEN)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.black.opacity(0.58))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Button(action: playAction) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(.black)
                        .frame(width: 46, height: 46)
                        .background(Circle().fill(.white))
                        .overlay(Circle().stroke(AtlasColors.line, lineWidth: 2))
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .background(AtlasColors.mint.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(.black.opacity(0.36), lineWidth: 1.6)
            )

            Button(action: speech.state == .recording ? stopAction : recordAction) {
                HStack(spacing: 11) {
                    Image(systemName: speech.state == .recording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 31, weight: .black))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(buttonTitle)
                            .font(.system(size: 18, weight: .black, design: .rounded))
                        Text(statusText)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(.black.opacity(0.62))
                            .lineLimit(2)
                    }

                    Spacer()
                }
                .foregroundStyle(.black)
                .padding(14)
                .background(buttonFill)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(AtlasColors.line, lineWidth: 2)
                )
                .shadow(color: .black.opacity(speech.state == .recording ? 0.55 : 0.32), radius: 0, y: 4)
            }
            .buttonStyle(.plain)
            .disabled(isLocked || speech.state == .requestingPermission)

            VStack(alignment: .leading, spacing: 6) {
                Text(language.text(ru: "Распознано", en: "Transcript"))
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(.black.opacity(0.48))

                Text(speech.transcript.isEmpty ? language.text(ru: "Здесь появится то, что услышит iPhone.", en: "What iPhone hears will appear here.") : speech.transcript)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(speech.transcript.isEmpty ? .black.opacity(0.4) : .black)
                    .frame(maxWidth: .infinity, minHeight: 54, alignment: .topLeading)
            }
            .padding(13)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.black.opacity(0.2), lineWidth: 1.4)
            )
        }
        .lessonPlayerSurface()
    }

    private var buttonTitle: String {
        switch speech.state {
        case .recording:
            language.text(ru: "Остановить запись", en: "Stop recording")
        case .requestingPermission:
            language.text(ru: "Запрашиваю доступ", en: "Requesting access")
        case .denied, .unavailable, .failed:
            language.text(ru: "Записать не вышло", en: "Recording unavailable")
        case .recognized:
            language.text(ru: "Записать заново", en: "Record again")
        case .idle:
            language.text(ru: "Начать запись", en: "Start recording")
        }
    }

    private var statusText: String {
        switch speech.state {
        case .idle:
            language.text(ru: "Запись короткая: около трех секунд.", en: "A short recording: about three seconds.")
        case .requestingPermission:
            language.text(ru: "Нужны микрофон и распознавание речи.", en: "Microphone and speech recognition are needed.")
        case .recording:
            language.text(ru: "Говори сейчас.", en: "Speak now.")
        case .recognized:
            language.text(ru: "Проверь распознанный текст ниже.", en: "Check the transcript below.")
        case .denied:
            language.text(ru: "Доступ запрещен в настройках.", en: "Access is denied in Settings.")
        case .unavailable:
            language.text(ru: "Распознавание сейчас недоступно.", en: "Speech recognition is unavailable right now.")
        case .failed(let message):
            message
        }
    }

    private var buttonFill: Color {
        switch speech.state {
        case .recording:
            AtlasColors.coral.opacity(0.32)
        case .denied, .unavailable, .failed:
            Color.white.opacity(0.58)
        case .idle, .requestingPermission, .recognized:
            AtlasColors.mint.opacity(0.42)
        }
    }
}

struct LessonActionPanel: View {
    let language: AppLanguage
    let task: LessonTask
    let canSubmit: Bool
    let canResetTiles: Bool
    let resetAction: () -> Void
    let dontKnowAction: () -> Void
    let submitAction: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            if canResetTiles {
                Button(action: resetAction) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(.black)
                        .frame(width: 50, height: 50)
                        .background(Circle().fill(.white))
                        .overlay(Circle().stroke(AtlasColors.line, lineWidth: 2))
                }
                .buttonStyle(.plain)
            }

            if task.type != .introCard {
                Button(action: dontKnowAction) {
                    Text(language.text(ru: "Я не знаю", en: "I don't know"))
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(.black)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .frame(width: 96, height: 50)
                        .background(Color.white.opacity(0.78))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(AtlasColors.line, lineWidth: 2)
                        )
                }
                .buttonStyle(.plain)
            }

            Button(action: submitAction) {
                HStack(spacing: 9) {
                    Image(systemName: canSubmit ? "checkmark.circle.fill" : "hand.tap")
                        .font(.system(size: 17, weight: .black))
                    Text(buttonTitle)
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.76)
                }
                .foregroundStyle(canSubmit ? .white : .black.opacity(0.46))
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(canSubmit ? AtlasColors.ink : Color.white.opacity(0.58))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(canSubmit ? .black : .black.opacity(0.18), lineWidth: 2)
                )
            }
            .buttonStyle(.plain)
            .disabled(!canSubmit)
        }
        .padding(.horizontal, AtlasLayout.screenPadding)
        .padding(.vertical, 14)
    }

    private var buttonTitle: String {
        switch task.type {
        case .introCard:
            language.text(ru: "Понятно", en: "Got it")
        case .meaningChoice, .contextChoice, .clozeChoice, .audioChoice, .matchingPairs, .dialogueChoice:
            language.text(ru: "Выбери вариант выше", en: "Choose an option above")
        case .speechRepeat:
            language.text(ru: "Проверить речь", en: "Check speech")
        default:
            language.text(ru: "Проверить", en: "Check")
        }
    }
}

struct LessonFeedbackPanel: View {
    let feedback: LessonFeedbackState
    let language: AppLanguage
    let continueAction: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 11) {
                Image(systemName: icon)
                    .font(.system(size: 25, weight: .black))
                    .foregroundStyle(color)

                VStack(alignment: .leading, spacing: 3) {
                    Text(feedback.title)
                        .font(.system(size: 18, weight: .black, design: .rounded))
                    Text(feedback.detail)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.black.opacity(0.68))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            Button(action: continueAction) {
                Text(language.text(ru: "Продолжить", en: "Continue"))
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(feedback.isCorrect ? AtlasColors.green : AtlasColors.ink)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(.black)
        .padding(.horizontal, AtlasLayout.screenPadding)
        .padding(.vertical, 14)
    }

    private var icon: String {
        if feedback.didNotKnow { return "lightbulb.fill" }
        return feedback.isCorrect ? "checkmark.seal.fill" : "xmark.octagon.fill"
    }

    private var color: Color {
        if feedback.didNotKnow { return AtlasColors.ink }
        return feedback.isCorrect ? AtlasColors.green : AtlasColors.coral
    }
}

private struct LessonExerciseTitle: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 20, weight: .black, design: .rounded))
            Text(subtitle)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.black.opacity(0.62))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct LessonPlayButton: View {
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 36, weight: .black))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 18, weight: .black, design: .rounded))
                    Text(subtitle)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.black.opacity(0.6))
                        .lineLimit(1)
                }

                Spacer()
            }
            .foregroundStyle(.black)
            .padding(13)
            .background(AtlasColors.coral.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 19, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 19, style: .continuous)
                    .stroke(AtlasColors.line, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct LessonChoiceRow: View {
    let choice: String
    let correctAnswer: String
    let selectedChoice: String?
    let isLocked: Bool
    let choose: () -> Void

    private var isSelected: Bool {
        selectedChoice == choice
    }

    private var isCorrectChoice: Bool {
        normalized(choice) == normalized(correctAnswer)
    }

    private var fill: Color {
        guard isLocked else { return .white }
        if isSelected && isCorrectChoice { return AtlasColors.green.opacity(0.32) }
        if isSelected && !isCorrectChoice { return AtlasColors.coral.opacity(0.34) }
        if isCorrectChoice { return AtlasColors.green.opacity(0.18) }
        return .white.opacity(0.78)
    }

    var body: some View {
        Button {
            AtlasHaptics.selection()
            choose()
        } label: {
            HStack(spacing: 10) {
                Text(choice)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(.black)
                    .lineLimit(3)
                    .minimumScaleFactor(0.72)

                Spacer()

                if isLocked {
                    Image(systemName: isCorrectChoice ? "checkmark.circle.fill" : (isSelected ? "xmark.circle.fill" : "circle"))
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(isCorrectChoice ? AtlasColors.green : (isSelected ? AtlasColors.coral : .black.opacity(0.2)))
                }
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 13)
            .background(fill)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AtlasColors.line, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.42), radius: 0, y: isLocked ? 0 : 4)
        }
        .buttonStyle(.plain)
        .disabled(isLocked)
    }

    private func normalized(_ value: String) -> String {
        value
            .lowercased()
            .replacingOccurrences(of: "[^a-zа-яё0-9 ]", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct LessonIndexedTileWrap<Content: View>: View {
    let items: [String]
    @ViewBuilder let content: (Int, String) -> Content

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 82), spacing: 9)], alignment: .leading, spacing: 9) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                content(index, item)
            }
        }
    }
}

private struct LessonTileButton: View {
    let title: String
    let fill: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(fill)
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(AtlasColors.line, lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.42), radius: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

private extension View {
    func lessonPlayerSurface() -> some View {
        self
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.96))
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.black.opacity(0.16), lineWidth: 1.4)
            )
            .shadow(color: .black.opacity(0.22), radius: 18, y: 12)
    }
}
