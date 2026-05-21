//
//  PremiumHomePieces.swift
//  Atlas learn
//

import SwiftUI

struct PremiumHomeBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.06, blue: 0.06),
                    Color(red: 0.10, green: 0.10, blue: 0.10),
                    Color(red: 0.04, green: 0.04, blue: 0.045)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(AtlasColors.mint.opacity(0.12))
                .frame(width: 280, height: 280)
                .blur(radius: 90)
                .offset(x: -120, y: -120)

            Circle()
                .fill(Color.white.opacity(0.055))
                .frame(width: 340, height: 340)
                .blur(radius: 110)
                .offset(x: 170, y: 170)
        }
    }
}

struct PremiumTopFade: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: Color.black.opacity(0.88), location: 0),
                .init(color: Color.black.opacity(0.66), location: 0.72),
                .init(color: Color.black.opacity(0.0), location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea(edges: .top)
    }
}

struct PremiumWordHeroView: View {
    let word: WordEntry
    let example: GeneratedWordExample
    let status: ExampleDisplayStatus
    let language: AppLanguage

    let isFavorite: Bool
    let isSaved: Bool

    let speak: () -> Void
    let showInfo: () -> Void
    let drill: () -> Void
    let toggleFavorite: () -> Void
    let toggleSaved: () -> Void

    private var cleanExample: GeneratedWordExample {
        if word.english.lowercased() == "worrying",
           example.russian.localizedCaseInsensitiveContains("качеством") {
            return GeneratedWordExample(
                english: "A worrying sign appeared.",
                russian: "Появился тревожный знак."
            )
        }

        return example
    }

    private var wordFontSize: CGFloat {
        if word.english.count > 14 { return 54 }
        if word.english.count > 10 { return 66 }
        return 78
    }

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 12) {
                Text(word.english.lowercased())
                    .font(.system(size: wordFontSize, weight: .black, design: .serif))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.48)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                Button(action: speak) {
                    HStack(spacing: 9) {
                        Text(word.ipa)
                            .font(.system(size: 17, weight: .black, design: .rounded))

                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 17, weight: .black))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 17)
                    .padding(.vertical, 9)
                    .background(Capsule().fill(Color.white.opacity(0.095)))
                    .overlay(Capsule().stroke(Color.white.opacity(0.16), lineWidth: 1.2))
                }
                .buttonStyle(.plain)
            }

            VStack(spacing: 10) {
                Text(word.russian)
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)

                Text(word.definition(for: language))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.58))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
                    .padding(.horizontal, 8)
            }

            exampleCard

            actionChips
        }
        .frame(maxWidth: .infinity)
    }

    private var exampleCard: some View {
        VStack(spacing: 8) {
            Text(cleanExample.english)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            Text(cleanExample.russian)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.62))
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            ExampleStatusPill(status: status, language: language)
                .scaleEffect(0.92)
                .padding(.top, 2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.075))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.11), lineWidth: 1.2)
        )
    }

    private var actionChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                PremiumActionChip(
                    icon: "info",
                    title: language.text(ru: "Инфо", en: "Info"),
                    action: showInfo
                )

                PremiumActionChip(
                    icon: "target",
                    title: language.text(ru: "Отработать", en: "Drill"),
                    isPrimary: true,
                    action: drill
                )

                PremiumActionChip(
                    icon: isFavorite ? "heart.fill" : "heart",
                    title: language.text(ru: "Любимое", en: "Favorite"),
                    foreground: isFavorite ? AtlasColors.coral : .white,
                    action: toggleFavorite
                )

                PremiumActionChip(
                    icon: isSaved ? "bookmark.fill" : "bookmark",
                    title: language.text(ru: "Сохранить", en: "Save"),
                    action: toggleSaved
                )
            }
            .padding(.horizontal, 2)
        }
    }
}

private struct PremiumActionChip: View {
    let icon: String
    let title: String
    var isPrimary = false
    var foreground: Color = .white
    let action: () -> Void

    var body: some View {
        Button {
            AtlasHaptics.tap()
            action()
        } label: {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .black))

                Text(title)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .lineLimit(1)
            }
            .foregroundStyle(isPrimary ? .black : foreground)
            .padding(.horizontal, 13)
            .frame(height: 38)
            .background(
                Capsule()
                    .fill(isPrimary ? AtlasColors.mint : Color.white.opacity(0.09))
            )
            .overlay(
                Capsule()
                    .stroke(isPrimary ? Color.black.opacity(0.72) : Color.white.opacity(0.13), lineWidth: 1.2)
            )
        }
        .buttonStyle(.plain)
    }
}

struct PremiumLessonDockView: View {
    let profile: AtlasProfile
    let openLesson: (LessonMode) -> Void
    let openWords: () -> Void
    let openMistakes: () -> Void
    let openStats: () -> Void

    private var language: AppLanguage {
        profile.appLanguage
    }

    private var unit: LessonPathUnit {
        LessonPathCatalog.units(for: profile).first ?? LessonPathUnit(
            id: "fallback",
            title: "Unit 1",
            subtitle: "",
            nodes: []
        )
    }

    private var currentNode: LessonPathNode? {
        unit.nodes.first { $0.state == .current }
            ?? unit.nodes.first { $0.state == .boss }
            ?? unit.nodes.first { $0.state != .locked }
            ?? unit.nodes.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            header

            pathRail

            startButton

            secondaryLinks
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color(red: 0.085, green: 0.085, blue: 0.09).opacity(0.96))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(Color.white.opacity(0.13), lineWidth: 1.25)
        )
        .shadow(color: .black.opacity(0.42), radius: 24, y: 16)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(language.text(ru: "Продолжить путь", en: "Continue path"))
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Text(unit.title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            .layoutPriority(1)

            Spacer()

            HStack(spacing: 7) {
                Image(systemName: "bolt.heart.fill")
                    .font(.system(size: 14, weight: .black))

                Text("\(profile.energy)/\(EnergyEngine.maxEnergy)")
                    .font(.system(size: 15, weight: .black, design: .rounded))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .frame(height: 34)
            .background(Capsule().fill(Color.white.opacity(0.095)))
            .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))
        }
    }

    private var pathRail: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 18) {
                ForEach(unit.nodes) { node in
                    PremiumLessonNodeView(node: node) {
                        guard node.state != .locked else {
                            AtlasHaptics.impact(.soft)
                            return
                        }

                        AtlasHaptics.tap()
                        openLesson(node.mode)
                    }
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 4)
        }
        .frame(height: 104)
    }

    private var startButton: some View {
        Button {
            AtlasHaptics.tap()
            openLesson(currentNode?.mode ?? .daily)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: currentNode?.mode.icon ?? "graduationcap.fill")
                    .font(.system(size: 19, weight: .black))

                Text(startButtonTitle)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(AtlasColors.mint)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.black.opacity(0.84), lineWidth: 1.8)
            )
            .shadow(color: Color.black.opacity(0.5), radius: 0, y: 5)
        }
        .buttonStyle(.plain)
    }

    private var startButtonTitle: String {
        guard let currentNode else {
            return language.text(ru: "Начать урок", en: "Start lesson")
        }

        switch currentNode.mode {
        case .daily:
            return language.text(ru: "Начать Practice", en: "Start Practice")
        case .newWords:
            return language.text(ru: "Учить новые слова", en: "Learn new words")
        case .review:
            return language.text(ru: "Повторить слова", en: "Review words")
        case .weakWords:
            return language.text(ru: "Разобрать ошибки", en: "Fix mistakes")
        case .listening:
            return language.text(ru: "Начать Listening", en: "Start Listening")
        case .story:
            return language.text(ru: "Открыть Story", en: "Open Story")
        case .boss:
            return "Boss Challenge"
        case .wordDrill:
            return language.text(ru: "Отработать слово", en: "Drill word")
        case .grammar:
            return language.text(ru: "Начать Grammar", en: "Start Grammar")
        }
    }

    private var secondaryLinks: some View {
        HStack(spacing: 10) {
            PremiumDockLink(icon: "square.grid.2x2", title: language.text(ru: "Слова", en: "Words"), action: openWords)
            PremiumDockLink(icon: "cross.case.fill", title: language.text(ru: "Ошибки", en: "Mistakes"), action: openMistakes)
            PremiumDockLink(icon: "chart.bar", title: language.text(ru: "Статы", en: "Stats"), action: openStats)
        }
    }
}

private struct PremiumLessonNodeView: View {
    let node: LessonPathNode
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    Circle()
                        .fill(fill)
                        .frame(width: 72, height: 72)
                        .overlay(
                            Circle()
                                .stroke(border, lineWidth: 2)
                        )
                        .shadow(color: glow, radius: node.state == .current ? 16 : 0, y: 0)

                    Image(systemName: node.state == .locked ? "lock.fill" : node.mode.icon)
                        .font(.system(size: 27, weight: .black))
                        .foregroundStyle(foreground)
                        .frame(width: 72, height: 72)

                    if node.state == .completed {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 23, weight: .black))
                            .foregroundStyle(AtlasColors.green)
                            .background(Circle().fill(.white))
                            .offset(x: 4, y: -4)
                    }
                }

                Text(node.title)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(labelColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.74)
                    .frame(width: 86)
            }
            .frame(width: 88)
            .opacity(node.state == .locked ? 0.48 : 1)
        }
        .buttonStyle(.plain)
    }

    private var fill: Color {
        switch node.state {
        case .completed:
            return .white
        case .current:
            return AtlasColors.mint
        case .locked:
            return Color.white.opacity(0.13)
        case .boss:
            return Color(red: 1.0, green: 0.82, blue: 0.36)
        }
    }

    private var foreground: Color {
        switch node.state {
        case .completed, .current, .boss:
            return .black
        case .locked:
            return .white.opacity(0.54)
        }
    }

    private var border: Color {
        switch node.state {
        case .completed, .current, .boss:
            return .black.opacity(0.9)
        case .locked:
            return .white.opacity(0.12)
        }
    }

    private var glow: Color {
        switch node.state {
        case .current:
            return AtlasColors.mint.opacity(0.42)
        case .boss:
            return Color(red: 1.0, green: 0.82, blue: 0.36).opacity(0.35)
        case .completed, .locked:
            return .clear
        }
    }

    private var labelColor: Color {
        node.state == .locked ? .white.opacity(0.45) : .white.opacity(0.92)
    }
}

private struct PremiumDockLink: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button {
            AtlasHaptics.tap()
            action()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .black))

                Text(title)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundStyle(.white.opacity(0.78))
            .frame(maxWidth: .infinity)
            .frame(height: 34)
            .background(Color.white.opacity(0.065))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct DarkLessonHeader: View {
    let language: AppLanguage
    let mode: LessonMode
    let progress: Double
    let energy: Int
    let xp: Int
    let combo: Int
    let questionPosition: Int
    let questionCount: Int
    let dismiss: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button {
                    AtlasHaptics.tap()
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 17, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(Circle().fill(Color.white.opacity(0.09)))
                        .overlay(Circle().stroke(Color.white.opacity(0.14), lineWidth: 1.2))
                }
                .buttonStyle(.plain)

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.15))

                        Capsule()
                            .fill(AtlasColors.mint)
                            .frame(width: proxy.size.width * min(max(progress, 0), 1))
                    }
                }
                .frame(height: 12)

                HStack(spacing: 6) {
                    Image(systemName: "bolt.heart.fill")
                        .font(.system(size: 13, weight: .black))

                    Text("\(energy)")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                }
                .foregroundStyle(.white)
                .frame(width: 72, height: 42)
                .background(Capsule().fill(Color.white.opacity(0.09)))
                .overlay(Capsule().stroke(Color.white.opacity(0.14), lineWidth: 1.2))
            }

            HStack(spacing: 8) {
                DarkHeaderPill(icon: mode.icon, title: mode.title(for: language))
                DarkHeaderPill(icon: "bolt.fill", title: "+\(xp) XP")
                DarkHeaderPill(icon: "flame.fill", title: "\(combo)")

                Spacer()

                Text("\(questionPosition)/\(max(questionCount, 1))")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(.white.opacity(0.58))
            }
        }
        .padding(.horizontal, AtlasLayout.screenPadding)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(PremiumTopFade())
    }
}

private struct DarkHeaderPill: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .black))

            Text(title)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .foregroundStyle(.white.opacity(0.78))
        .padding(.horizontal, 9)
        .frame(height: 28)
        .background(Capsule().fill(Color.white.opacity(0.075)))
        .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
}
