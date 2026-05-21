//
//  LessonPlayerView.swift
//  Atlas learn
//

import SwiftUI

struct LessonPlayerView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var profile: AtlasProfile
    let mode: LessonMode
    let selectedWord: WordEntry?

    @State private var activeMode: LessonMode
    @State private var activeSelectedWord: WordEntry?
    @State private var run: LessonRun?
    @State private var initialMastery: [String: Int] = [:]
    @State private var selectedChoice: String?
    @State private var selectedTiles: [String] = []
    @State private var remainingTiles: [String] = []
    @State private var typedAnswer = ""
    @State private var feedback: LessonFeedbackState?
    @State private var isFinished = false
    @State private var taskStartedAt = Date()
    @StateObject private var speech = AtlasSpeechRecognition()

    init(profile: Binding<AtlasProfile>, mode: LessonMode = .daily, selectedWord: WordEntry? = nil) {
        _profile = profile
        self.mode = mode
        self.selectedWord = selectedWord
        _activeMode = State(initialValue: mode)
        _activeSelectedWord = State(initialValue: selectedWord)
    }

    private var language: AppLanguage {
        profile.appLanguage
    }

    private var currentTask: LessonTask? {
        run.flatMap { LessonEngine.nextTask(run: $0, profile: profile) }
    }

    private var currentTaskID: UUID? {
        currentTask?.id
    }

    private var currentWord: WordEntry? {
        guard let wordID = currentTask?.wordID else { return nil }
        return WordBank.all.first { $0.id == wordID }
    }

    var body: some View {
        ZStack {
            lessonBackground

            if let run, isFinished {
                LessonSummaryViewV2(
                    language: language,
                    run: run,
                    profile: profile,
                    initialMastery: initialMastery,
                    continuePath: dismiss.callAsFunction,
                    reviewMistakes: restartMistakeReview,
                    drillWeakWord: restartWeakWordDrill
                )
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            } else if let run {
                lessonContent(run: run)
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
        }
        .onAppear {
            if run == nil {
                startNewLesson(mode: activeMode, selectedWord: activeSelectedWord)
            }
        }
        .onDisappear {
            speech.stopRecording(keepTranscript: false)
        }
        .onChange(of: currentTaskID) { _, _ in
            prepareCurrentTask()
        }
        .atlasMotion(currentTaskID)
        .atlasMotion(run?.energy ?? 0)
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

    private func lessonContent(run: LessonRun) -> some View {
        VStack(spacing: 0) {
            LessonPlayerHeader(
                language: language,
                mode: run.mode,
                progress: lessonProgress(for: run),
                energy: run.energy,
                xp: run.xpEarned,
                combo: run.combo,
                questionPosition: run.questionPosition,
                questionCount: run.tasks.count,
                dismiss: dismiss.callAsFunction
            )

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 13) {
                    LessonTaskRail(tasks: run.tasks, currentIndex: run.currentTaskIndex)

                    if let task = currentTask {
                        taskContent(task)
                    }
                }
                .padding(.horizontal, AtlasLayout.screenPadding)
                .padding(.top, 12)
                .padding(.bottom, 132)
            }
        }
        .safeAreaInset(edge: .bottom) {
            bottomPanel
        }
    }

    private func taskContent(_ task: LessonTask) -> AnyView {
        let word = currentWord ?? WordBank.all[0]
        let audioAction: (() -> Void)? = task.audioText == nil ? nil : { playCurrentAudio() }

        if task.type == .introCard {
            return AnyView(LessonIntroCardView(
                task: task,
                word: word,
                language: language,
                playAction: playCurrentAudio
            ))
        } else if task.type == .speechRepeat {
            return AnyView(LessonSpeechTaskView(
                task: task,
                word: word,
                language: language,
                speech: speech,
                isLocked: feedback != nil,
                playAction: playCurrentAudio,
                recordAction: startSpeechAttempt,
                stopAction: stopSpeechAttempt
            ))
        } else if isTileTask(task) {
            return AnyView(LessonTileTaskView(
                task: task,
                language: language,
                selectedTiles: selectedTiles,
                remainingTiles: remainingTiles,
                isLocked: feedback != nil,
                playAction: audioAction,
                chooseTile: chooseTile,
                removeTile: removeTile
            ))
        } else if !task.options.isEmpty {
            return AnyView(LessonChoiceTaskView(
                task: task,
                language: language,
                selectedChoice: selectedChoice,
                isLocked: feedback != nil,
                playAction: audioAction,
                choose: selectChoice
            ))
        } else {
            return AnyView(LessonInputTaskView(
                task: task,
                language: language,
                answer: $typedAnswer,
                isLocked: feedback != nil,
                playAction: audioAction
            ))
        }
    }

    @ViewBuilder
    private var bottomPanel: some View {
        if let feedback {
            LessonFeedbackPanel(
                feedback: feedback,
                language: language,
                continueAction: continueLesson
            )
            .background(.ultraThinMaterial)
            .overlay(Rectangle().fill(.black.opacity(0.1)).frame(height: 1), alignment: .top)
        } else if let task = currentTask {
            LessonActionPanel(
                language: language,
                task: task,
                canSubmit: canSubmit(task),
                canResetTiles: isTileTask(task) && !selectedTiles.isEmpty,
                resetAction: resetTiles,
                dontKnowAction: markIDontKnow,
                submitAction: submitCurrentTask
            )
            .background(.ultraThinMaterial)
            .overlay(Rectangle().fill(.black.opacity(0.1)).frame(height: 1), alignment: .top)
        }
    }

    private func startNewLesson(mode: LessonMode, selectedWord: WordEntry?) {
        activeMode = mode
        activeSelectedWord = selectedWord
        speech.stopRecording(keepTranscript: false)

        var nextRun = LessonEngine.makeLesson(mode: mode, profile: profile, selectedWord: selectedWord)
        nextRun.energy = EnergyEngine.lessonStartEnergy(from: profile.energy)
        profile.energy = nextRun.energy

        let ids = Set(nextRun.targetWordIDs + nextRun.reviewWordIDs + nextRun.weakWordIDs + nextRun.tasks.compactMap(\.wordID))
        initialMastery = Dictionary(uniqueKeysWithValues: ids.map { id in
            (id, profile.wordProgress[id]?.mastery ?? 0)
        })

        withAnimation(.atlasSoftSpring) {
            run = nextRun
            isFinished = false
            feedback = nil
        }
        prepareCurrentTask()
    }

    private func prepareCurrentTask() {
        selectedChoice = nil
        selectedTiles = []
        typedAnswer = ""
        feedback = nil
        taskStartedAt = Date()
        speech.reset()

        if let task = currentTask, isTileTask(task) {
            remainingTiles = task.options
        } else {
            remainingTiles = []
        }

        if let task = currentTask, task.audioText != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                guard currentTaskID == task.id, feedback == nil else { return }
                playCurrentAudio()
            }
        }
    }

    private func lessonProgress(for run: LessonRun) -> Double {
        guard run.tasks.count > 0 else { return 0 }
        let completed = run.currentTaskIndex + (feedback == nil ? 0 : 1)
        return Double(completed) / Double(run.tasks.count)
    }

    private func canSubmit(_ task: LessonTask) -> Bool {
        if feedback != nil { return false }

        switch task.type {
        case .introCard:
            return true
        case .meaningChoice, .contextChoice, .clozeChoice, .audioChoice, .matchingPairs, .dialogueChoice:
            return false
        case .translationTiles, .wordOrder:
            return selectedTiles.count >= max(task.correctAnswer.split(separator: " ").count, 1)
        case .speechRepeat:
            return !speech.transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && speech.state != .recording
        case .mistakeClinic:
            if isTileTask(task) {
                return selectedTiles.count >= max(task.correctAnswer.split(separator: " ").count, 1)
            }
            return !typedAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        default:
            return !typedAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private func isTileTask(_ task: LessonTask) -> Bool {
        switch task.type {
        case .translationTiles, .wordOrder:
            return true
        case .mistakeClinic:
            return !task.options.isEmpty && task.correctAnswer.split(separator: " ").count > 1
        default:
            return false
        }
    }

    private func selectChoice(_ choice: String) {
        guard feedback == nil else { return }
        selectedChoice = choice
        commit(answer: .answer(choice, responseTime: responseTime()))
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
        guard let task = currentTask, isTileTask(task) else { return }

        AtlasHaptics.tap()
        withAnimation(.atlasSpring) {
            selectedTiles = []
            remainingTiles = task.options
        }
    }

    private func markIDontKnow() {
        guard feedback == nil else { return }
        AtlasHaptics.tap()
        commit(answer: .dontKnow(responseTime: responseTime()))
    }

    private func submitCurrentTask() {
        guard let task = currentTask, feedback == nil else { return }

        switch task.type {
        case .introCard:
            commit(answer: .answer(task.correctAnswer, responseTime: responseTime()))
        case .translationTiles, .wordOrder:
            commit(answer: .answer(selectedTiles.joined(separator: " "), responseTime: responseTime()))
        case .speechRepeat:
            commit(answer: .answer(speech.transcript, responseTime: responseTime()))
        case .mistakeClinic where isTileTask(task):
            commit(answer: .answer(selectedTiles.joined(separator: " "), responseTime: responseTime()))
        default:
            commit(answer: .answer(typedAnswer, responseTime: responseTime()))
        }
    }

    private func commit(answer: LessonAnswer) {
        guard var currentRun = run, let task = currentRun.currentTask, feedback == nil else { return }

        let evaluation = LessonEngine.evaluate(answer: answer, task: task, profile: profile)
        let nextCombo = evaluation.isCorrect ? currentRun.combo + 1 : 0
        let energyDelta = EnergyEngine.delta(
            isCorrect: evaluation.isCorrect,
            didNotKnow: evaluation.didNotKnow,
            comboAfterAnswer: nextCombo
        )

        let result = LessonTaskResult(
            id: UUID(),
            taskID: task.id,
            wordID: task.wordID,
            type: task.type,
            skill: task.skill,
            isCorrect: evaluation.isCorrect,
            usedHint: evaluation.usedHint,
            responseTime: answer.responseTime,
            xp: evaluation.xp,
            masteryDelta: evaluation.masteryDelta,
            createdAt: Date()
        )

        if evaluation.isCorrect {
            AtlasHaptics.success()
        } else {
            AtlasHaptics.error()
        }

        currentRun.results.append(result)
        currentRun.xpEarned += result.xp
        currentRun.combo = nextCombo
        currentRun.maxCombo = max(currentRun.maxCombo, nextCombo)
        currentRun.energy = EnergyEngine.clamped(currentRun.energy + energyDelta)
        profile.energy = currentRun.energy

        if evaluation.shouldScheduleMistake,
           let mistake = MistakeClinicEngine.makeItem(task: task, wrongAnswer: answer.value) {
            currentRun.mistakeQueue.append(mistake)

            if answer.didNotKnow, let word = currentWord {
                let insertIndex = min(currentRun.currentTaskIndex + 1, currentRun.tasks.count)
                currentRun.tasks.insert(MistakeClinicEngine.teachAgainTask(for: word), at: insertIndex)
            }
        }

        run = currentRun
        LessonEngine.applyResult(result, profile: &profile)

        withAnimation(.atlasSpring) {
            feedback = LessonFeedbackState(
                isCorrect: evaluation.isCorrect,
                didNotKnow: evaluation.didNotKnow,
                title: evaluation.title,
                detail: evaluation.detail,
                correctAnswer: evaluation.correctAnswer,
                xp: evaluation.xp
            )
        }
    }

    private func continueLesson() {
        guard feedback != nil, var currentRun = run else { return }

        var nextIndex = currentRun.currentTaskIndex + 1
        for index in currentRun.mistakeQueue.indices {
            currentRun.mistakeQueue[index].returnAfterTasks -= 1
        }

        if nextIndex >= currentRun.tasks.count,
           !currentRun.mistakeQueue.isEmpty {
            currentRun.mistakeQueue[0].returnAfterTasks = 0
        }

        if let dueIndex = currentRun.mistakeQueue.firstIndex(where: { $0.returnAfterTasks <= 0 }) {
            let mistake = currentRun.mistakeQueue.remove(at: dueIndex)
            if let word = WordBank.all.first(where: { $0.id == mistake.wordID }) {
                let clinic = MistakeClinicEngine.clinicTask(for: mistake, word: word)
                currentRun.tasks.insert(clinic, at: min(nextIndex, currentRun.tasks.count))
            }
        }

        if nextIndex >= currentRun.tasks.count {
            currentRun.finishedAt = Date()
            run = currentRun
            finishLesson()
            return
        }

        nextIndex = min(nextIndex, currentRun.tasks.count - 1)
        withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
            currentRun.currentTaskIndex = nextIndex
            run = currentRun
            feedback = nil
        }
    }

    private func finishLesson() {
        speech.stopRecording(keepTranscript: false)
        AtlasHaptics.success()
        withAnimation(.atlasSoftSpring) {
            isFinished = true
            feedback = nil
        }
    }

    private func restartMistakeReview() {
        startNewLesson(mode: .weakWords, selectedWord: nil)
    }

    private func restartWeakWordDrill() {
        let weakID = run?.weakWordIDs.first ?? profile.weakWordIDs.first ?? run?.targetWordIDs.first
        let word = weakID.flatMap { id in WordBank.all.first { $0.id == id } }
        startNewLesson(mode: .wordDrill, selectedWord: word)
    }

    private func playCurrentAudio() {
        guard let task = currentTask else { return }
        AtlasHaptics.tap()
        AtlasSpeech.speak(task.audioText ?? task.correctAnswer, voice: profile.selectedSpeechVoice)
    }

    private func startSpeechAttempt() {
        AtlasHaptics.tap()
        speech.startRecording(localeIdentifier: profile.selectedSpeechVoice.languageCode)
    }

    private func stopSpeechAttempt() {
        AtlasHaptics.tap()
        speech.stopRecording(keepTranscript: true)
    }

    private func responseTime() -> TimeInterval {
        Date().timeIntervalSince(taskStartedAt)
    }
}
