//
//  LessonPathView.swift
//  Atlas learn
//

import SwiftUI

struct LessonPathView: View {
    let profile: AtlasProfile
    let start: (LessonMode) -> Void

    private var language: AppLanguage {
        profile.appLanguage
    }

    private var units: [LessonPathUnit] {
        LessonPathCatalog.units(for: profile)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(language.text(ru: "Продолжить путь", en: "Continue path"))
                        .font(.system(size: 15, weight: .black, design: .rounded))
                    Text(units.first?.title ?? "Unit 1")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.68))
                }

                Spacer()

                Label("\(profile.energy)/\(EnergyEngine.maxEnergy)", systemImage: "bolt.heart.fill")
                    .font(.system(size: 12, weight: .black, design: .rounded))
            }
            .foregroundStyle(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(units.first?.nodes ?? []) { node in
                        LessonPathNodeButton(node: node, language: language) {
                            start(node.mode)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(14)
        .background(AtlasColors.deepInk.opacity(0.94))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.16), lineWidth: 1.2)
        )
        .shadow(color: .black.opacity(0.24), radius: 14, y: 10)
    }
}

private struct LessonPathNodeButton: View {
    let node: LessonPathNode
    let language: AppLanguage
    let action: () -> Void

    var body: some View {
        Button {
            guard node.state != .locked else {
                AtlasHaptics.impact(.soft)
                return
            }
            AtlasHaptics.tap()
            action()
        } label: {
            VStack(spacing: 7) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: node.mode.icon)
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(foreground)
                        .frame(width: 52, height: 52)
                        .background(Circle().fill(fill))
                        .overlay(Circle().stroke(border, lineWidth: 2))

                    if node.state == .completed {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 15, weight: .black))
                            .foregroundStyle(AtlasColors.green)
                            .background(Circle().fill(.white))
                            .offset(x: 2, y: -2)
                    }
                }

                Text(node.title)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(.white.opacity(node.state == .locked ? 0.48 : 0.9))
                    .lineLimit(1)
                    .minimumScaleFactor(0.66)
                    .frame(width: 76)
            }
        }
        .buttonStyle(.plain)
        .disabled(node.state == .locked)
    }

    private var fill: Color {
        switch node.state {
        case .completed:
            .white
        case .current:
            AtlasColors.mint
        case .locked:
            .white.opacity(0.18)
        }
    }

    private var foreground: Color {
        node.state == .locked ? .white.opacity(0.38) : .black
    }

    private var border: Color {
        node.state == .locked ? .white.opacity(0.16) : .black
    }
}

struct LessonLaunchView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var profile: AtlasProfile
    let mode: LessonMode
    let selectedWord: WordEntry?
    let start: () -> Void

    private var language: AppLanguage {
        profile.appLanguage
    }

    private var preview: LessonLaunchPreview {
        LessonLaunchPreview(mode: mode, selectedWord: selectedWord, profile: profile)
    }

    var body: some View {
        ZStack {
            AtlasColors.paper.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(mode.title(for: language))
                            .font(.system(size: 31, weight: .black, design: .serif))
                        Text(mode.subtitle(for: language))
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(.black.opacity(0.62))
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
                            .background(Circle().fill(.white.opacity(0.82)))
                            .overlay(Circle().stroke(.black.opacity(0.86), lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                }

                if let selectedWord {
                    HStack(spacing: 10) {
                        Image(systemName: "target")
                            .font(.system(size: 20, weight: .black))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(selectedWord.english)
                                .font(.system(size: 19, weight: .black, design: .serif))
                            Text(selectedWord.russian)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(.black.opacity(0.62))
                        }
                        Spacer()
                    }
                    .padding(14)
                    .background(.white.opacity(0.82))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(.black.opacity(0.22), lineWidth: 1.4)
                    )
                }

                VStack(spacing: 10) {
                    launchMetric(icon: "sparkles", title: language.text(ru: "Новые слова", en: "New words"), value: "\(preview.newCount)")
                    launchMetric(icon: "arrow.clockwise", title: language.text(ru: "Повторение", en: "Review"), value: "\(preview.reviewCount)")
                    launchMetric(icon: "cross.case.fill", title: language.text(ru: "Слабые слова", en: "Weak words"), value: "\(preview.weakCount)")
                    launchMetric(icon: "clock", title: language.text(ru: "Время", en: "Time"), value: "~\(preview.minutes) мин")
                }

                VStack(alignment: .leading, spacing: 9) {
                    Text(language.text(ru: "Размер урока", en: "Lesson size"))
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(.black.opacity(0.54))

                    AtlasSegmentedPicker(
                        options: SessionLength.allCases,
                        selection: $profile.settings.sessionLength
                    ) { length in
                        switch length {
                        case .quick:
                            language.text(ru: "Быстрый", en: "Quick")
                        case .normal:
                            language.text(ru: "Обычный", en: "Normal")
                        case .deep:
                            language.text(ru: "Глубокий", en: "Deep")
                        }
                    }
                }

                Spacer()

                Button {
                    AtlasHaptics.tap()
                    start()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 20, weight: .black))
                        Text(language.text(ru: "Начать", en: "Start"))
                            .font(.system(size: 18, weight: .black, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(AtlasColors.ink)
                    .clipShape(RoundedRectangle(cornerRadius: 19, style: .continuous))
                    .shadow(color: .black.opacity(0.36), radius: 0, y: 5)
                }
                .buttonStyle(.plain)
            }
            .foregroundStyle(.black)
            .padding(.horizontal, AtlasLayout.screenPadding)
            .padding(.vertical, 22)
        }
    }

    private func launchMetric(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .black))
                .frame(width: 30)
            Text(title)
                .font(.system(size: 16, weight: .black, design: .rounded))
            Spacer()
            Text(value)
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(.black.opacity(0.62))
        }
        .padding(14)
        .background(.white.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.black.opacity(0.18), lineWidth: 1.4)
        )
    }
}

private struct LessonLaunchPreview {
    let newCount: Int
    let reviewCount: Int
    let weakCount: Int
    let minutes: Int

    init(mode: LessonMode, selectedWord: WordEntry?, profile: AtlasProfile) {
        if mode == .wordDrill {
            newCount = 0
            reviewCount = selectedWord == nil ? 0 : 1
            weakCount = selectedWord.map { profile.weakWordIDs.contains($0.id) ? 1 : 0 } ?? 0
        } else {
            let pack = WordSelectionEngine.dailyPack(for: profile)
            newCount = mode == .review || mode == .weakWords ? 0 : min(pack.newWords.count, 3)
            reviewCount = min(pack.reviewWords.count, 4)
            weakCount = min(pack.weakWords.count, 2)
        }

        switch profile.settings.sessionLength {
        case .quick:
            minutes = 3
        case .normal:
            minutes = 5
        case .deep:
            minutes = 8
        }
    }
}

