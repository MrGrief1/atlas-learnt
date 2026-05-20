//
//  ProfileView.swift
//  Atlas learn
//

import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var profile: AtlasProfile
    let resetOnboarding: () -> Void

    private var language: AppLanguage {
        profile.appLanguage
    }

    var body: some View {
        ZStack(alignment: .top) {
            AtlasColors.deepInk
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header

                    Text(language.text(ru: "Профиль", en: "Profile"))
                        .font(.system(size: 36, weight: .black, design: .serif))
                        .foregroundStyle(.black)

                    premiumCard

                    takeTestCard

                    languageCard

                    Text(language.text(ru: "Настроить приложение", en: "Customize the app"))
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(.black)
                        .padding(.top, 6)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                        ProfileTile(
                            title: language.text(ru: "Темы", en: "Topics"),
                            icon: "square.stack.3d.up",
                            color: AtlasColors.mint
                        )
                        ProfileTile(
                            title: language.text(ru: "Напоминания", en: "Reminders"),
                            icon: "bell.badge",
                            color: AtlasColors.mint
                        )
                        ProfileTile(
                            title: language.text(ru: "Голоса", en: "Voices"),
                            icon: "waveform",
                            color: AtlasColors.mint
                        )
                        ProfileTile(
                            title: language.text(ru: "Виджеты", en: "Widgets"),
                            icon: "apps.iphone",
                            color: AtlasColors.mint
                        )
                    }

                    Spacer(minLength: 18)
                }
                .padding(.horizontal, 18)
                .padding(.top, 22)
                .padding(.bottom, 34)
            }
            .background(AtlasColors.paper)
            .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
            .padding(.top, 64)
            .ignoresSafeArea(edges: .bottom)
        }
        .atlasSoftMotion(profile.appLanguage)
        .atlasMotion(profile.dailyGoal)
        .onChange(of: profile.appLanguage) { _, _ in
            AtlasHaptics.selection()
        }
    }

    private var header: some View {
        HStack {
            PaperIconButton(systemName: "xmark") {
                dismiss()
            }

            Spacer()

            PaperIconButton(systemName: "gearshape") {
                withAnimation(.atlasSpring) {
                    profile.dailyGoal = profile.dailyGoal == 5 ? 7 : 5
                }
            }
        }
    }

    private var premiumCard: some View {
        HStack(spacing: 15) {
            VStack(alignment: .leading, spacing: 10) {
                Text(language.text(ru: "Atlas Plus", en: "Atlas Plus"))
                    .font(.system(size: 24, weight: .black, design: .rounded))
                Text(language.text(
                    ru: "Все темы, больше слов дня, виджеты и режим без рекламы.",
                    en: "All topics, more daily words, widgets, and no ads."
                ))
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .lineSpacing(3)
            }
            .foregroundStyle(.black)

            Spacer()

            ZStack {
                TinyDotsShadow()
                    .frame(width: 70, height: 32)
                    .offset(y: 23)

                Circle()
                    .fill(.white.opacity(0.35))
                    .frame(width: 68, height: 68)
                    .overlay(Circle().stroke(.black, lineWidth: 2.5))

                Image(systemName: "target")
                    .font(.system(size: 36, weight: .black))
                    .foregroundStyle(.black)
                    .rotationEffect(.degrees(-12))
            }
        }
        .padding(17)
        .background(AtlasColors.mint)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.black, lineWidth: 2.5)
        )
        .shadow(color: .black, radius: 0, y: 6)
    }

    private var takeTestCard: some View {
        Button {
            AtlasHaptics.warning()
            resetOnboarding()
            dismiss()
        } label: {
            HStack(spacing: 14) {
                TopicMiniIllustration(icon: "graduationcap")
                    .scaleEffect(0.55)
                    .frame(width: 100, height: 66)

                VStack(alignment: .leading, spacing: 5) {
                    Text(language.text(ru: "Пройти тест", en: "Take a test"))
                        .font(.system(size: 21, weight: .black, design: .rounded))
                    Text(language.text(ru: "и уточнить свой уровень", en: "to see your current level"))
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                }
                .foregroundStyle(.black)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(.black.opacity(0.46))
            }
            .padding(14)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.black, lineWidth: 2.5)
            )
            .shadow(color: .black, radius: 0, y: 6)
        }
        .buttonStyle(.plain)
    }

    private var languageCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(language.text(ru: "Язык", en: "Language"))
                        .font(.system(size: 19, weight: .black, design: .rounded))
                    Text(language.text(ru: "Русский / English интерфейс", en: "Russian / English interface"))
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.black.opacity(0.56))
                }

                Spacer()

                Image(systemName: "globe")
                    .font(.system(size: 24, weight: .bold))
            }

            Picker("", selection: $profile.appLanguage) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.nativeTitle)
                        .tag(language)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(15)
        .foregroundStyle(.black)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.black, lineWidth: 2.3)
        )
        .shadow(color: .black, radius: 0, y: 5)
    }
}

struct ProfileTile: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            TopicMiniIllustration(icon: icon)
                .frame(maxWidth: .infinity)

            Spacer(minLength: 4)

            Text(title)
                .font(.system(size: 21, weight: .black, design: .rounded))
                .foregroundStyle(.black)
                .lineLimit(2)
                .minimumScaleFactor(0.74)
        }
        .padding(14)
        .frame(minHeight: 168, alignment: .topLeading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.black.opacity(0.72), lineWidth: 2.2)
        )
        .shadow(color: .black.opacity(0.72), radius: 0, y: 6)
    }
}
