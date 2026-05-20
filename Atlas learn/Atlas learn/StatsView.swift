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

            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(language.text(ru: "Сегодня", en: "Today"))
                            .font(.system(size: 34, weight: .black, design: .serif))
                        Text("\(profile.currentLevel.tag) · \(profile.score0To160)/160")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(.black.opacity(0.58))
                    }

                    Spacer()

                    Button {
                        AtlasHaptics.tap()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .black))
                            .foregroundStyle(.black)
                            .frame(width: 42, height: 42)
                            .background(Circle().fill(.white))
                            .overlay(Circle().stroke(.black, lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(profile.completedTodayCount)")
                            .font(.system(size: 46, weight: .black, design: .rounded))
                        Text("/ \(profile.dailyGoal)")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(.black.opacity(0.52))
                        Spacer()
                        Image(systemName: "flag.checkered")
                            .font(.system(size: 28, weight: .black))
                    }

                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule().fill(.black.opacity(0.08))
                            Capsule()
                                .fill(AtlasColors.green)
                                .frame(width: proxy.size.width * min(progress, 1))
                        }
                    }
                    .frame(height: 12)

                    Text(language.text(
                        ru: "Капсула сверху теперь показывает реальный прогресс дня: цель, CEFR-score, повторения и точность.",
                        en: "The top capsule now shows real daily progress: goal, CEFR score, reviews, and accuracy."
                    ))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.black.opacity(0.58))
                    .fixedSize(horizontal: false, vertical: true)
                }
                .padding(17)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(AtlasColors.line, lineWidth: 2.2)
                )
                .shadow(color: AtlasColors.line, radius: 0, y: 6)

                HStack(spacing: 12) {
                    dailyMetric(icon: "clock.arrow.circlepath", title: language.text(ru: "К повторению", en: "Due"), value: "\(profile.dueWordsCount)")
                    dailyMetric(icon: "target", title: language.text(ru: "Точность", en: "Accuracy"), value: percent(today.accuracy))
                }

                Button {
                    AtlasHaptics.tap()
                    dismiss()
                    continueAction()
                } label: {
                    Text(language.text(ru: "Продолжить тренировку", en: "Continue practice"))
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(AtlasColors.ink)
                        .clipShape(RoundedRectangle(cornerRadius: 21, style: .continuous))
                        .shadow(color: .black.opacity(0.35), radius: 0, y: 5)
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
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 21, weight: .black))
                .foregroundStyle(AtlasColors.green)
            Text(value)
                .font(.system(size: 27, weight: .black, design: .rounded))
            Text(title)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(.black.opacity(0.58))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 21, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 21, style: .continuous)
                .stroke(AtlasColors.line, lineWidth: 2)
        )
        .shadow(color: AtlasColors.line, radius: 0, y: 5)
    }
}

struct StatsView: View {
    let profile: AtlasProfile

    private var language: AppLanguage { profile.appLanguage }
    private var recentDays: [DailyProgress] {
        Array(profile.dailyProgress.values.sorted { $0.dateKey > $1.dateKey }.prefix(7).reversed())
    }
    private var weakWords: [WordEntry] {
        Array(profile.weakWordIDs.compactMap(WordBank.entry).prefix(6))
    }

    var body: some View {
        ZStack {
            AtlasColors.paper.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    Text(language.text(ru: "Статистика", en: "Stats"))
                        .font(.system(size: 36, weight: .black, design: .serif))
                        .foregroundStyle(.black)

                    levelScoreCard

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        statCard(icon: "flame.fill", title: language.text(ru: "Серия", en: "Streak"), value: "\(profile.streak)")
                        statCard(icon: "bolt.fill", title: "XP", value: "\(profile.xp)")
                        statCard(icon: "target", title: language.text(ru: "Точность", en: "Accuracy"), value: percent(profile.overallAccuracy))
                        statCard(icon: "exclamationmark.bubble", title: language.text(ru: "Слабые", en: "Weak"), value: "\(profile.weakWordIDs.count)")
                    }

                    sectionTitle(language.text(ru: "7 дней", en: "7 days"))
                    weekChart

                    sectionTitle(language.text(ru: "Уровни", en: "Levels"))
                    levelDistribution

                    sectionTitle(language.text(ru: "Режимы", en: "Modes"))
                    modeAccuracy

                    if !weakWords.isEmpty {
                        sectionTitle(language.text(ru: "Слабые слова", en: "Weak words"))
                        VStack(spacing: 10) {
                            ForEach(weakWords) { word in
                                weakWordRow(word)
                            }
                        }
                    }

                    sectionTitle(language.text(ru: "История", en: "History"))
                    VStack(spacing: 10) {
                        ForEach(profile.practiceHistory.prefix(8)) { record in
                            historyRow(record)
                        }
                    }
                }
                .padding(.horizontal, AtlasLayout.screenPadding)
                .padding(.top, 22)
                .padding(.bottom, 28)
            }
        }
    }

    private var levelScoreCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("\(profile.currentLevel.tag) \(profile.currentLevel.title(for: language))")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                    Text(profile.currentLevel.shortCanDoRU)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.black.opacity(0.6))
                }
                Spacer()
                Text("\(profile.score0To160)")
                    .font(.system(size: 40, weight: .black, design: .rounded))
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(.black.opacity(0.08))
                    Capsule()
                        .fill(AtlasColors.green)
                        .frame(width: proxy.size.width * CGFloat(Double(profile.score0To160) / 160.0))
                }
            }
            .frame(height: 12)
        }
        .foregroundStyle(.black)
        .padding(17)
        .background(AtlasColors.mint.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .stroke(AtlasColors.line, lineWidth: 2.3)
        )
        .shadow(color: AtlasColors.line, radius: 0, y: 6)
    }

    private var weekChart: some View {
        HStack(alignment: .bottom, spacing: 9) {
            ForEach(recentDays) { day in
                VStack(spacing: 7) {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(AtlasColors.green)
                        .frame(height: max(CGFloat(day.xp) / 2.4, 8))
                    Text(shortDay(day.dateKey))
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(.black.opacity(0.58))
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 132, alignment: .bottom)
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 23, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 23, style: .continuous)
                .stroke(AtlasColors.line, lineWidth: 2)
        )
        .shadow(color: AtlasColors.line, radius: 0, y: 5)
    }

    private var levelDistribution: some View {
        VStack(spacing: 10) {
            ForEach(LearningLevel.allCases) { level in
                let mastered = profile.wordProgress.filter { entry in
                    WordBank.entry(id: entry.key)?.level == level && entry.value.mastery >= 70
                }.count
                let total = WordBank.all.filter { $0.level == level }.count
                levelBar(level: level, mastered: mastered, total: total)
            }
        }
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 23, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 23, style: .continuous)
                .stroke(AtlasColors.line, lineWidth: 2)
        )
        .shadow(color: AtlasColors.line, radius: 0, y: 5)
    }

    private var modeAccuracy: some View {
        VStack(spacing: 10) {
            ForEach(PracticeMode.allCases) { mode in
                let records = profile.practiceHistory.filter { $0.mode == mode }
                let correct = records.filter(\.isCorrect).count
                let accuracy = records.isEmpty ? 0 : Double(correct) / Double(records.count)
                levelLikeRow(icon: mode.icon, title: mode.title(for: language), value: records.isEmpty ? "0" : percent(accuracy))
            }
        }
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 23, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 23, style: .continuous)
                .stroke(AtlasColors.line, lineWidth: 2)
        )
        .shadow(color: AtlasColors.line, radius: 0, y: 5)
    }

    private func statCard(icon: String, title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(AtlasColors.green)

            Text(value)
                .font(.system(size: 31, weight: .black, design: .rounded))

            Text(title)
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(.black.opacity(0.62))
        }
        .foregroundStyle(.black)
        .padding(15)
        .frame(maxWidth: .infinity, minHeight: 126, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(AtlasColors.line, lineWidth: 2)
        )
        .shadow(color: AtlasColors.line, radius: 0, y: 5)
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

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(.black.opacity(0.08))
                    Capsule()
                        .fill(level == profile.currentLevel ? AtlasColors.green : AtlasColors.mint)
                        .frame(width: proxy.size.width * CGFloat(Double(mastered) / Double(max(total, 1))))
                }
            }
            .frame(height: 8)
        }
    }

    private func levelLikeRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .black))
                .frame(width: 34, height: 34)
                .background(Circle().fill(AtlasColors.mint.opacity(0.5)))
            Text(title)
                .font(.system(size: 15, weight: .black, design: .rounded))
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(.black.opacity(0.62))
        }
        .foregroundStyle(.black)
    }

    private func weakWordRow(_ word: WordEntry) -> some View {
        levelLikeRow(
            icon: "exclamationmark.bubble",
            title: "\(word.english) · \(word.russian)",
            value: "\(profile.wordProgress[word.id]?.mastery ?? 0)%"
        )
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AtlasColors.line, lineWidth: 2)
        )
    }

    private func historyRow(_ record: PracticeRecord) -> some View {
        levelLikeRow(
            icon: record.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill",
            title: "\(record.wordEnglish) · \(record.mode.title(for: language))",
            value: record.isCorrect ? "+\(record.xp)" : "0"
        )
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AtlasColors.line, lineWidth: 2)
        )
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 23, weight: .black, design: .rounded))
            .foregroundStyle(.black)
            .padding(.top, 4)
    }

    private func shortDay(_ key: String) -> String {
        String(key.suffix(5))
    }
}

private func percent(_ value: Double) -> String {
    "\(Int((value * 100).rounded()))%"
}
