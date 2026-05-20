//
//  PracticeView.swift
//  Atlas learn
//

import SwiftUI

struct PracticeView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var profile: AtlasProfile
    let words: [WordEntry]
    var startWordID: WordEntry.ID?

    @State private var session = PracticeSession(words: [], startWordID: nil)
    @State private var selectedChoice: String?
    @State private var selectedTiles: [String] = []
    @State private var remainingTiles: [String] = []
    @State private var feedback: PracticeFeedback?
    @State private var isFinished = false
    @State private var hasStartedCurrentWord = false
    @StateObject private var speech = AtlasSpeechRecognition()
    @State private var generatedExamples: [WordEntry.ID: GeneratedWordExample] = [:]
    @State private var generatingExampleIDs: Set<WordEntry.ID> = []

    private var lessonWord: WordEntry {
        let source = words.isEmpty ? Array(profile.dailyWords.prefix(max(profile.dailyGoal, 7))) : words
        let fallback = source.isEmpty ? Array(WordBank.all.prefix(max(profile.dailyGoal, 7))) : source
        let uniqueWords = fallback.uniquedByID()

        if let startWordID {
            if let selected = uniqueWords.first(where: { $0.id == startWordID }) {
                return selected
            }

            if let selected = WordBank.all.first(where: { $0.id == startWordID }) {
                return selected
            }
        }

        return uniqueWords.first ?? WordBank.all[0]
    }

    private var practiceWords: [WordEntry] {
        [lessonWord]
    }

    private var currentWord: WordEntry {
        if let currentWordID = session.currentWordID,
           let word = practiceWords.first(where: { $0.id == currentWordID }) {
            return word
        }

        return practiceWords.first ?? WordBank.all[0]
    }

    private var currentExample: GeneratedWordExample {
        generatedExamples[currentWord.id] ?? AtlasExampleGenerator.fallbackExample(for: currentWord)
    }

    private var currentExampleStatus: ExampleDisplayStatus {
        if generatedExamples[currentWord.id] != nil {
            return .generated
        }

        if generatingExampleIDs.contains(currentWord.id) {
            return .generating
        }

        return .local
    }

    private var language: AppLanguage {
        profile.appLanguage
    }

    private var currentStep: PracticeStep {
        session.currentStep
    }

    private var lessonProgress: Double {
        guard !session.wordIDs.isEmpty, !session.steps.isEmpty else { return 0 }
        let completed = session.currentWordIndex * session.steps.count + session.currentStepIndex + (feedback == nil ? 0 : 1)
        return Double(completed) / Double(session.wordIDs.count * session.steps.count)
    }

    private var speechTarget: String {
        currentWord.english
    }

    var body: some View {
        ZStack {
            lessonBackground

            if isFinished {
                LessonSummaryView(
                    language: language,
                    session: session,
                    levelTag: profile.currentLevel.tag,
                    score: profile.score0To160,
                    dismiss: dismiss.callAsFunction
                )
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            } else {
                lessonContent
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
        }
        .onAppear(perform: startSessionIfNeeded)
        .onDisappear {
            speech.stopRecording(keepTranscript: false)
        }
        .onChange(of: currentStep) { _, _ in
            prepareCurrentStep()
        }
        .task(id: lessonWord.id) {
            await generateExampleIfNeeded(for: lessonWord)
        }
        .atlasMotion(currentWord.id)
        .atlasMotion(currentStep)
        .atlasMotion(session.hearts)
    }

    private var lessonBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 0.97, green: 0.94, blue: 0.86),
                Color(red: 0.84, green: 0.95, blue: 0.92),
                Color(red: 0.98, green: 0.89, blue: 0.78)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var lessonContent: some View {
        VStack(spacing: 0) {
            LessonHeader(
                language: language,
                progress: lessonProgress,
                hearts: session.hearts,
                xp: session.xp,
                wordPosition: min(session.currentWordIndex + 1, max(session.wordIDs.count, 1)),
                wordCount: max(session.wordIDs.count, 1),
                dismiss: dismiss.callAsFunction
            )

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 13) {
                    if hasStartedCurrentWord {
                        PracticeStepRail(steps: session.steps, currentStep: currentStep)

                        TargetWordCapsule(
                            word: currentWord,
                            language: language,
                            mastery: profile.wordProgress[currentWord.id]?.mastery ?? 0,
                            speak: speakWord
                        )

                        challengeContent
                    } else {
                        StartWordCard(
                            word: currentWord,
                            language: language,
                            mastery: profile.wordProgress[currentWord.id]?.mastery ?? 0,
                            example: currentExample,
                            exampleStatus: currentExampleStatus,
                            speak: speakWord,
                            start: startWordQuestions
                        )
                    }
                }
                .padding(.horizontal, AtlasLayout.screenPadding)
                .padding(.top, 12)
                .padding(.bottom, hasStartedCurrentWord ? 132 : 28)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if hasStartedCurrentWord {
                bottomPanel
            }
        }
    }

    @ViewBuilder
    private var challengeContent: some View {
        switch currentStep {
        case .meaningChoice:
            ChoiceExerciseView(
                title: currentStep.title(for: language),
                prompt: language.text(ru: "Что значит это слово?", en: "What does this word mean?"),
                focusText: currentWord.english,
                detail: "\(currentWord.ipa) · \(currentWord.partOfSpeech)",
                choices: WordBank.translationChoices(for: currentWord),
                correctAnswer: currentWord.russian,
                selectedChoice: selectedChoice,
                feedback: feedback,
                choose: selectChoice
            )
        case .ruToEnglishTiles:
            TileExerciseView(
                title: currentStep.title(for: language),
                prompt: currentExample.russian,
                helper: language.text(ru: "Собери английскую фразу. Целевое слово должно оказаться внутри ответа.", en: "Build the English phrase. The target word belongs inside the answer."),
                selectedTiles: selectedTiles,
                remainingTiles: remainingTiles,
                isLocked: feedback != nil,
                playAction: nil,
                chooseTile: chooseTile,
                removeTile: removeTile
            )
        case .listenTiles:
            TileExerciseView(
                title: currentStep.title(for: language),
                prompt: language.text(ru: "Слушай английскую фразу и собери ее.", en: "Listen to the English phrase and assemble it."),
                helper: currentWord.russian,
                selectedTiles: selectedTiles,
                remainingTiles: remainingTiles,
                isLocked: feedback != nil,
                playAction: speakSentence,
                chooseTile: chooseTile,
                removeTile: removeTile
            )
        case .clozeWord:
            ChoiceExerciseView(
                title: currentStep.title(for: language),
                prompt: lessonClozeSentence(for: currentWord),
                focusText: "____",
                detail: currentExample.russian,
                choices: WordBank.clozeChoices(for: currentWord),
                correctAnswer: currentWord.english,
                selectedChoice: selectedChoice,
                feedback: feedback,
                choose: selectChoice
            )
        case .wordOrder:
            TileExerciseView(
                title: currentStep.title(for: language),
                prompt: currentExample.russian,
                helper: language.text(ru: "Поставь все слова в естественном английском порядке.", en: "Put every word into natural English order."),
                selectedTiles: selectedTiles,
                remainingTiles: remainingTiles,
                isLocked: feedback != nil,
                playAction: nil,
                chooseTile: chooseTile,
                removeTile: removeTile
            )
        case .speechRepeat:
            SpeechRepeatChallenge(
                word: currentWord,
                language: language,
                target: speechTarget,
                speech: speech,
                isLocked: feedback != nil,
                example: currentExample.english,
                playAction: speakWord,
                recordAction: startSpeechAttempt,
                stopAction: stopSpeechAttempt
            )
        }
    }

    private var bottomPanel: some View {
        VStack(spacing: 0) {
            if let feedback {
                FeedbackPanel(
                    feedback: feedback,
                    language: language,
                    continueAction: continueLesson
                )
            } else {
                ActionPanel(
                    language: language,
                    step: currentStep,
                    canSubmit: canSubmitCurrentStep,
                    canResetTiles: isTileStep(currentStep) && !selectedTiles.isEmpty,
                    canSkip: currentStep == .speechRepeat && speech.canSkip,
                    resetAction: resetTiles,
                    skipAction: skipSpeechStep,
                    submitAction: submitCurrentStep
                )
            }
        }
        .background(.ultraThinMaterial)
        .overlay(Rectangle().fill(.black.opacity(0.1)).frame(height: 1), alignment: .top)
    }

    private var canSubmitCurrentStep: Bool {
        switch currentStep {
        case .meaningChoice, .clozeWord:
            false
        case .ruToEnglishTiles, .listenTiles, .wordOrder:
            !selectedTiles.isEmpty && remainingTiles.isEmpty
        case .speechRepeat:
            !speech.transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && speech.state != .recording
        }
    }

    private func startSessionIfNeeded() {
        guard session.wordIDs.isEmpty else { return }

        session = PracticeSession(words: [lessonWord], startWordID: lessonWord.id)
        prepareCurrentStep()
    }

    private func startWordQuestions() {
        AtlasHaptics.tap()
        withAnimation(.atlasSpring) {
            hasStartedCurrentWord = true
        }
        prepareCurrentStep()
    }

    private func prepareCurrentStep() {
        selectedChoice = nil
        selectedTiles = []
        feedback = nil
        speech.reset()

        if isTileStep(currentStep) {
            remainingTiles = lessonSentenceTiles(for: currentWord)
        } else {
            remainingTiles = []
        }

        if hasStartedCurrentWord && currentStep == .listenTiles {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                speakSentence()
            }
        }
    }

    private func speakWord() {
        AtlasHaptics.tap()
        AtlasSpeech.speak(currentWord.english, voice: profile.selectedSpeechVoice)
    }

    private func speakSentence() {
        AtlasHaptics.tap()
        AtlasSpeech.speak(lessonSentenceAnswer(for: currentWord), voice: profile.selectedSpeechVoice)
    }

    private func selectChoice(_ choice: String, correctAnswer: String) {
        guard feedback == nil else { return }

        selectedChoice = choice
        commitStep(isCorrect: normalized(choice) == normalized(correctAnswer), detail: correctAnswer)
    }

    private func chooseTile(_ tile: String, at index: Int) {
        guard feedback == nil, remainingTiles.indices.contains(index) else { return }

        AtlasHaptics.selection()
        withAnimation(.atlasSpring) {
            selectedTiles.append(tile)
            remainingTiles.remove(at: index)
        }
    }

    private func removeTile(at index: Int) {
        guard feedback == nil, selectedTiles.indices.contains(index) else { return }

        AtlasHaptics.selection()
        withAnimation(.atlasSpring) {
            let tile = selectedTiles.remove(at: index)
            remainingTiles.append(tile)
        }
    }

    private func resetTiles() {
        guard isTileStep(currentStep) else { return }

        AtlasHaptics.tap()
        withAnimation(.atlasSpring) {
            selectedTiles = []
            remainingTiles = lessonSentenceTiles(for: currentWord)
        }
    }

    private func startSpeechAttempt() {
        AtlasHaptics.tap()
        speech.startRecording(localeIdentifier: profile.selectedSpeechVoice.languageCode)
    }

    private func stopSpeechAttempt() {
        AtlasHaptics.tap()
        speech.stopRecording(keepTranscript: true)
    }

    private func submitCurrentStep() {
        guard feedback == nil else { return }

        switch currentStep {
        case .meaningChoice, .clozeWord:
            break
        case .ruToEnglishTiles, .listenTiles, .wordOrder:
            let answer = selectedTiles.joined(separator: " ")
            let correct = lessonSentenceAnswer(for: currentWord)
            commitStep(isCorrect: normalized(answer) == normalized(correct), detail: correct)
        case .speechRepeat:
            let result = evaluateSpeechAnswer()
            commitStep(isCorrect: result.isCorrect, detail: result.detail)
        }
    }

    private func lessonSentenceTiles(for word: WordEntry) -> [String] {
        if generatedExamples[word.id] == nil {
            return WordBank.sentenceTiles(for: word)
        }

        let tiles = currentExample.sentenceTiles
        guard tiles.count > 1 else { return tiles }
        let rawOffset = word.id.unicodeScalars.reduce(0) { $0 + Int($1.value) } % tiles.count
        let offset = rawOffset == 0 ? 1 : rawOffset
        return Array(tiles[offset...]) + Array(tiles[..<offset])
    }

    private func lessonSentenceAnswer(for word: WordEntry) -> String {
        if generatedExamples[word.id] == nil {
            return WordBank.sentenceAnswer(for: word)
        }

        return currentExample.sentenceTiles.joined(separator: " ")
    }

    private func lessonClozeSentence(for word: WordEntry) -> String {
        if generatedExamples[word.id] == nil {
            return word.clozeSentence
        }

        return currentExample.clozeSentence(targetWord: word.english)
    }

    private func generateExampleIfNeeded(for word: WordEntry) async {
        guard AtlasExampleGenerator.isAvailable else { return }
        guard generatedExamples[word.id] == nil, !generatingExampleIDs.contains(word.id) else { return }

        generatingExampleIDs.insert(word.id)
        defer { generatingExampleIDs.remove(word.id) }

        guard let generated = await AtlasExampleGenerator.generateExample(for: word) else { return }
        generatedExamples[word.id] = generated

        if isTileStep(currentStep), feedback == nil {
            selectedTiles = []
            remainingTiles = lessonSentenceTiles(for: word)
        }
    }

    private func skipSpeechStep() {
        guard currentStep == .speechRepeat, feedback == nil else { return }

        AtlasHaptics.tap()
        speech.stopRecording(keepTranscript: true)
        withAnimation(.atlasSpring) {
            session.record(step: currentStep, wordID: currentWord.id, isCorrect: false, xp: 0, wasSkipped: true)
            feedback = PracticeFeedback(
                isCorrect: false,
                wasSkipped: true,
                title: language.text(ru: "Пропущено", en: "Skipped"),
                detail: language.text(
                    ru: "Микрофон или распознавание недоступны. Этот шаг не влияет на XP и сердца.",
                    en: "Microphone or speech recognition is unavailable. This step does not affect XP or hearts."
                ),
                correctAnswer: speechTarget
            )
        }
    }

    private func evaluateSpeechAnswer() -> (isCorrect: Bool, detail: String) {
        let heard = speech.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedHeard = normalized(heard)
        let target = normalized(speechTarget)
        let accepted = [target] + currentWord.acceptedAnswers.map(normalized)
        let isCorrect = accepted.contains { answer in
            normalizedHeard == answer || normalizedHeard.contains(answer)
        }

        let detail = isCorrect
            ? language.text(ru: "Распознано: \(heard)", en: "Recognized: \(heard)")
            : language.text(ru: "Я услышал: \(heard). Цель: \(speechTarget)", en: "I heard: \(heard). Target: \(speechTarget)")
        return (isCorrect, detail)
    }

    private func commitStep(isCorrect: Bool, detail: String) {
        let step = currentStep
        let mode = step.mode
        let xp = profile.recordPractice(word: currentWord, mode: mode, isCorrect: isCorrect)

        if isCorrect {
            AtlasHaptics.success()
        } else {
            AtlasHaptics.error()
        }

        withAnimation(.atlasSpring) {
            session.record(step: step, wordID: currentWord.id, isCorrect: isCorrect, xp: xp)
            feedback = PracticeFeedback(
                isCorrect: isCorrect,
                wasSkipped: false,
                title: isCorrect ? language.text(ru: "Верно", en: "Correct") : language.text(ru: "Еще раз", en: "Try again"),
                detail: isCorrect ? "+\(xp) XP · \(currentWord.english) / \(currentWord.russian)" : detail,
                correctAnswer: detail
            )
        }
    }

    private func continueLesson() {
        guard feedback != nil else { return }

        if session.hearts == 0 {
            finishSession()
            return
        }

        if session.isOnLastStep {
            if session.currentWordIndex >= session.wordIDs.count - 1 {
                finishSession()
            } else {
                withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
                    session.advanceWord()
                    hasStartedCurrentWord = false
                }
            }
        } else {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
                session.advanceStep()
            }
        }
    }

    private func finishSession() {
        speech.stopRecording(keepTranscript: false)
        AtlasHaptics.success()
        withAnimation(.atlasSoftSpring) {
            isFinished = true
        }
    }

    private func isTileStep(_ step: PracticeStep) -> Bool {
        switch step {
        case .ruToEnglishTiles, .listenTiles, .wordOrder:
            true
        case .meaningChoice, .clozeWord, .speechRepeat:
            false
        }
    }

    private func normalized(_ value: String) -> String {
        value
            .lowercased()
            .replacingOccurrences(of: "[^a-zа-яё0-9 ]", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct PracticeFeedback: Equatable {
    let isCorrect: Bool
    let wasSkipped: Bool
    let title: String
    let detail: String
    let correctAnswer: String
}

private struct LessonHeader: View {
    let language: AppLanguage
    let progress: Double
    let hearts: Int
    let xp: Int
    let wordPosition: Int
    let wordCount: Int
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

                HStack(spacing: 3) {
                    ForEach(0..<3, id: \.self) { index in
                        Image(systemName: index < hearts ? "heart.fill" : "heart")
                            .font(.system(size: 15, weight: .black))
                            .foregroundStyle(index < hearts ? AtlasColors.coral : .black.opacity(0.24))
                    }
                }
                .frame(width: 66)
            }

            HStack(spacing: 8) {
                CapsuleMetric(icon: "bolt.fill", title: "\(xp) XP")
                CapsuleMetric(icon: "map", title: "\(wordPosition)/\(wordCount)")
                Spacer()
                Text(language.text(ru: "Путь слова", en: "Word path"))
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

private struct PracticeStepRail: View {
    let steps: [PracticeStep]
    let currentStep: PracticeStep

    var body: some View {
        HStack(spacing: 7) {
            ForEach(steps) { step in
                let isActive = step == currentStep

                Image(systemName: step.icon)
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(isActive ? .white : .black.opacity(0.52))
                    .frame(maxWidth: .infinity)
                    .frame(height: 32)
                    .background(isActive ? AtlasColors.ink : Color.white.opacity(0.68))
                    .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .stroke(.black.opacity(isActive ? 0.84 : 0.2), lineWidth: 1.5)
                    )
            }
        }
    }
}

private struct TargetWordCapsule: View {
    let word: WordEntry
    let language: AppLanguage
    let mastery: Int
    let speak: () -> Void

    var body: some View {
        HStack(spacing: 11) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 7) {
                    Text(word.english)
                        .font(.system(size: 22, weight: .black, design: .serif))
                        .lineLimit(1)
                        .minimumScaleFactor(0.66)

                    Text(word.level.tag)
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(AtlasColors.mint.opacity(0.6)))
                }

                Text("\(word.russian) · \(word.ipa) · \(mastery)%")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(.black.opacity(0.6))
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
            }

            Spacer()

            Button(action: speak) {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 17, weight: .black))
                    .foregroundStyle(.black)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(.white))
                    .overlay(Circle().stroke(.black, lineWidth: 2))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 10)
        .background(.white.opacity(0.84))
        .clipShape(RoundedRectangle(cornerRadius: 19, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 19, style: .continuous)
                .stroke(AtlasColors.line, lineWidth: 2)
        )
        .shadow(color: AtlasColors.line.opacity(0.55), radius: 0, y: 3)
    }
}

private struct StartWordCard: View {
    let word: WordEntry
    let language: AppLanguage
    let mastery: Int
    let example: GeneratedWordExample
    let exampleStatus: ExampleDisplayStatus
    let speak: () -> Void
    let start: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
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

                Button(action: speak) {
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

            HStack(spacing: 8) {
                CapsuleMetric(icon: "flag.checkered", title: word.level.tag)
                CapsuleMetric(icon: "target", title: "\(mastery)%")
                CapsuleMetric(icon: "square.grid.2x2", title: WordBank.topicTitle(word.topic, for: language))
            }

            Text(word.definition(for: language))
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.black.opacity(0.72))
                .lineSpacing(3)

            ExampleCard(
                title: language.text(ru: "Контекст", en: "Context"),
                text: "\(example.english)\n\(example.russian)"
            )

            ExampleStatusPill(status: exampleStatus, language: language)

            if !word.collocations.isEmpty || !word.hints.isEmpty {
                FlexibleChipWrap(items: Array((word.collocations + word.hints).prefix(6)))
            }

            Button(action: start) {
                HStack(spacing: 9) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 18, weight: .black))
                    Text(language.text(ru: "Начать вопросы", en: "Start questions"))
                        .font(.system(size: 17, weight: .black, design: .rounded))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(AtlasColors.ink)
                .clipShape(RoundedRectangle(cornerRadius: 19, style: .continuous))
                .shadow(color: .black.opacity(0.36), radius: 0, y: 5)
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
        }
        .lessonSurface()
    }
}

private struct ChoiceExerciseView: View {
    let title: String
    let prompt: String
    let focusText: String
    let detail: String
    let choices: [String]
    let correctAnswer: String
    let selectedChoice: String?
    let feedback: PracticeFeedback?
    let choose: (String, String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ExerciseTitle(title: title, subtitle: prompt)

            Text(focusText)
                .font(.system(size: focusText.count > 18 ? 28 : 38, weight: .black, design: .serif))
                .frame(maxWidth: .infinity)
                .frame(minHeight: 72)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.58)
                .padding(.horizontal, 14)
                .background(AtlasColors.mint.opacity(0.32))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(.black.opacity(0.36), lineWidth: 1.6)
                )

            Text(detail)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.black.opacity(0.58))
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 10) {
                ForEach(choices, id: \.self) { choice in
                    ChoiceRow(
                        choice: choice,
                        correctAnswer: correctAnswer,
                        selectedChoice: selectedChoice,
                        isLocked: feedback != nil
                    ) { selected in
                        choose(selected, correctAnswer)
                    }
                }
            }
        }
        .lessonSurface()
    }
}

private struct TileExerciseView: View {
    let title: String
    let prompt: String
    let helper: String
    let selectedTiles: [String]
    let remainingTiles: [String]
    let isLocked: Bool
    let playAction: (() -> Void)?
    let chooseTile: (String, Int) -> Void
    let removeTile: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ExerciseTitle(title: title, subtitle: prompt)

            if let playAction {
                Button(action: playAction) {
                    HStack(spacing: 12) {
                        Image(systemName: "waveform.circle.fill")
                            .font(.system(size: 36, weight: .black))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Play")
                                .font(.system(size: 18, weight: .black, design: .rounded))
                            Text(helper)
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
            } else {
                Text(helper)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.black.opacity(0.58))
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 10) {
                if selectedTiles.isEmpty {
                    Text("Tap tiles")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.black.opacity(0.38))
                        .frame(maxWidth: .infinity, minHeight: 82, alignment: .topLeading)
                } else {
                    FlexibleIndexedTileWrap(items: selectedTiles) { index, tile in
                        TileButton(title: tile, fill: AtlasColors.mint.opacity(0.52)) {
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

            FlexibleIndexedTileWrap(items: remainingTiles) { index, tile in
                TileButton(title: tile, fill: .white) {
                    chooseTile(tile, index)
                }
                .disabled(isLocked)
            }
        }
        .lessonSurface()
    }
}

private struct SpeechRepeatChallenge: View {
    let word: WordEntry
    let language: AppLanguage
    let target: String
    @ObservedObject var speech: AtlasSpeechRecognition
    let isLocked: Bool
    let example: String
    let playAction: () -> Void
    let recordAction: () -> Void
    let stopAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ExerciseTitle(
                title: PracticeStep.speechRepeat.title(for: language),
                subtitle: language.text(ru: "Произнеси цель четко и коротко.", en: "Say the target clearly and briefly.")
            )

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(target)
                        .font(.system(size: target.count > 16 ? 30 : 40, weight: .black, design: .serif))
                        .lineLimit(1)
                        .minimumScaleFactor(0.58)

                    Text(example)
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
            .disabled(isLocked || speech.state == .requestingPermission || speech.canSkip)

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
        .lessonSurface()
    }

    private var buttonTitle: String {
        switch speech.state {
        case .recording:
            language.text(ru: "Остановить запись", en: "Stop recording")
        case .requestingPermission:
            language.text(ru: "Запрашиваю доступ", en: "Requesting access")
        case .denied, .unavailable, .failed:
            language.text(ru: "Можно пропустить", en: "You can skip")
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

private struct ExerciseTitle: View {
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

private struct ChoiceRow: View {
    let choice: String
    let correctAnswer: String
    let selectedChoice: String?
    let isLocked: Bool
    let choose: (String) -> Void

    private var isSelected: Bool {
        selectedChoice == choice
    }

    private var isCorrectChoice: Bool {
        choice.localizedCaseInsensitiveCompare(correctAnswer) == .orderedSame
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
            choose(choice)
        } label: {
            HStack(spacing: 10) {
                Text(choice)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(.black)
                    .lineLimit(2)
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
}

private struct ActionPanel: View {
    let language: AppLanguage
    let step: PracticeStep
    let canSubmit: Bool
    let canResetTiles: Bool
    let canSkip: Bool
    let resetAction: () -> Void
    let skipAction: () -> Void
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

            if canSkip {
                Button(action: skipAction) {
                    Image(systemName: "forward.end.fill")
                        .font(.system(size: 17, weight: .black))
                        .foregroundStyle(.black)
                        .frame(width: 50, height: 50)
                        .background(Circle().fill(.white))
                        .overlay(Circle().stroke(AtlasColors.line, lineWidth: 2))
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
                        .minimumScaleFactor(0.78)
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
        switch step {
        case .meaningChoice, .clozeWord:
            language.text(ru: "Выбери вариант выше", en: "Choose an option above")
        default:
            step.actionTitle(for: language)
        }
    }
}

private struct FeedbackPanel: View {
    let feedback: PracticeFeedback
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
        if feedback.wasSkipped { return "forward.end.fill" }
        return feedback.isCorrect ? "checkmark.seal.fill" : "xmark.octagon.fill"
    }

    private var color: Color {
        if feedback.wasSkipped { return AtlasColors.ink }
        return feedback.isCorrect ? AtlasColors.green : AtlasColors.coral
    }
}

private struct LessonSummaryView: View {
    let language: AppLanguage
    let session: PracticeSession
    let levelTag: String
    let score: Int
    let dismiss: () -> Void

    private var accuracy: Int {
        guard session.scoredCount > 0 else { return 0 }
        return Int((Double(session.correctCount) / Double(session.scoredCount)) * 100)
    }

    var body: some View {
        VStack(spacing: 18) {
            Spacer()

            ZStack {
                Circle()
                    .fill(AtlasColors.mint)
                    .frame(width: 132, height: 132)
                    .overlay(Circle().stroke(.black, lineWidth: 3))
                    .shadow(color: AtlasColors.line, radius: 0, y: 8)

                Image(systemName: session.hearts == 0 ? "heart.slash.fill" : "checkmark.seal.fill")
                    .font(.system(size: 62, weight: .black))
                    .foregroundStyle(.black)
            }

            Text(session.hearts == 0 ? language.text(ru: "Тренировка остановлена", en: "Practice paused") : language.text(ru: "Путь слова завершен", en: "Word path complete"))
                .font(.system(size: 31, weight: .black, design: .serif))
                .foregroundStyle(.black)
                .multilineTextAlignment(.center)

            Text(language.text(
                ru: "XP начисляется только за активные ответы. Слабые шаги вернут слово раньше.",
                en: "XP is awarded only for active answers. Weak steps bring the word back sooner."
            ))
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(.black.opacity(0.62))
            .multilineTextAlignment(.center)
            .lineSpacing(4)

            HStack(spacing: 12) {
                SummaryMetric(icon: "bolt.fill", title: "XP", value: "+\(session.xp)")
                SummaryMetric(icon: "target", title: language.text(ru: "Точность", en: "Accuracy"), value: "\(accuracy)%")
                SummaryMetric(icon: "flag.checkered", title: language.text(ru: "Уровень", en: "Level"), value: "\(levelTag) \(score)")
            }

            Button(action: dismiss) {
                Text(language.text(ru: "Вернуться", en: "Back"))
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(AtlasColors.ink)
                    .clipShape(RoundedRectangle(cornerRadius: 21, style: .continuous))
                    .shadow(color: .black.opacity(0.36), radius: 0, y: 5)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)

            Spacer()
        }
        .foregroundStyle(.black)
        .padding(.horizontal, AtlasLayout.screenPadding)
        .padding(.vertical, 22)
    }
}

private struct SummaryMetric: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .black))
            Text(value)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(.black.opacity(0.58))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(.white.opacity(0.84))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AtlasColors.line, lineWidth: 2)
        )
        .shadow(color: AtlasColors.line.opacity(0.7), radius: 0, y: 4)
    }
}

private struct ExampleCard: View {
    let title: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(.black.opacity(0.48))
            Text(text)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.black)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.white.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.black.opacity(0.18), lineWidth: 1.4)
        )
    }
}

private struct FlexibleChipWrap: View {
    let items: [String]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 112), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.74)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(AtlasColors.mint.opacity(0.38))
                    .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .stroke(.black.opacity(0.2), lineWidth: 1.2)
                    )
            }
        }
    }
}

private struct FlexibleIndexedTileWrap<Content: View>: View {
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

private struct TileButton: View {
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
    func lessonSurface() -> some View {
        padding(15)
            .background(.white.opacity(0.76))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(AtlasColors.line, lineWidth: 2.1)
            )
            .shadow(color: AtlasColors.line.opacity(0.64), radius: 0, y: 5)
    }
}
