//
//  StatsView.swift
//  Atlas learn
//

import SwiftUI

struct DailyProgressView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var profile: AtlasProfile
    let continueAction: () -> Void

    private var language: AppLanguage { profile.appLanguage }
    private var today: DailyProgress { profile.dailyProgress[AtlasProfile.todayKey()] ?? .empty(for: AtlasProfile.todayKey()) }
    private var progress: Double { Double(profile.completedTodayCount) / Double(max(profile.dailyGoal, 1)) }

    var body: some View {
        ZStack {
            AtlasColors.paper.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 14) {
                    Button {
                        AtlasHaptics.tap()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .black))
                            .foregroundStyle(.black)
                            .frame(width: 42, height: 42)
                            .background(Circle().fill(.white))
                            .overlay(Circle().stroke(.black, lineWidth: 2))
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(language.text(ru: "Сегодня", en: "Today"))
                            .font(.system(size: 31, weight: .black, design: .serif))
                        Text("\(profile.currentLevel.tag) · \(profile.score0To160)/160")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(.black.opacity(0.6))
                    }

                    Spacer()
                }

                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(profile.completedTodayCount)")
                            .font(.system(size: 50, weight: .black, design: .rounded))
                        Text("/ \(profile.dailyGoal)")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(.black.opacity(0.58))
                        Spacer()
                        Image(systemName: "flag.checkered")
                            .font(.system(size: 29, weight: .black))
                    }

                    progressBar(progress)

                    HStack(spacing: 10) {
                        dailyMetric(icon: "clock.arrow.circlepath", title: language.text(ru: "Повторить", en: "Due"), value: "\(profile.dueWordsCount)")
                        dailyMetric(icon: "target", title: language.text(ru: "Точность", en: "Accuracy"), value: percent(today.accuracy))
                    }
                }
                .padding(17)
                .cardSurface(cornerRadius: 25)

                Button {
                    AtlasHaptics.tap()
                    dismiss()
                    continueAction()
                } label: {
                    HStack(spacing: 9) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 15, weight: .black))
                        Text(language.text(ru: "Продолжить тренировку", en: "Continue practice"))
                            .font(.system(size: 17, weight: .black, design: .rounded))
                    }
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

                Spacer()
            }
            .foregroundStyle(.black)
            .padding(.horizontal, AtlasLayout.screenPadding)
            .padding(.top, 22)
        }
        .onAppear { profile.prepareForToday() }
    }

    private func dailyMetric(icon: String, title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 19, weight: .black))
            Text(value)
                .font(.system(size: 25, weight: .black, design: .rounded))
            Text(title)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(.black.opacity(0.58))
        }
        .foregroundStyle(.black)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AtlasColors.mint.opacity(0.32))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AtlasColors.line, lineWidth: 1.8)
        )
    }
}

struct StatsView: View {
    @Environment(\.dismiss) private var dismiss

    let profile: AtlasProfile

    private var language: AppLanguage { profile.appLanguage }
    private var today: DailyProgress { profile.dailyProgress[AtlasProfile.todayKey()] ?? .empty(for: AtlasProfile.todayKey()) }
    private var recentDays: [DailyProgress] {
        let calendar = Calendar(identifier: .gregorian)
        return (0..<7).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: Date()) ?? Date()
            let key = AtlasProfile.todayKey(date: date)
            return profile.dailyProgress[key] ?? .empty(for: key)
        }
    }
    private var weakWords: [WordEntry] {
        Array(profile.weakWordIDs.compactMap { id in
            WordBank.all.first { $0.id == id }
        }.prefix(6))
    }
    private var nextReviewTitle: String {
        profile.dueWordsCount > 0 ? language.text(ru: "Сейчас", en: "Now") : language.text(ru: "Позже", en: "Later")
    }

    var body: some View {
        ZStack {
            AtlasColors.paper.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    scorePanel
                    dailyPanel

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        statCard(icon: "flame.fill", title: language.text(ru: "Серия", en: "Streak"), value: "\(profile.streak)")
                        statCard(icon: "bolt.fill", title: "XP", value: "\(profile.xp)")
                        statCard(icon: "target", title: language.text(ru: "Точность", en: "Accuracy"), value: percent(profile.overallAccuracy))
                        statCard(icon: "exclamationmark.bubble", title: language.text(ru: "Слабые", en: "Weak"), value: "\(profile.weakWordIDs.count)")
                    }

                    sectionTitle(language.text(ru: "Последние 7 дней", en: "Last 7 days"))
                    weekChart

                    sectionTitle(language.text(ru: "Уровни", en: "Levels"))
                    levelDistribution

                    sectionTitle(language.text(ru: "Режимы", en: "Modes"))
                    modeAccuracy

                    sectionTitle(language.text(ru: "Слабые слова", en: "Weak words"))
                    weakWordsPanel

                    sectionTitle(language.text(ru: "История", en: "History"))
                    historyPanel
                }
                .padding(.horizontal, AtlasLayout.screenPadding)
                .padding(.top, 20)
                .padding(.bottom, 30)
            }
        }
        .foregroundStyle(.black)
    }

    private var header: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(language.text(ru: "Статистика", en: "Stats"))
                    .font(.system(size: 34, weight: .black, design: .serif))
                Text("\(profile.currentLevel.tag) · \(profile.score0To160)/160")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(.black.opacity(0.58))
            }

            Spacer()

            Button {
                AtlasHaptics.tap()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(.black)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(.white))
                    .overlay(Circle().stroke(.black, lineWidth: 2))
            }
            .buttonStyle(.plain)
        }
    }

    private var scorePanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("\(profile.currentLevel.tag) \(profile.currentLevel.title(for: language))")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                    Text(profile.currentLevel.shortCanDoRU)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.black.opacity(0.62))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Text("\(profile.score0To160)")
                    .font(.system(size: 42, weight: .black, design: .rounded))
            }

            progressBar(Double(profile.score0To160) / 160.0)
        }
        .padding(17)
        .background(AtlasColors.mint.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .stroke(AtlasColors.line, lineWidth: 2.3)
        )
        .shadow(color: AtlasColors.line, radius: 0, y: 6)
    }

    private var dailyPanel: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                Label(language.text(ru: "Сегодня", en: "Today"), systemImage: "flag.checkered")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                Spacer()
                Text("\(profile.completedTodayCount)/\(profile.dailyGoal)")
                    .font(.system(size: 18, weight: .black, design: .rounded))
            }

            progressBar(Double(profile.completedTodayCount) / Double(max(profile.dailyGoal, 1)))

            HStack(spacing: 10) {
                inlineMetric(title: language.text(ru: "Повторить", en: "Due"), value: "\(profile.dueWordsCount)")
                inlineMetric(title: language.text(ru: "Следующее", en: "Next"), value: nextReviewTitle)
                inlineMetric(title: language.text(ru: "Точность", en: "Accuracy"), value: percent(today.accuracy))
            }
        }
        .padding(16)
        .cardSurface(cornerRadius: 23)
    }

    private var weekChart: some View {
        let maxXP = max(recentDays.map(\.xp).max() ?? 0, 1)

        return HStack(alignment: .bottom, spacing: 9) {
            ForEach(recentDays) { day in
                VStack(spacing: 7) {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(day.xp > 0 ? .black : .black.opacity(0.12))
                        .frame(height: max(CGFloat(day.xp) / CGFloat(maxXP) * 92, 8))

                    Text(shortDay(day.dateKey))
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(.black.opacity(0.58))
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 132, alignment: .bottom)
        .padding(14)
        .cardSurface(cornerRadius: 23)
    }

    private var levelDistribution: some View {
        VStack(spacing: 11) {
            ForEach(LearningLevel.allCases) { level in
                let mastered = profile.wordProgress.filter { entry in
                    WordBank.all.first { $0.id == entry.key }?.level == level && entry.value.mastery >= 70
                }.count
                let total = WordBank.all.filter { $0.level == level }.count
                levelBar(level: level, mastered: mastered, total: total)
            }
        }
        .padding(14)
        .cardSurface(cornerRadius: 23)
    }

    private var modeAccuracy: some View {
        VStack(spacing: 10) {
            ForEach(PracticeMode.allCases) { mode in
                let records = profile.practiceHistory.filter { $0.mode == mode }
                let correct = records.filter(\.isCorrect).count
                let accuracy = records.isEmpty ? 0 : Double(correct) / Double(records.count)
                row(icon: mode.icon, title: mode.title(for: language), value: records.isEmpty ? "0" : percent(accuracy))
            }
        }
        .padding(14)
        .cardSurface(cornerRadius: 23)
    }

    private var weakWordsPanel: some View {
        VStack(spacing: 10) {
            if weakWords.isEmpty {
                emptyPanel(icon: "checkmark.seal", title: language.text(ru: "Пока слабых слов нет", en: "No weak words yet"))
            } else {
                ForEach(weakWords) { word in
                    row(
                        icon: "exclamationmark.bubble",
                        title: "\(word.english) · \(word.russian)",
                        value: "\(profile.wordProgress[word.id]?.mastery ?? 0)%"
                    )
                }
            }
        }
        .padding(14)
        .cardSurface(cornerRadius: 23)
    }

    private var historyPanel: some View {
        VStack(spacing: 10) {
            if profile.practiceHistory.isEmpty {
                emptyPanel(icon: "clock", title: language.text(ru: "История появится после тренировки", en: "History appears after practice"))
            } else {
                ForEach(profile.practiceHistory.prefix(8)) { record in
                    row(
                        icon: record.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill",
                        title: "\(record.wordEnglish) · \(record.mode.title(for: language))",
                        value: record.isCorrect ? "+\(record.xp)" : "0"
                    )
                }
            }
        }
        .padding(14)
        .cardSurface(cornerRadius: 23)
    }

    private func statCard(icon: String, title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 21, weight: .black))

            Text(value)
                .font(.system(size: 30, weight: .black, design: .rounded))

            Text(title)
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(.black.opacity(0.62))
        }
        .foregroundStyle(.black)
        .padding(15)
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
        .cardSurface(cornerRadius: 22)
    }

    private func levelBar(level: LearningLevel, mastered: Int, total: Int) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(level.tag)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                Text(level.title(for: language))
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(.black.opacity(0.62))
                Spacer()
                Text("\(mastered)/\(total)")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(.black.opacity(0.58))
            }

            progressBar(Double(mastered) / Double(max(total, 1)), height: 8)
        }
    }

    private func row(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .black))
                .frame(width: 34, height: 34)
                .background(Circle().fill(AtlasColors.mint.opacity(0.55)))

            Text(title)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Spacer()

            Text(value)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(.black.opacity(0.62))
        }
        .foregroundStyle(.black)
    }

    private func emptyPanel(icon: String, title: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .black))
                .frame(width: 34, height: 34)
                .background(Circle().fill(AtlasColors.mint.opacity(0.55)))

            Text(title)
                .font(.system(size: 15, weight: .black, design: .rounded))

            Spacer()
        }
        .foregroundStyle(.black)
        .padding(.vertical, 2)
    }

    private func inlineMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.system(size: 18, weight: .black, design: .rounded))
            Text(title)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(.black.opacity(0.58))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(AtlasColors.mint.opacity(0.34))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AtlasColors.line, lineWidth: 1.7)
        )
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 22, weight: .black, design: .rounded))
            .foregroundStyle(.black)
            .padding(.top, 4)
    }

    private func shortDay(_ key: String) -> String {
        String(key.suffix(5))
    }
}

private func progressBar(_ progress: Double, height: CGFloat = 11) -> some View {
    GeometryReader { proxy in
        ZStack(alignment: .leading) {
            Capsule().fill(.black.opacity(0.10))
            Capsule()
                .fill(.black)
                .frame(width: proxy.size.width * CGFloat(min(max(progress, 0), 1)))
        }
    }
    .frame(height: height)
}

private func percent(_ value: Double) -> String {
    "\(Int((value * 100).rounded()))%"
}

private extension View {
    func cardSurface(cornerRadius: CGFloat) -> some View {
        background(.white)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AtlasColors.line, lineWidth: 2)
            )
            .shadow(color: AtlasColors.line, radius: 0, y: 5)
    }
}
