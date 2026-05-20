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

    @State private var index = 0
    @State private var selectedMode: PracticeMode?
    @State private var selectedChoice: String?
    @State private var selectedTiles: [String] = []
    @State private var remainingTiles: [String] = []
    @State private var lastAnswerWasCorrect: Bool?
    @State private var lastAnswerText = ""
    @State private var hearts = 3
    @State private var sessionXP = 0
    @State private var isFinished = false

    private var practiceWords: [WordEntry] {
        let source = words.isEmpty ? Array(WordBank.all.prefix(max(profile.dailyGoal, 7))) : words
        return source.uniquedByID()
    }

    private var currentWord: WordEntry {
        practiceWords[min(index, max(practiceWords.count - 1, 0))]
    }

    private var language: AppLanguage {
        profile.appLanguage
    }

    var body: some View {
        ZStack {
            AtlasColors.paper.ignoresSafeArea()

            if isFinished {
                completionView
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            } else if selectedMode == nil {
                modePickerView
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            } else {
                challengeView
                    .transition(.opacity.combined(with: .move(edge: .leading)))
            }
        }
        .onAppear(perform: alignStartWord)
        .atlasMotion(index)
        .atlasMotion(selectedMode)
        .atlasMotion(selectedChoice)
        .atlasMotion(lastAnswerWasCorrect)
        .atlasMotion(hearts)
        .atlasSoftMotion(profile.appLanguage)
    }

    private var modePickerView: some View {
        VStack(spacing: 0) {
            practiceHeader

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(language.text(ru: "Выбери тренировку", en: "Choose practice"))
                            .font(.system(size: 31, weight: .black, design: .serif))
                        Text(language.text(
                            ru: "Начнем со слова, на котором ты остановился. Можно закрепить перевод, синоним, фразу или контекст.",
                            en: "Start from the word you stopped on. Practice meaning, synonym, sentence, or context."
                        ))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.black.opacity(0.62))
                        .lineSpacing(3)
                    }

                    focusWordCard

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        ForEach(PracticeMode.allCases) { mode in
                            Button {
                                startChallenge(mode)
                            } label: {
                                modeCard(mode)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    dueStrip
                }
                .foregroundStyle(.black)
                .padding(.horizontal, AtlasLayout.screenPadding)
                .padding(.top, 20)
                .padding(.bottom, 28)
            }
        }
    }

    private var challengeView: some View {
        VStack(spacing: 0) {
            practiceHeader

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 19) {
                    if let selectedMode {
                        Text(selectedMode.title(for: language))
                            .font(.system(size: 27, weight: .black, design: .serif))
                            .foregroundStyle(.black)

                        switch selectedMode {
                        case .translateChoice:
                            choiceChallenge(
                                prompt: language.text(ru: "Выбери правильный перевод", en: "Choose the correct translation"),
                                hero: currentWord.english,
                                detail: currentWord.ipa,
                                choices: WordBank.translationChoices(for: currentWord),
                                correctAnswer: currentWord.russian
                            )
                        case .synonymMatch:
                            choiceChallenge(
                                prompt: language.text(ru: "Найди ближайший синоним", en: "Find the closest synonym"),
                                hero: currentWord.english,
                                detail: currentWord.russian,
                                choices: WordBank.synonymChoices(for: currentWord),
                                correctAnswer: currentWord.synonyms.first ?? "no exact synonym"
                            )
                        case .sentenceBuilder:
                            sentenceBuilderChallenge
                        case .clozeChoice:
                            choiceChallenge(
                                prompt: currentWord.clozeSentence,
                                hero: "____",
                                detail: currentWord.russian,
                                choices: WordBank.clozeChoices(for: currentWord),
                                correctAnswer: currentWord.english
                            )
                        }
                    }
                }
                .padding(.horizontal, AtlasLayout.screenPadding)
                .padding(.top, 20)
                .padding(.bottom, 132)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if let lastAnswerWasCorrect {
                feedbackBar(isCorrect: lastAnswerWasCorrect)
            }
        }
    }

    private var practiceHeader: some View {
        VStack(spacing: 13) {
            HStack(spacing: 12) {
                Button {
                    AtlasHaptics.tap()
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 19, weight: .black))
                        .foregroundStyle(.black)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.black.opacity(0.08))

                        Capsule()
                            .fill(AtlasColors.green)
                            .frame(width: proxy.size.width * progressWidth)
                    }
                }
                .frame(height: 10)

                HStack(spacing: 3) {
                    ForEach(0..<3, id: \.self) { heart in
                        Image(systemName: heart < hearts ? "heart.fill" : "heart")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(heart < hearts ? AtlasColors.coral : .black.opacity(0.25))
                    }
                }
                .frame(width: 66)
            }

            HStack {
                CapsuleMetric(icon: "bolt.fill", title: "\(sessionXP) XP")
                Spacer()
                CapsuleMetric(icon: "flag.checkered", title: "\(profile.currentLevel.tag) \(profile.score0To160)")
                Spacer()
                CapsuleMetric(icon: "bookmark", title: "\(min(index + 1, practiceWords.count))/\(practiceWords.count)")
            }
            .colorScheme(.dark)
        }
        .padding(.horizontal, AtlasLayout.screenPadding)
        .padding(.top, 12)
        .padding(.bottom, 6)
    }

    private var progressWidth: CGFloat {
        guard !practiceWords.isEmpty else { return 0 }
        let answeredBoost = lastAnswerWasCorrect == nil ? 0.0 : 1.0
        return CGFloat(min((Double(index) + answeredBoost) / Double(practiceWords.count), 1))
    }

    private var focusWordCard: some View {
        VStack(spacing: 11) {
            HStack {
                CapsuleMetric(icon: "graduationcap", title: "\(currentWord.level.tag) \(currentWord.level.title(for: language))")
                    .colorScheme(.dark)
                Spacer()
                CapsuleMetric(icon: "chart.line.uptrend.xyaxis", title: "\(profile.wordProgress[currentWord.id]?.mastery ?? 0)%")
                    .colorScheme(.dark)
            }

            Text(currentWord.english)
                .font(.system(size: 44, weight: .black, design: .serif))
                .minimumScaleFactor(0.62)
                .lineLimit(1)

            Text(currentWord.russian)
                .font(.system(size: 20, weight: .black, design: .rounded))

            Text(currentWord.definition(for: language))
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.black.opacity(0.62))
                .multilineTextAlignment(.center)
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(AtlasColors.mint.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 27, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 27, style: .continuous)
                .stroke(AtlasColors.line, lineWidth: 2.4)
        )
        .shadow(color: AtlasColors.line, radius: 0, y: 6)
    }

    private func modeCard(_ mode: PracticeMode) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: mode.icon)
                .font(.system(size: 26, weight: .black))
                .frame(width: 46, height: 46)
                .background(Circle().fill(AtlasColors.mint.opacity(0.55)))

            Spacer(minLength: 2)

            Text(mode.title(for: language))
                .font(.system(size: 19, weight: .black, design: .rounded))
                .lineLimit(2)
                .minimumScaleFactor(0.78)

            Text(mode.subtitle(for: language))
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.black.opacity(0.58))
                .lineLimit(3)
        }
        .foregroundStyle(.black)
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 168, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.black.opacity(0.72), lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.58), radius: 0, y: 5)
    }

    private var dueStrip: some View {
        HStack(spacing: 12) {
            miniMetric(
                icon: "clock.arrow.circlepath",
                title: language.text(ru: "К повторению", en: "Due"),
                value: "\(profile.dueWordsCount)"
            )
            miniMetric(
                icon: "exclamationmark.bubble",
                title: language.text(ru: "Слабые", en: "Weak"),
                value: "\(profile.weakWordIDs.count)"
            )
        }
    }

    private func miniMetric(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .black))
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                Text(title)
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(.black.opacity(0.58))
            }
            Spacer()
        }
        .foregroundStyle(.black)
        .padding(13)
        .frame(maxWidth: .infinity)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AtlasColors.line, lineWidth: 2)
        )
    }

    private func choiceChallenge(
        prompt: String,
        hero: String,
        detail: String,
        choices: [String],
        correctAnswer: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(prompt)
                .font(.system(size: 19, weight: .black, design: .rounded))
                .foregroundStyle(.black)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 10) {
                Text(hero)
                    .font(.system(size: hero.count > 12 ? 38 : 46, weight: .black, design: .serif))
                    .foregroundStyle(.black)
                    .minimumScaleFactor(0.55)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                Text(detail)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.black.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 25)
            .padding(.horizontal, 12)
            .background(AtlasColors.mint.opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(AtlasColors.line, lineWidth: 2.5)
            )
            .shadow(color: AtlasColors.line, radius: 0, y: 6)

            VStack(spacing: 12) {
                ForEach(choices, id: \.self) { choice in
                    answerButton(choice, correctAnswer: correctAnswer)
                }
            }

            Button {
                selectAnswer("", correctAnswer: correctAnswer)
            } label: {
                Text(language.text(ru: "Не помню", en: "I do not remember"))
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(.black.opacity(0.64))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
            .disabled(selectedChoice != nil)
        }
    }

    private var sentenceBuilderChallenge: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(language.text(ru: "Собери предложение", en: "Build the sentence"))
                .font(.system(size: 19, weight: .black, design: .rounded))
                .foregroundStyle(.black)

            VStack(alignment: .leading, spacing: 10) {
                Text(currentWord.exampleRU)
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(.black.opacity(0.62))

                Text(selectedTiles.isEmpty ? " " : selectedTiles.joined(separator: " "))
                    .font(.system(size: 24, weight: .black, design: .serif))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity, minHeight: 86, alignment: .topLeading)
                    .padding(14)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 23, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 23, style: .continuous)
                            .stroke(AtlasColors.line, lineWidth: 2)
                    )
            }
            .padding(16)
            .background(AtlasColors.mint.opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(AtlasColors.line, lineWidth: 2.5)
            )
            .shadow(color: AtlasColors.line, radius: 0, y: 6)

            FlexibleTileWrap(items: remainingTiles) { tile in
                Button {
                    chooseTile(tile)
                } label: {
                    Text(tile)
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(AtlasColors.line, lineWidth: 2)
                        )
                        .shadow(color: AtlasColors.line, radius: 0, y: 4)
                }
                .buttonStyle(.plain)
                .disabled(lastAnswerWasCorrect != nil)
            }

            HStack(spacing: 12) {
                Button {
                    resetTiles()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(.black)
                        .frame(width: 52, height: 52)
                        .background(Circle().fill(.white))
                        .overlay(Circle().stroke(AtlasColors.line, lineWidth: 2))
                }
                .buttonStyle(.plain)
                .disabled(selectedTiles.isEmpty || lastAnswerWasCorrect != nil)

                Button {
                    submitSentence()
                } label: {
                    Text(language.text(ru: "Проверить", en: "Check"))
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(remainingTiles.isEmpty ? AtlasColors.ink : Color.black.opacity(0.28))
                        .clipShape(RoundedRectangle(cornerRadius: 19, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!remainingTiles.isEmpty || lastAnswerWasCorrect != nil)
            }
        }
    }

    private func answerButton(_ choice: String, correctAnswer: String) -> some View {
        let isSelected = selectedChoice == choice
        let isCorrectChoice = choice == correctAnswer
        let fill: Color = {
            guard selectedChoice != nil else { return .white }
            if isSelected && isCorrectChoice { return AtlasColors.green.opacity(0.28) }
            if isSelected && !isCorrectChoice { return AtlasColors.coral.opacity(0.35) }
            if isCorrectChoice { return AtlasColors.green.opacity(0.18) }
            return .white
        }()

        return Button {
            selectAnswer(choice, correctAnswer: correctAnswer)
        } label: {
            HStack(spacing: 10) {
                Text(choice)
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(.black)
                    .lineLimit(2)
                    .minimumScaleFactor(0.74)

                Spacer()

                if selectedChoice != nil {
                    Image(systemName: isCorrectChoice ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(isCorrectChoice ? AtlasColors.green : .black.opacity(0.18))
                }
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 15)
            .background(fill)
            .clipShape(RoundedRectangle(cornerRadius: 21, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 21, style: .continuous)
                    .stroke(AtlasColors.line, lineWidth: 2)
            )
            .shadow(color: AtlasColors.line, radius: 0, y: 5)
        }
        .buttonStyle(.plain)
        .disabled(selectedChoice != nil)
    }

    private func feedbackBar(isCorrect: Bool) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 23, weight: .bold))

                VStack(alignment: .leading, spacing: 3) {
                    Text(isCorrect ? language.text(ru: "Верно", en: "Correct") : language.text(ru: "Запомним это слово", en: "We will remember this word"))
                        .font(.system(size: 17, weight: .black, design: .rounded))

                    Text(lastAnswerText)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .opacity(0.78)
                        .lineLimit(2)
                }

                Spacer()
            }

            Button {
                AtlasHaptics.tap()
                continuePractice()
            } label: {
                Text(language.text(ru: "Продолжить", en: "Continue"))
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(isCorrect ? AtlasColors.green : AtlasColors.ink)
                    .clipShape(RoundedRectangle(cornerRadius: 19, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(.black)
        .padding(.horizontal, AtlasLayout.screenPadding)
        .padding(.vertical, 16)
        .background(AtlasColors.paper)
        .overlay(Rectangle().fill(.black.opacity(0.08)).frame(height: 1), alignment: .top)
    }

    private var completionView: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                TinyDotsShadow()
                    .frame(width: 144, height: 68)
                    .offset(y: 42)

                Circle()
                    .fill(AtlasColors.mint)
                    .frame(width: 120, height: 120)
                    .overlay(Circle().stroke(.black, lineWidth: 3))
                    .shadow(color: AtlasColors.line, radius: 0, y: 8)

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 60, weight: .black))
                    .foregroundStyle(.black)
            }

            Text(language.text(ru: "Тренировка завершена", en: "Practice complete"))
                .font(.system(size: 30, weight: .black, design: .serif))
                .foregroundStyle(.black)
                .multilineTextAlignment(.center)

            Text(language.text(
                ru: "Слова пересортированы: слабые вернутся раньше, уверенные уйдут дальше по расписанию.",
                en: "Words were resorted: weak words return sooner, strong words move further out."
            ))
            .font(.system(size: 15, weight: .medium, design: .rounded))
            .foregroundStyle(.black.opacity(0.62))
            .multilineTextAlignment(.center)
            .lineSpacing(4)

            HStack(spacing: 12) {
                finishMetric(title: "XP", value: "+\(sessionXP)", icon: "bolt.fill")
                finishMetric(title: language.text(ru: "Уровень", en: "Level"), value: profile.currentLevel.tag, icon: "flag.checkered")
            }
            .padding(.top, 6)

            Button {
                AtlasHaptics.tap()
                dismiss()
            } label: {
                Text(language.text(ru: "Вернуться к словам", en: "Back to words"))
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(AtlasColors.ink)
                    .clipShape(RoundedRectangle(cornerRadius: 21, style: .continuous))
                    .shadow(color: .black.opacity(0.36), radius: 0, y: 5)
            }
            .buttonStyle(.plain)
            .padding(.top, 6)

            Spacer()
        }
        .padding(.horizontal, AtlasLayout.screenPadding)
        .padding(.vertical, 20)
    }

    private func finishMetric(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(AtlasColors.green)

            Text(value)
                .font(.system(size: 25, weight: .black, design: .rounded))

            Text(title)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(.black.opacity(0.58))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 21, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 21, style: .continuous)
                .stroke(AtlasColors.line, lineWidth: 2)
        )
        .shadow(color: AtlasColors.line, radius: 0, y: 5)
    }

    private func alignStartWord() {
        guard let startWordID,
              let startIndex = practiceWords.firstIndex(where: { $0.id == startWordID })
        else {
            return
        }

        index = startIndex
    }

    private func startChallenge(_ mode: PracticeMode) {
        AtlasHaptics.selection()
        withAnimation(.atlasSpring) {
            selectedMode = mode
            selectedChoice = nil
            selectedTiles = []
            lastAnswerWasCorrect = nil
            lastAnswerText = ""
            remainingTiles = mode == .sentenceBuilder ? WordBank.sentenceTiles(for: currentWord) : []
        }
    }

    private func selectAnswer(_ choice: String, correctAnswer: String) {
        guard selectedChoice == nil, let selectedMode else { return }

        let isCorrect = choice == correctAnswer
        commitAnswer(isCorrect: isCorrect, mode: selectedMode)

        withAnimation(.atlasSpring) {
            selectedChoice = choice
            lastAnswerWasCorrect = isCorrect
            lastAnswerText = "\(currentWord.english) - \(currentWord.russian)"
        }
    }

    private func chooseTile(_ tile: String) {
        guard let index = remainingTiles.firstIndex(of: tile) else { return }
        AtlasHaptics.selection()
        withAnimation(.atlasSpring) {
            selectedTiles.append(tile)
            remainingTiles.remove(at: index)
        }
    }

    private func resetTiles() {
        AtlasHaptics.tap()
        withAnimation(.atlasSpring) {
            selectedTiles = []
            remainingTiles = WordBank.sentenceTiles(for: currentWord)
        }
    }

    private func submitSentence() {
        guard selectedMode == .sentenceBuilder, lastAnswerWasCorrect == nil else { return }
        let answer = selectedTiles.joined(separator: " ")
        let correct = WordBank.sentenceAnswer(for: currentWord)
        let isCorrect = answer == correct
        commitAnswer(isCorrect: isCorrect, mode: .sentenceBuilder)

        withAnimation(.atlasSpring) {
            lastAnswerWasCorrect = isCorrect
            lastAnswerText = correct
        }
    }

    private func commitAnswer(isCorrect: Bool, mode: PracticeMode) {
        if isCorrect {
            AtlasHaptics.success()
        } else {
            AtlasHaptics.error()
            hearts = max(0, hearts - 1)
        }

        let xp = profile.recordPractice(word: currentWord, mode: mode, isCorrect: isCorrect)
        sessionXP += xp
    }

    private func continuePractice() {
        withAnimation(.atlasSpring) {
            selectedChoice = nil
            selectedTiles = []
            remainingTiles = []
            lastAnswerWasCorrect = nil
            lastAnswerText = ""
            selectedMode = nil
        }

        if hearts == 0 || index >= practiceWords.count - 1 {
            finishSession()
        } else {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
                index += 1
            }
        }
    }

    private func finishSession() {
        AtlasHaptics.success()
        withAnimation(.atlasSoftSpring) {
            isFinished = true
        }
    }
}

struct FlexibleTileWrap<Content: View>: View {
    let items: [String]
    @ViewBuilder let content: (String) -> Content

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 10)], alignment: .leading, spacing: 10) {
            ForEach(items, id: \.self) { item in
                content(item)
            }
        }
    }
}
