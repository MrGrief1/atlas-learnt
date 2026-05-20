//
//  OnboardingView.swift
//  Atlas learn
//

import SwiftUI

struct OnboardingView: View {
    let onComplete: (AtlasProfile) -> Void

    @State private var page = 0
    @State private var appLanguage: AppLanguage = .russian
    @State private var selectedLevel: LearningLevel = .a2
    @State private var dailyGoal = 7
    @State private var selectedTopics = Set(["Everyday", "Work", "Study"])
    @State private var quizIndex = 0
    @State private var correctAnswers = 0
    @State private var adaptiveScore = LearningLevel.a2.scoreStart
    @State private var unknownWordIDs = Set<String>()
    @State private var askedWordIDs = Set<String>()

    private let quizLimit = 28

    private var currentAssessmentLevel: LearningLevel {
        LearningLevel.from(score: adaptiveScore)
    }

    private var currentQuizWord: WordEntry {
        let levelWords = WordBank.all.filter {
            $0.level == currentAssessmentLevel &&
                !askedWordIDs.contains($0.id) &&
                WordBank.isAssessmentReady($0)
        }
        let fallback = WordBank.all.filter { $0.level == currentAssessmentLevel && WordBank.isAssessmentReady($0) }
        return WordBank.rotated(levelWords.isEmpty ? fallback : levelWords, seed: adaptiveScore + quizIndex * 13).first
            ?? WordBank.assessmentWords.first
            ?? WordBank.all[0]
    }

    var body: some View {
        ZStack {
            AtlasColors.paper.ignoresSafeArea()

            VStack(spacing: 0) {
                progressHeader

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 21) {
                        switch page {
                        case 0:
                            languagePage
                        case 1:
                            levelPage
                        case 2:
                            goalPage
                        case 3:
                            topicsPage
                        case 4:
                            quizPage
                        default:
                            resultPage
                        }
                    }
                    .padding(.horizontal, AtlasLayout.screenPadding)
                    .padding(.top, 16)
                    .padding(.bottom, 30)
                }
            }
        }
        .atlasMotion(page)
        .atlasSoftMotion(appLanguage)
        .atlasMotion(selectedLevel)
        .atlasMotion(dailyGoal)
        .atlasMotion(selectedTopics)
        .atlasMotion(quizIndex)
        .atlasMotion(adaptiveScore)
    }

    private var progressHeader: some View {
        VStack(spacing: 14) {
            HStack {
                Text(appLanguage.text(ru: "Atlas Learn", en: "Atlas Learn"))
                    .font(.system(size: 16, weight: .black, design: .rounded))

                Spacer()

                Text("\(min(page + 1, 6))/6")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.black.opacity(0.08))

                    Capsule()
                        .fill(.black)
                        .frame(width: proxy.size.width * CGFloat(min(Double(page + 1) / 6.0, 1)))
                }
            }
            .frame(height: 8)
        }
        .foregroundStyle(.black)
        .padding(.horizontal, AtlasLayout.screenPadding)
        .padding(.top, 14)
        .padding(.bottom, 8)
    }

    private var languagePage: some View {
        VStack(alignment: .leading, spacing: 16) {
            onboardingTitle(
                appLanguage.text(ru: "Выбери язык приложения", en: "Choose app language"),
                subtitle: appLanguage.text(
                    ru: "Слова будут в паре English - Русский. Интерфейс можно переключать в профиле.",
                    en: "Words will be paired English - Russian. You can switch the interface later."
                )
            )

            ForEach(AppLanguage.allCases) { language in
                OutlineButton(
                    title: language.nativeTitle,
                    subtitle: language == .russian ? "Русский интерфейс" : "English interface",
                    isSelected: appLanguage == language,
                    icon: language == .russian ? "textformat" : "character.book.closed"
                ) {
                    withAnimation(.atlasSpring) {
                        appLanguage = language
                    }
                }
            }

            primaryButton(title: appLanguage.text(ru: "Продолжить", en: "Continue")) {
                goToPage(1)
            }
        }
    }

    private var levelPage: some View {
        VStack(alignment: .leading, spacing: 14) {
            onboardingTitle(
                appLanguage.text(ru: "Какой у тебя уровень?", en: "What is your level?"),
                subtitle: appLanguage.text(
                    ru: "Это стартовая оценка. Дальше адаптивный тест уточнит CEFR и Atlas Score.",
                    en: "This is the starting point. An adaptive test will refine CEFR and Atlas Score."
                )
            )

            ForEach(LearningLevel.allCases) { level in
                OutlineButton(
                    title: "\(level.tag)  \(level.title(for: appLanguage))",
                    subtitle: levelSubtitle(level),
                    isSelected: selectedLevel == level,
                    icon: "graduationcap"
                ) {
                    withAnimation(.atlasSpring) {
                        selectedLevel = level
                    }
                }
            }

            primaryButton(title: appLanguage.text(ru: "Дальше", en: "Next")) {
                goToPage(2)
            }
        }
    }

    private var goalPage: some View {
        VStack(alignment: .leading, spacing: 16) {
            onboardingTitle(
                appLanguage.text(ru: "Сколько слов давать каждый день?", en: "How many words per day?"),
                subtitle: appLanguage.text(
                    ru: "Цель влияет на капсулу сверху, статистику и размер ежедневного набора.",
                    en: "The goal drives the top capsule, stats, and daily word set size."
                )
            )

            HStack(spacing: 12) {
                ForEach([5, 7, 10], id: \.self) { amount in
                    Button {
                        AtlasHaptics.selection()
                        withAnimation(.atlasSpring) {
                            dailyGoal = amount
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Text("\(amount)")
                                .font(.system(size: 30, weight: .black, design: .rounded))
                            Text(appLanguage.text(ru: "слов", en: "words"))
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(dailyGoal == amount ? AtlasColors.mint : .white)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(AtlasColors.line, lineWidth: 2)
                        )
                        .shadow(color: AtlasColors.line, radius: 0, y: 5)
                    }
                    .buttonStyle(.plain)
                }
            }

            primaryButton(title: appLanguage.text(ru: "Выбрать темы", en: "Pick topics")) {
                goToPage(3)
            }
        }
    }

    private var topicsPage: some View {
        VStack(alignment: .leading, spacing: 14) {
            onboardingTitle(
                appLanguage.text(ru: "Какие слова тебе нужны?", en: "Which words do you need?"),
                subtitle: appLanguage.text(
                    ru: "Темы влияют на ежедневный набор и сортировку новых слов.",
                    en: "Topics shape the daily set and new-word sorting."
                )
            )

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(WordBank.topics, id: \.self) { topic in
                    Button {
                        AtlasHaptics.selection()
                        withAnimation(.atlasSpring) {
                            if selectedTopics.contains(topic) {
                                selectedTopics.remove(topic)
                            } else {
                                selectedTopics.insert(topic)
                            }
                        }
                    } label: {
                        VStack(spacing: 10) {
                            TopicMiniIllustration(icon: topicIcon(topic))
                                .scaleEffect(0.74)
                                .frame(height: 76)

                            Text(WordBank.topicTitle(topic, for: appLanguage))
                                .font(.system(size: 15, weight: .black, design: .rounded))
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background(selectedTopics.contains(topic) ? AtlasColors.mint.opacity(0.9) : .white)
                        .clipShape(RoundedRectangle(cornerRadius: 21, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 21, style: .continuous)
                                .stroke(AtlasColors.line, lineWidth: 2)
                        )
                        .shadow(color: AtlasColors.line, radius: 0, y: 5)
                    }
                    .buttonStyle(.plain)
                }
            }

            primaryButton(title: appLanguage.text(ru: "Начать тест", en: "Start test")) {
                startAssessment()
            }
            .disabled(selectedTopics.isEmpty)
            .opacity(selectedTopics.isEmpty ? 0.5 : 1)
        }
    }

    private var quizPage: some View {
        let word = currentQuizWord

        return VStack(alignment: .leading, spacing: 18) {
            onboardingTitle(
                appLanguage.text(ru: "Выбери перевод", en: "Choose the translation"),
                subtitle: appLanguage.text(
                    ru: "Вопрос \(quizIndex + 1)/\(quizLimit). Сейчас сложность: \(currentAssessmentLevel.tag).",
                    en: "Question \(quizIndex + 1)/\(quizLimit). Current difficulty: \(currentAssessmentLevel.tag)."
                )
            )

            VStack(spacing: 10) {
                Text(word.english)
                    .font(.system(size: 40, weight: .black, design: .serif))
                    .foregroundStyle(.black)
                    .minimumScaleFactor(0.65)
                    .lineLimit(1)

                Text(word.ipa)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.black.opacity(0.58))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(.black.opacity(0.06)))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(AtlasColors.mint.opacity(0.55))
            .clipShape(RoundedRectangle(cornerRadius: 27, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 27, style: .continuous)
                    .stroke(AtlasColors.line, lineWidth: 2.3)
            )
            .shadow(color: AtlasColors.line, radius: 0, y: 6)

            VStack(spacing: 12) {
                ForEach(WordBank.translationChoices(for: word), id: \.self) { choice in
                    OutlineButton(title: choice, subtitle: nil, isSelected: false, icon: nil) {
                        answerQuiz(choice == word.russian)
                    }
                }
            }

            Button {
                answerQuiz(false)
            } label: {
                Text(appLanguage.text(ru: "Не знаю это слово", en: "I do not know this word"))
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(.black.opacity(0.72))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
        }
    }

    private var resultPage: some View {
        VStack(alignment: .leading, spacing: 18) {
            onboardingTitle(
                appLanguage.text(ru: "Готово. Я собрал твой старт.", en: "Done. Your start is ready."),
                subtitle: appLanguage.text(
                    ru: "Уровень и Atlas Score рассчитаны по адаптивному тесту. Ошибки сразу попадут в повторение.",
                    en: "Your level and Atlas Score are based on the adaptive test. Mistakes go straight to review."
                )
            )

            VStack(alignment: .leading, spacing: 13) {
                summaryRow(
                    icon: "chart.bar",
                    title: appLanguage.text(ru: "Уровень", en: "Level"),
                    value: "\(currentAssessmentLevel.tag) \(currentAssessmentLevel.title(for: appLanguage))"
                )
                summaryRow(icon: "flag.checkered", title: "Atlas Score", value: "\(adaptiveScore)/160")
                summaryRow(
                    icon: "bookmark",
                    title: appLanguage.text(ru: "Слов в день", en: "Words per day"),
                    value: "\(dailyGoal)"
                )
                summaryRow(
                    icon: "exclamationmark.bubble",
                    title: appLanguage.text(ru: "Незнакомые слова", en: "Unknown words"),
                    value: "\(unknownWordIDs.count)"
                )
            }
            .padding(16)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 25, style: .continuous)
                    .stroke(AtlasColors.line, lineWidth: 2.2)
            )
            .shadow(color: AtlasColors.line, radius: 0, y: 6)

            primaryButton(title: appLanguage.text(ru: "Открыть слова дня", en: "Open daily words")) {
                finishOnboarding(level: currentAssessmentLevel, score: adaptiveScore)
            }
        }
    }

    private func onboardingTitle(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 30, weight: .black, design: .serif))
                .foregroundStyle(.black)
                .fixedSize(horizontal: false, vertical: true)

            Text(subtitle)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.black.opacity(0.62))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func primaryButton(title: String, action: @escaping () -> Void) -> some View {
        Button {
            AtlasHaptics.tap()
            action()
        } label: {
            Text(title)
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(AtlasColors.mint)
                .clipShape(RoundedRectangle(cornerRadius: 21, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 21, style: .continuous)
                        .stroke(AtlasColors.line, lineWidth: 2)
                )
                .shadow(color: AtlasColors.line, radius: 0, y: 5)
        }
        .buttonStyle(.plain)
        .padding(.top, 6)
    }

    private func summaryRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .bold))
                .frame(width: 30, height: 30)
                .background(Circle().fill(AtlasColors.mint.opacity(0.55)))

            Text(title)
                .font(.system(size: 15, weight: .heavy, design: .rounded))

            Spacer()

            Text(value)
                .font(.system(size: 15, weight: .black, design: .rounded))
        }
        .foregroundStyle(.black)
    }

    private func answerQuiz(_ isCorrect: Bool) {
        let word = currentQuizWord
        askedWordIDs.insert(word.id)

        if isCorrect {
            AtlasHaptics.success()
            correctAnswers += 1
            adaptiveScore = min(160, adaptiveScore + 4 + max(0, word.level.order - selectedLevel.order))
        } else {
            AtlasHaptics.warning()
            unknownWordIDs.insert(word.id)
            adaptiveScore = max(0, adaptiveScore - 4)
        }

        if quizIndex < quizLimit - 1 {
            withAnimation(.atlasSpring) {
                quizIndex += 1
            }
        } else {
            goToPage(5)
        }
    }

    private func finishOnboarding(level: LearningLevel, score: Int) {
        AtlasHaptics.success()
        var unknown = Array(unknownWordIDs)

        if unknown.isEmpty {
            unknown = WordBank.all
                .filter { $0.level.order <= min(level.order + 1, LearningLevel.c2.order) }
                .prefix(3)
                .map(\.id)
        }

        let weakMemory = WordMemory(correctCount: 0, wrongCount: 1, streak: 0, mastery: 0, lastPracticedAt: nil, dueAt: Date())
        let profile = AtlasProfile(
            appLanguage: appLanguage,
            currentLevel: level,
            score0To160: score,
            dailyGoal: dailyGoal,
            selectedTopics: Array(selectedTopics),
            unknownWordIDs: unknown,
            savedWordIDs: [],
            favoriteWordIDs: [],
            completedTodayIDs: [],
            wordProgress: Dictionary(uniqueKeysWithValues: unknown.map { ($0, weakMemory) }),
            dailyProgress: [:],
            practiceHistory: [],
            streak: 0,
            xp: 0
        )

        onComplete(profile)
    }

    private func goToPage(_ nextPage: Int) {
        withAnimation(.atlasSpring) {
            page = nextPage
        }
    }

    private func startAssessment() {
        adaptiveScore = selectedLevel.scoreStart + 8
        quizIndex = 0
        correctAnswers = 0
        unknownWordIDs = []
        askedWordIDs = []
        goToPage(4)
    }

    private func levelSubtitle(_ level: LearningLevel) -> String {
        switch level {
        case .a1:
            appLanguage.text(ru: "Знаю простые фразы", en: "I know simple phrases")
        case .a2:
            appLanguage.text(ru: "Могу читать короткие тексты", en: "I can read short texts")
        case .b1:
            appLanguage.text(ru: "Понимаю смысл, но не все нюансы", en: "I understand meaning, not every nuance")
        case .b2:
            appLanguage.text(ru: "Хочу точнее говорить и писать", en: "I want sharper speaking and writing")
        case .c1:
            appLanguage.text(ru: "Ищу редкие и точные слова", en: "I want rare, precise words")
        case .c2:
            appLanguage.text(ru: "Понимаю сложные оттенки смысла", en: "I understand subtle shades of meaning")
        }
    }

    private func topicIcon(_ topic: String) -> String {
        switch topic {
        case "Everyday": "house"
        case "Work": "briefcase"
        case "Study": "book.closed"
        case "Emotions": "heart"
        case "Travel": "map"
        case "Business": "chart.line.uptrend.xyaxis"
        case "Health": "cross.case"
        case "Tech": "cpu"
        case "Culture": "theatermasks"
        case "Nature": "leaf"
        default: "square.grid.2x2"
        }
    }
}
