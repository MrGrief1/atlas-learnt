//
//  OnboardingView.swift
//  Atlas learn
//

import SwiftUI

struct OnboardingView: View {
    let onComplete: (AtlasProfile) -> Void

    @State private var page = 0
    @State private var appLanguage: AppLanguage = .russian
    @State private var selectedLevel: LearningLevel = .elementary
    @State private var dailyGoal = 5
    @State private var selectedTopics = Set(["Everyday", "Work", "Emotions"])
    @State private var quizIndex = 0
    @State private var knownCount = 0
    @State private var unknownWordIDs = Set<String>()

    private let quizWords = WordBank.assessmentWords

    var body: some View {
        ZStack {
            AtlasColors.paper
                .ignoresSafeArea()

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
                        .fill(AtlasColors.green)
                        .frame(width: proxy.size.width * CGFloat(min(Double(page + 1) / 6.0, 1)))
                }
            }
            .frame(height: 8)
        }
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
                    ru: "Это стартовая оценка. Дальше короткий тест уточнит слова, которые ты не знаешь.",
                    en: "This is the starting point. A short test will refine the words you do not know."
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
                    ru: "Начнем мягко: ежедневный набор будет обновляться и попадать в тренировку.",
                    en: "We will keep it light: your daily set refreshes and feeds practice."
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
                    ru: "Выбери несколько направлений. Это влияет на ежедневный набор.",
                    en: "Choose a few areas. This shapes your daily set."
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

            primaryButton(title: appLanguage.text(ru: "Начать мини-тест", en: "Start mini test")) {
                goToPage(4)
            }
            .disabled(selectedTopics.isEmpty)
            .opacity(selectedTopics.isEmpty ? 0.5 : 1)
        }
    }

    private var quizPage: some View {
        let word = quizWords[quizIndex]

        return VStack(alignment: .leading, spacing: 18) {
            onboardingTitle(
                appLanguage.text(ru: "Выбери перевод", en: "Choose the translation"),
                subtitle: appLanguage.text(
                    ru: "Так приложение поймет, какие слова уже знакомы, а какие добавить в тренировку.",
                    en: "This tells the app what you know and what should go into practice."
                )
            )

            VStack(spacing: 10) {
                Text(word.english)
                    .font(.system(size: 40, weight: .black, design: .serif))
                    .foregroundStyle(.black)

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
                    OutlineButton(
                        title: choice,
                        subtitle: nil,
                        isSelected: false,
                        icon: nil
                    ) {
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
                    ru: "Уровень скорректирован по ответам, а незнакомые слова попадут в ежедневный набор.",
                    en: "Your level was calibrated, and unknown words will enter the daily set."
                )
            )

            let calibratedLevel = LearningLevel.calibrated(
                from: selectedLevel,
                knownCount: knownCount,
                total: quizWords.count
            )

            VStack(alignment: .leading, spacing: 13) {
                summaryRow(
                    icon: "chart.bar",
                    title: appLanguage.text(ru: "Уровень", en: "Level"),
                    value: "\(calibratedLevel.tag) \(calibratedLevel.title(for: appLanguage))"
                )
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
                finishOnboarding(level: calibratedLevel)
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
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(AtlasColors.ink)
                .clipShape(RoundedRectangle(cornerRadius: 21, style: .continuous))
                .shadow(color: .black.opacity(0.35), radius: 0, y: 5)
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
        let word = quizWords[quizIndex]

        if isCorrect {
            AtlasHaptics.success()
            knownCount += 1
        } else {
            AtlasHaptics.warning()
            unknownWordIDs.insert(word.id)
        }

        if quizIndex < quizWords.count - 1 {
            withAnimation(.atlasSpring) {
                quizIndex += 1
            }
        } else {
            goToPage(5)
        }
    }

    private func finishOnboarding(level: LearningLevel) {
        AtlasHaptics.success()
        var unknown = Array(unknownWordIDs)

        if unknown.isEmpty {
            unknown = WordBank.all
                .filter { $0.level.order <= min(level.order + 1, LearningLevel.advanced.order) }
                .prefix(3)
                .map(\.id)
        }

        let profile = AtlasProfile(
            appLanguage: appLanguage,
            level: level,
            dailyGoal: dailyGoal,
            selectedTopics: Array(selectedTopics),
            unknownWordIDs: unknown,
            savedWordIDs: [],
            favoriteWordIDs: [],
            completedTodayIDs: [],
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

    private func levelSubtitle(_ level: LearningLevel) -> String {
        switch level {
        case .beginner:
            appLanguage.text(ru: "Знаю простые фразы", en: "I know simple phrases")
        case .elementary:
            appLanguage.text(ru: "Могу читать короткие тексты", en: "I can read short texts")
        case .intermediate:
            appLanguage.text(ru: "Понимаю смысл, но не все нюансы", en: "I understand meaning, not every nuance")
        case .upperIntermediate:
            appLanguage.text(ru: "Хочу точнее говорить и писать", en: "I want sharper speaking and writing")
        case .advanced:
            appLanguage.text(ru: "Ищу редкие и точные слова", en: "I want rare, precise words")
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
        default: "square.grid.2x2"
        }
    }
}
