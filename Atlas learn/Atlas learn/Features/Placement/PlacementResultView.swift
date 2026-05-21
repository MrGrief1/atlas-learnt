//
//  PlacementResultView.swift
//  Atlas learn
//

import SwiftUI

struct PlacementResultView: View {
    let result: PlacementResult
    let language: AppLanguage
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text(language.text(ru: "Готово. Я собрал твой старт.", en: "Done. Your start is ready."))
                    .font(.system(size: 30, weight: .black, design: .serif))
                Text(language.text(
                    ru: "Теперь путь строится от CEFR-уровня и слов, которые нужно подтянуть.",
                    en: "Your path now uses your CEFR level and the words that need more practice."
                ))
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.black.opacity(0.62))
                .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(LearningLevel.sublevel(forAtlasScore: result.atlasScore).tag)
                            .font(.system(size: 34, weight: .black, design: .rounded))
                        Text(result.cefrLevel.title(for: language))
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(.black.opacity(0.58))
                    }
                    Spacer()
                    Text("\(result.atlasScore)/600")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                }

                progressBar(Double(result.atlasScore) / 600.0)

                HStack(spacing: 10) {
                    resultMetric(icon: "target", title: language.text(ru: "Уверенность", en: "Confidence"), value: "\(Int((result.confidence * 100).rounded()))%")
                    resultMetric(icon: "flag.checkered", title: language.text(ru: "Цель", en: "Goal"), value: "\(result.recommendedDailyGoal)")
                }
            }
            .padding(16)
            .background(AtlasColors.mint.opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 25, style: .continuous)
                    .stroke(AtlasColors.line, lineWidth: 2.3)
            )
            .shadow(color: AtlasColors.line, radius: 0, y: 6)

            skillPanel(
                title: language.text(ru: "Сильные навыки", en: "Strong skills"),
                skills: result.strongSkills,
                icon: "checkmark.seal.fill"
            )

            skillPanel(
                title: language.text(ru: "Слабые навыки", en: "Weak skills"),
                skills: result.weakSkills,
                icon: "exclamationmark.bubble.fill"
            )

            VStack(alignment: .leading, spacing: 9) {
                Label(language.text(ru: "Рекомендуемый путь", en: "Recommended path"), systemImage: "map")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                Text("\(result.cefrLevel.tag) Core + A2/B1 review + \(result.cefrLevel.next.tag) stretch")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.black.opacity(0.64))
            }
            .padding(14)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(.black.opacity(0.2), lineWidth: 1.4)
            )

            Button(action: action) {
                Text(language.text(ru: "Открыть слова дня", en: "Open daily words"))
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
        }
        .foregroundStyle(.black)
    }

    private func skillPanel(title: String, skills: [PlacementSkill], icon: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.system(size: 16, weight: .black, design: .rounded))
            if skills.isEmpty {
                Text(language.text(ru: "Появится после нескольких заданий.", en: "Appears after a few tasks."))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.black.opacity(0.58))
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(skills) { skill in
                        Label(skill.title(for: language), systemImage: skill.icon)
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AtlasColors.paper.opacity(0.6))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
            }
        }
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.black.opacity(0.2), lineWidth: 1.4)
        )
    }

    private func resultMetric(icon: String, title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .black))
            Text(value)
                .font(.system(size: 18, weight: .black, design: .rounded))
            Text(title)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(.black.opacity(0.58))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.white.opacity(0.66))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func progressBar(_ progress: Double) -> some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(.black.opacity(0.10))
                Capsule()
                    .fill(.black)
                    .frame(width: proxy.size.width * CGFloat(min(max(progress, 0), 1)))
            }
        }
        .frame(height: 11)
    }
}
