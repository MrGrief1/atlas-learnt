//
//  LessonSummaryViewV2.swift
//  Atlas learn
//

import SwiftUI

struct LessonSummaryViewV2: View {
    let language: AppLanguage
    let run: LessonRun
    let profile: AtlasProfile
    let initialMastery: [String: Int]
    let continuePath: () -> Void
    let reviewMistakes: () -> Void
    let drillWeakWord: () -> Void

    private var improvedWords: [WordEntry] {
        let ids = run.targetWordIDs + run.reviewWordIDs + run.weakWordIDs + run.practicedWordIDs
        var seen = Set<String>()
        return ids.compactMap { id in
            guard !seen.contains(id) else { return nil }
            seen.insert(id)
            return WordBank.word(withID: id)
        }
    }

    private var mistakeCounts: [(LessonSkill, Int)] {
        Dictionary(grouping: run.results.filter { !$0.isCorrect }, by: \.skill)
            .map { ($0.key, $0.value.count) }
            .sorted { $0.1 > $1.1 }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(AtlasColors.mint)
                        .frame(width: 132, height: 132)
                        .overlay(Circle().stroke(.black, lineWidth: 3))
                        .shadow(color: AtlasColors.line, radius: 0, y: 8)

                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 62, weight: .black))
                        .foregroundStyle(.black)
                }

                VStack(spacing: 7) {
                    Text(language.text(ru: "Урок завершён", en: "Lesson complete"))
                        .font(.system(size: 31, weight: .black, design: .serif))
                        .foregroundStyle(.black)
                        .multilineTextAlignment(.center)

                    Text(language.text(
                        ru: "XP мотивирует, но рост mastery и возвращённые ошибки важнее очков.",
                        en: "XP motivates, but mastery growth and repaired mistakes matter more than points."
                    ))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.black.opacity(0.62))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                }

                HStack(spacing: 12) {
                    LessonSummaryMetric(icon: "bolt.fill", title: "XP", value: "+\(run.xpEarned)")
                    LessonSummaryMetric(icon: "flame.fill", title: language.text(ru: "Combo", en: "Combo"), value: "\(run.maxCombo)")
                    LessonSummaryMetric(icon: "bolt.heart.fill", title: "Energy", value: "\(run.energy)/\(EnergyEngine.maxEnergy)")
                }

                if !improvedWords.isEmpty {
                    summarySection(title: language.text(ru: "Слова", en: "Words")) {
                        VStack(spacing: 9) {
                            ForEach(improvedWords.prefix(6)) { word in
                                masteryRow(for: word)
                            }
                        }
                    }
                }

                summarySection(title: language.text(ru: "Ошибки", en: "Mistakes")) {
                    if mistakeCounts.isEmpty {
                        Text(language.text(ru: "Без ошибок. Чистый урок.", en: "No mistakes. Clean lesson."))
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(.black.opacity(0.64))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(mistakeCounts, id: \.0) { skill, count in
                                HStack {
                                    Text(skill.rawValue)
                                        .font(.system(size: 14, weight: .black, design: .rounded))
                                    Spacer()
                                    Text("\(count)")
                                        .font(.system(size: 14, weight: .black, design: .rounded))
                                }
                                .foregroundStyle(.black)
                            }
                        }
                    }
                }

                summarySection(title: language.text(ru: "Следующее повторение", en: "Next review")) {
                    VStack(spacing: 8) {
                        ForEach(improvedWords.prefix(4)) { word in
                            HStack {
                                Text(word.english)
                                    .font(.system(size: 14, weight: .black, design: .rounded))
                                Spacer()
                                Text(nextReviewText(for: word))
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundStyle(.black.opacity(0.62))
                            }
                        }
                    }
                }

                if !mistakeCounts.isEmpty, let weak = improvedWords.first(where: { (profile.wordProgress[$0.id]?.mastery ?? 100) < 60 }) {
                    Text(language.text(
                        ru: "Рекомендация: повтори \(weak.english) через Word Drill.",
                        en: "Recommendation: drill \(weak.english) once more."
                    ))
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(.black.opacity(0.66))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(AtlasColors.coral.opacity(0.18))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(.black.opacity(0.2), lineWidth: 1.3)
                    )
                }

                VStack(spacing: 10) {
                    Button(action: continuePath) {
                        summaryButtonLabel(title: language.text(ru: "Продолжить путь", en: "Continue path"), icon: "map.fill", fill: AtlasColors.ink, foreground: .white, showsBorder: false)
                    }
                    .buttonStyle(.plain)

                    HStack(spacing: 10) {
                        Button(action: reviewMistakes) {
                            summaryButtonLabel(title: language.text(ru: "Повторить ошибки", en: "Review mistakes"), icon: "arrow.clockwise", fill: .white, foreground: .black, showsBorder: true)
                        }
                        .buttonStyle(.plain)
                        .disabled(mistakeCounts.isEmpty)
                        .opacity(mistakeCounts.isEmpty ? 0.55 : 1)

                        Button(action: drillWeakWord) {
                            summaryButtonLabel(title: language.text(ru: "Слабое слово", en: "Weak word"), icon: "target", fill: .white, foreground: .black, showsBorder: true)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, AtlasLayout.screenPadding)
            .padding(.vertical, 28)
        }
        .foregroundStyle(.black)
    }

    private func summarySection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(.black.opacity(0.52))
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.white.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.black.opacity(0.18), lineWidth: 1.4)
        )
    }

    private func masteryRow(for word: WordEntry) -> some View {
        let before = initialMastery[word.id] ?? 0
        let after = profile.wordProgress[word.id]?.mastery ?? before

        return VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(word.english)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                Spacer()
                Text("\(before)% → \(after)%")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(.black.opacity(0.62))
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(.black.opacity(0.10))
                    Capsule()
                        .fill(AtlasColors.green)
                        .frame(width: proxy.size.width * CGFloat(min(max(after, 0), 100)) / 100)
                }
            }
            .frame(height: 8)
        }
    }

    private func nextReviewText(for word: WordEntry) -> String {
        guard let dueAt = profile.wordProgress[word.id]?.dueAt else {
            return language.text(ru: "скоро", en: "soon")
        }

        let hours = max(1, Int(dueAt.timeIntervalSince(Date()) / 3600))
        if hours < 3 {
            return language.text(ru: "через 2 часа", en: "in 2 hours")
        }
        if hours < 36 {
            return language.text(ru: "завтра", en: "tomorrow")
        }
        return language.text(ru: "через \(max(2, hours / 24)) дн.", en: "in \(max(2, hours / 24)) days")
    }

    private func summaryButtonLabel(title: String, icon: String, fill: Color, foreground: Color, showsBorder: Bool) -> some View {
        HStack(spacing: 9) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .black))
            Text(title)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .foregroundStyle(foreground)
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(fill)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.black.opacity(showsBorder ? 0.84 : 0), lineWidth: 2)
        )
    }
}

private struct LessonSummaryMetric: View {
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
