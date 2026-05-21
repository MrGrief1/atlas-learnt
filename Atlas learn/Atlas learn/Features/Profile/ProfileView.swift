//
//  ProfileView.swift
//  Atlas learn
//

import SwiftUI
import UserNotifications

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var profile: AtlasProfile
    let resetOnboarding: () -> Void

    @AppStorage("atlas.displayName") private var displayName = "Atlas learner"
    @AppStorage("atlas.speechEnabled") private var speechEnabled = true
    @AppStorage("atlas.hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("atlas.reminderEnabled") private var reminderEnabled = false
    @AppStorage("atlas.reminderHour") private var reminderHour = 19
    @AppStorage("atlas.reminderMinute") private var reminderMinute = 30
    @AppStorage("atlas.weekendReminders") private var weekendReminders = true
    @AppStorage("atlas.profileCompactMode") private var compactProfile = false

    @State private var activeSheet: ProfileSheet?
    @State private var selectedTab: ProfileTab = .overview
    @State private var reminderStatus: String?
    @State private var showsProgressReset = false
    @FocusState private var isNameFocused: Bool

    private var language: AppLanguage {
        profile.appLanguage
    }

    private var today: DailyProgress {
        profile.dailyProgress[AtlasProfile.todayKey()] ?? .empty(for: AtlasProfile.todayKey())
    }

    private var dailyProgress: Double {
        Double(profile.completedTodayCount) / Double(max(profile.dailyGoal, 1))
    }

    private var masteredWordsCount: Int {
        profile.wordProgress.values.filter { $0.mastery >= 70 }.count
    }

    private var sectionSpacing: CGFloat {
        compactProfile ? 12 : 18
    }

    private var trimmedDisplayName: String {
        displayName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var avatarInitial: String {
        String(trimmedDisplayName.first ?? "A").uppercased()
    }

    private var reminderTimeTitle: String {
        String(format: "%02d:%02d", reminderHour, reminderMinute)
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(version) (\(build))"
    }

    var body: some View {
        ZStack {
            AtlasColors.paper
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                titleBar

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: sectionSpacing) {
                        profileHero
                        ProfileTabPicker(selection: $selectedTab, language: language)
                        tabContent
                    }
                    .padding(.horizontal, AtlasLayout.scrollShadowPadding)
                    .padding(.top, AtlasLayout.scrollTopInset)
                    .padding(.bottom, 28)
                }
            }
            .padding(.horizontal, AtlasLayout.modalPadding - AtlasLayout.scrollShadowPadding)
            .padding(.top, 20)
        }
        .foregroundStyle(.black)
        .atlasSoftMotion(profile.appLanguage)
        .atlasMotion(profile.dailyGoal)
        .atlasMotion(profile.selectedTopics)
        .atlasMotion(profile.enabledPracticeSteps)
        .atlasMotion(reminderEnabled)
        .atlasMotion(selectedTab)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .voice:
                VoicePickerView(profile: $profile)
            }
        }
        .alert(language.text(ru: "Сбросить прогресс?", en: "Reset progress?"), isPresented: $showsProgressReset) {
            Button(language.text(ru: "Сбросить", en: "Reset"), role: .destructive) {
                resetLearningProgress()
            }
            Button(language.text(ru: "Отмена", en: "Cancel"), role: .cancel) {}
        } message: {
            Text(language.text(
                ru: "Слова, темы, язык и голос останутся. История, серия и повторения начнутся заново.",
                en: "Words, topics, language, and voice stay. History, streak, and reviews start over."
            ))
        }
        .onAppear {
            profile.prepareForToday()
            profile.settings.speechEnabled = speechEnabled
            profile.settings.reminderEnabled = reminderEnabled
            updateReminderStatus()
        }
        .onChange(of: reminderEnabled) { _, _ in
            profile.settings.reminderEnabled = reminderEnabled
            syncReminderSettings()
        }
        .onChange(of: speechEnabled) { _, newValue in
            profile.settings.speechEnabled = newValue
        }
        .onChange(of: reminderHour) { _, _ in
            syncReminderSettings()
        }
        .onChange(of: reminderMinute) { _, _ in
            syncReminderSettings()
        }
        .onChange(of: weekendReminders) { _, _ in
            syncReminderSettings()
        }
    }

    private var titleBar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(language.text(ru: "Профиль", en: "Profile"))
                    .font(.system(size: 34, weight: .black, design: .serif))

                Text(language.text(ru: "Настройки и прогресс", en: "Settings and progress"))
                    .font(.system(size: 13, weight: .black, design: .rounded))
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
    }

    private var profileHero: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 15) {
                ZStack {
                    TinyDotsShadow()
                        .frame(width: 76, height: 32)
                        .offset(y: 35)

                    Circle()
                        .fill(AtlasColors.mint)
                        .frame(width: 84, height: 84)
                        .overlay(Circle().stroke(.black, lineWidth: 2.5))
                        .shadow(color: .black.opacity(0.74), radius: 0, y: 6)

                    Text(avatarInitial)
                        .font(.system(size: 36, weight: .black, design: .rounded))
                }

                VStack(alignment: .leading, spacing: 9) {
                    TextField(
                        language.text(ru: "Имя", en: "Name"),
                        text: $displayName
                    )
                    .font(.system(size: 25, weight: .black, design: .rounded))
                    .foregroundStyle(.black)
                    .focused($isNameFocused)
                    .submitLabel(.done)
                    .textInputAutocapitalization(.words)
                    .onSubmit { isNameFocused = false }

                Text("\(profile.levelTag) · \(profile.currentLevel.title(for: language))")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(.black.opacity(0.62))
                        .lineLimit(1)
                        .minimumScaleFactor(0.74)

                    HStack(spacing: 7) {
                        CapsuleMetric(icon: "graduationcap", title: profile.levelTag)
                        CapsuleMetric(icon: "target", title: "\(profile.atlasScore)/600")
                    }
                }

                Spacer(minLength: 0)
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label(language.text(ru: "Сегодня", en: "Today"), systemImage: "flag.checkered")
                        .font(.system(size: 17, weight: .black, design: .rounded))

                    Spacer()

                    Text("\(profile.completedTodayCount)/\(profile.dailyGoal)")
                        .font(.system(size: 17, weight: .black, design: .rounded))
                }

                ProfileProgressBar(progress: dailyProgress)
            }
        }
        .padding(17)
        .background(AtlasColors.mint.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .stroke(AtlasColors.line, lineWidth: 2.4)
        )
        .shadow(color: AtlasColors.line, radius: 0, y: 6)
    }

    private var quickStatsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ProfileStatCard(
                icon: "flame.fill",
                title: language.text(ru: "Серия", en: "Streak"),
                value: "\(profile.streak)"
            )
            ProfileStatCard(
                icon: "bookmark.fill",
                title: language.text(ru: "Сохранено", en: "Saved"),
                value: "\(profile.savedWordIDs.count)"
            )
            ProfileStatCard(
                icon: "checkmark.seal.fill",
                title: language.text(ru: "Освоено", en: "Mastered"),
                value: "\(masteredWordsCount)"
            )
            ProfileStatCard(
                icon: "clock.arrow.circlepath",
                title: language.text(ru: "Повторить", en: "Due"),
                value: "\(profile.dueWordsCount)"
            )
            ProfileStatCard(
                icon: "target",
                title: language.text(ru: "Точность", en: "Accuracy"),
                value: profilePercent(profile.overallAccuracy == 0 ? today.accuracy : profile.overallAccuracy)
            )
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .overview:
            overviewTab
        case .learning:
            learningTab
        case .settings:
            settingsTab
        case .data:
            dataTab
        }
    }

    private var overviewTab: some View {
        VStack(alignment: .leading, spacing: sectionSpacing) {
            quickStatsGrid
            premiumCard
        }
    }

    private var learningTab: some View {
        VStack(alignment: .leading, spacing: sectionSpacing) {
            studySection
            topicsSection
            practiceModesSection
        }
    }

    private var settingsTab: some View {
        VStack(alignment: .leading, spacing: sectionSpacing) {
            soundAndReminderSection
            engineSettingsSection
            interfaceSection
            defaultsSection
        }
    }

    private var dataTab: some View {
        VStack(alignment: .leading, spacing: sectionSpacing) {
            dataSection
        }
    }

    private var premiumCard: some View {
        HStack(spacing: 15) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 17, weight: .black))
                    Text("Atlas Plus")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                }

                Text(language.text(
                    ru: "Все темы, расширенные повторы, больше слов дня и виджеты прогресса.",
                    en: "All topics, extended reviews, more daily words, and progress widgets."
                ))
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.black.opacity(0.72))
                .lineSpacing(3)
            }

            Spacer()

            ZStack {
                Circle()
                    .fill(.white.opacity(0.42))
                    .frame(width: 70, height: 70)
                    .overlay(Circle().stroke(.black, lineWidth: 2.5))

                Image(systemName: "sparkles")
                    .font(.system(size: 34, weight: .black))
            }
        }
        .padding(17)
        .background(AtlasColors.coral.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.black, lineWidth: 2.5)
        )
        .shadow(color: .black, radius: 0, y: 6)
    }

    private var studySection: some View {
        ProfileSection(
            title: language.text(ru: "Учебный план", en: "Learning plan"),
            subtitle: language.text(ru: "Только обычные ежедневные параметры", en: "Only everyday study preferences"),
            icon: "graduationcap"
        ) {
            VStack(alignment: .leading, spacing: 14) {
                ProfileSubheader(title: language.text(ru: "Слов в день", en: "Words per day"))

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach([5, 7, 10], id: \.self) { amount in
                        ProfileGoalButton(
                            amount: amount,
                            title: language.text(ru: "слов", en: "words"),
                            isSelected: profile.dailyGoal == amount
                        ) {
                            AtlasHaptics.selection()
                            withAnimation(.atlasSpring) {
                                profile.dailyGoal = amount
                                profile.settings.dailyGoal = amount
                            }
                        }
                    }
                }

                ProfileSubheader(title: language.text(ru: "Длина сессии", en: "Session length"))

                AtlasSegmentedPicker(
                    options: SessionLength.allCases,
                    selection: $profile.settings.sessionLength
                ) { length in
                    length.title(for: language)
                }

                ProfileInfoRow(
                    icon: "chart.bar.fill",
                    title: language.text(ru: "Уровень обновляется автоматически", en: "Level updates automatically"),
                    value: "\(profile.levelTag) · \(profile.atlasScore)/600"
                )
            }
        }
    }

    private var topicsSection: some View {
        ProfileSection(
            title: language.text(ru: "Темы", en: "Topics"),
            subtitle: language.text(
                ru: "\(profile.selectedTopics.count) из \(WordBank.topics.count) выбрано",
                en: "\(profile.selectedTopics.count) of \(WordBank.topics.count) selected"
            ),
            icon: "square.grid.2x2"
        ) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    ProfileMiniButton(title: language.text(ru: "Все", en: "All"), icon: "checkmark.circle") {
                        AtlasHaptics.selection()
                        withAnimation(.atlasSpring) {
                            profile.selectedTopics = WordBank.topics
                            profile.settings.selectedTopics = profile.selectedTopics
                        }
                    }

                    ProfileMiniButton(title: language.text(ru: "База", en: "Core"), icon: "star.circle") {
                        AtlasHaptics.selection()
                        withAnimation(.atlasSpring) {
                            profile.selectedTopics = ["Everyday", "Work", "Study"]
                            profile.settings.selectedTopics = profile.selectedTopics
                        }
                    }
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 11) {
                    ForEach(WordBank.topics, id: \.self) { topic in
                        ProfileTopicChip(
                            title: WordBank.topicTitle(topic, for: language),
                            icon: topicIcon(topic),
                            isSelected: profile.selectedTopics.contains(topic)
                        ) {
                            toggleTopic(topic)
                        }
                    }
                }
            }
        }
    }

    private var defaultsSection: some View {
        ProfileSection(
            title: language.text(ru: "По умолчанию", en: "Defaults"),
            subtitle: language.text(ru: "Вернуть спокойные базовые настройки", en: "Return to calm base settings"),
            icon: "arrow.triangle.2.circlepath"
        ) {
            ProfileActionRow(
                icon: "checkmark.seal.fill",
                title: language.text(ru: "Сделать настройки дефолтными", en: "Use default settings"),
                subtitle: language.text(
                    ru: "7 слов, базовые темы, все режимы, звук и отклик включены",
                    en: "7 words, core topics, all modes, speech and haptics on"
                ),
                value: nil
            ) {
                resetDefaultSettings()
            }
        }
    }

    private var practiceModesSection: some View {
        ProfileSection(
            title: language.text(ru: "Практика", en: "Practice"),
            subtitle: language.text(
                ru: "Включай режимы, которые попадут в урок",
                en: "Choose modes that can appear in lessons"
            ),
            icon: "checklist"
        ) {
            VStack(spacing: 10) {
                ForEach(PracticeStep.allCases) { step in
                    ProfilePracticeStepRow(
                        step: step,
                        language: language,
                        isOn: profile.enabledPracticeSteps.contains(step)
                    ) {
                        togglePracticeStep(step)
                    }
                }
            }
        }
    }

    private var soundAndReminderSection: some View {
        ProfileSection(
            title: language.text(ru: "Звук и напоминания", en: "Sound and reminders"),
            subtitle: language.text(ru: "Голос, отклик и ежедневный пинг", en: "Voice, feedback, and daily ping"),
            icon: "bell.badge"
        ) {
            VStack(spacing: 10) {
                ProfileActionRow(
                    icon: "waveform",
                    title: language.text(ru: "Голос озвучки", en: "Pronunciation voice"),
                    subtitle: profile.selectedSpeechVoice.subtitle(for: language),
                    value: profile.selectedSpeechVoice.title(for: language)
                ) {
                    activeSheet = .voice
                }

                ProfileSettingsToggle(
                    title: language.text(ru: "Озвучка", en: "Speech"),
                    subtitle: language.text(ru: "Кнопки Play и аудио в тренировке", en: "Play buttons and practice audio"),
                    icon: "speaker.wave.2.fill",
                    isOn: $speechEnabled
                )

                ProfileSettingsToggle(
                    title: language.text(ru: "Виброотклик", en: "Haptics"),
                    subtitle: language.text(ru: "Мягкие реакции на выборы", en: "Soft feedback for selections"),
                    icon: "hand.tap.fill",
                    isOn: $hapticsEnabled
                )

                ProfileSettingsToggle(
                    title: language.text(ru: "Напоминание", en: "Reminder"),
                    subtitle: language.text(ru: "Ежедневный пуш для слов дня", en: "Daily push for your words"),
                    icon: "alarm.fill",
                    isOn: $reminderEnabled
                )

                if reminderEnabled {
                    reminderControls
                }
            }
        }
    }

    private var engineSettingsSection: some View {
        ProfileSection(
            title: language.text(ru: "Движки обучения", en: "Learning engines"),
            subtitle: language.text(ru: "Разнообразие, повторы и AI-контент", en: "Variety, review, and AI content"),
            icon: "gearshape.2"
        ) {
            VStack(alignment: .leading, spacing: 13) {
                ProfileSubheader(title: language.text(ru: "Повторы", en: "Review"))
                AtlasSegmentedPicker(
                    options: ReviewAggressiveness.allCases,
                    selection: $profile.settings.reviewAggressiveness
                ) { option in
                    option.title(for: language)
                }

                ProfileSubheader(title: language.text(ru: "Игры", en: "Games"))
                AtlasSegmentedPicker(
                    options: GameVarietyLevel.allCases,
                    selection: $profile.settings.gameVariety
                ) { option in
                    option.title(for: language)
                }

                ProfileSettingsToggle(
                    title: language.text(ru: "Stretch-слова", en: "Stretch words"),
                    subtitle: language.text(ru: "Иногда добавлять уровень выше", en: "Sometimes add one level above"),
                    icon: "arrow.up.forward",
                    isOn: $profile.settings.stretchModeEnabled
                )

                ProfileSettingsToggle(
                    title: language.text(ru: "Аудирование", en: "Listening"),
                    subtitle: language.text(ru: "Audio Catch и диктанты в сессии", en: "Audio Catch and dictation in sessions"),
                    icon: "waveform",
                    isOn: $profile.settings.listeningEnabled
                )

                ProfileSettingsToggle(
                    title: language.text(ru: "Речь", en: "Speaking"),
                    subtitle: language.text(ru: "Speaking Echo максимум 1-2 раза", en: "Speaking Echo at most 1-2 times"),
                    icon: "mic.fill",
                    isOn: $profile.settings.speechEnabled
                )

                ProfileSettingsToggle(
                    title: language.text(ru: "AI-контент", en: "AI content"),
                    subtitle: language.text(ru: "Если недоступен, будет локальный fallback", en: "Uses local fallback when unavailable"),
                    icon: "sparkles",
                    isOn: $profile.settings.aiContentEnabled
                )

                ProfileSettingsToggle(
                    title: language.text(ru: "Строгая проверка", en: "Strict checking"),
                    subtitle: language.text(ru: "Требовать более точные ответы", en: "Require more exact answers"),
                    icon: "checkmark.shield.fill",
                    isOn: $profile.settings.strictAnswerChecking
                )
            }
        }
    }

    private var reminderControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            ProfileSubheader(title: language.text(ru: "Время", en: "Time"))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 9) {
                ForEach(ReminderPreset.all) { preset in
                    ReminderPresetButton(
                        title: preset.title,
                        isSelected: reminderHour == preset.hour && reminderMinute == preset.minute
                    ) {
                        AtlasHaptics.selection()
                        withAnimation(.atlasSpring) {
                            reminderHour = preset.hour
                            reminderMinute = preset.minute
                        }
                    }
                }
            }

            ProfileSettingsToggle(
                title: language.text(ru: "Включать выходные", en: "Include weekends"),
                subtitle: language.text(ru: "Если выключить, напоминания будут по будням", en: "Turn off for weekdays only"),
                icon: "calendar",
                isOn: $weekendReminders
            )

            if let reminderStatus {
                Text(reminderStatus)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(.black.opacity(0.58))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .background(AtlasColors.mint.opacity(0.25))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.black.opacity(0.26), lineWidth: 1.5)
        )
    }

    private var interfaceSection: some View {
        ProfileSection(
            title: language.text(ru: "Интерфейс", en: "Interface"),
            subtitle: language.text(ru: "Язык и плотность профиля", en: "Language and profile density"),
            icon: "slider.horizontal.3"
        ) {
            VStack(alignment: .leading, spacing: 13) {
                AtlasSegmentedPicker(
                    options: AppLanguage.allCases,
                    selection: $profile.appLanguage
                ) { language in
                    language.nativeTitle
                }

                ProfileSettingsToggle(
                    title: language.text(ru: "Компактный профиль", en: "Compact profile"),
                    subtitle: language.text(ru: "Меньше воздуха между блоками", en: "Less spacing between blocks"),
                    icon: "rectangle.compress.vertical",
                    isOn: $compactProfile
                )
            }
        }
    }

    private var dataSection: some View {
        ProfileSection(
            title: language.text(ru: "Данные", en: "Data"),
            subtitle: language.text(ru: "Тест, прогресс и версия", en: "Test, progress, and version"),
            icon: "externaldrive"
        ) {
            VStack(spacing: 10) {
                ProfileActionRow(
                    icon: "graduationcap.fill",
                    title: language.text(ru: "Пройти тест заново", en: "Retake placement test"),
                    subtitle: language.text(ru: "Собрать профиль с нуля", en: "Build the profile from scratch"),
                    value: nil
                ) {
                    AtlasHaptics.warning()
                    resetOnboarding()
                    dismiss()
                }

                ProfileActionRow(
                    icon: "arrow.counterclockwise",
                    title: language.text(ru: "Сбросить прогресс", en: "Reset progress"),
                    subtitle: language.text(ru: "Оставить настройки и очистить историю", en: "Keep settings and clear history"),
                    value: nil,
                    isDestructive: true
                ) {
                    AtlasHaptics.warning()
                    showsProgressReset = true
                }

                ProfileInfoRow(
                    icon: "info.circle",
                    title: "Atlas Learn",
                    value: appVersion
                )
            }
        }
    }

    private func toggleTopic(_ topic: String) {
        AtlasHaptics.selection()
        withAnimation(.atlasSpring) {
            if profile.selectedTopics.contains(topic) {
                guard profile.selectedTopics.count > 1 else {
                    AtlasHaptics.warning()
                    return
                }
                profile.selectedTopics.removeAll { $0 == topic }
            } else {
                profile.selectedTopics.append(topic)
            }
            profile.settings.selectedTopics = profile.selectedTopics
        }
    }

    private func togglePracticeStep(_ step: PracticeStep) {
        AtlasHaptics.selection()
        withAnimation(.atlasSpring) {
            if profile.enabledPracticeSteps.contains(step) {
                guard profile.enabledPracticeSteps.count > 1 else {
                    AtlasHaptics.warning()
                    return
                }
                profile.enabledPracticeSteps.removeAll { $0 == step }
            } else {
                profile.enabledPracticeSteps.append(step)
            }
        }
    }

    private func resetDefaultSettings() {
        AtlasHaptics.success()
        withAnimation(.atlasSpring) {
            profile.dailyGoal = 7
            profile.selectedTopics = ["Everyday", "Work", "Study"]
            profile.enabledPracticeSteps = PracticeStep.allCases
            profile.settings = .default
            speechEnabled = true
            hapticsEnabled = true
            reminderEnabled = false
            reminderHour = 19
            reminderMinute = 30
            weekendReminders = true
            compactProfile = false
        }
    }

    private func resetLearningProgress() {
        AtlasHaptics.success()
        withAnimation(.atlasSpring) {
            profile.completedTodayIDs = []
            profile.unknownWordIDs = []
            profile.wordProgress = [:]
            profile.dailyProgress = [:]
            profile.practiceHistory = []
            profile.streak = 0
            profile.xp = 0
            profile.applyAtlasScore(profile.currentLevel.atlasScoreStart)
            profile.prepareForToday()
        }
    }

    private func syncReminderSettings() {
        if reminderEnabled {
            requestAndScheduleReminder()
        } else {
            cancelReminder()
            reminderStatus = language.text(ru: "Напоминания выключены.", en: "Reminders are off.")
        }
    }

    private func requestAndScheduleReminder() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                if granted {
                    scheduleReminder()
                } else {
                    reminderEnabled = false
                    reminderStatus = language.text(
                        ru: "Разреши уведомления в настройках iOS, чтобы включить напоминания.",
                        en: "Allow notifications in iOS Settings to enable reminders."
                    )
                }
            }
        }
    }

    private func scheduleReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: Self.reminderIdentifiers)

        let weekdays: [Int?] = weekendReminders ? [nil] : [2, 3, 4, 5, 6]

        for weekday in weekdays {
            var components = DateComponents()
            components.calendar = Calendar(identifier: .gregorian)
            components.hour = reminderHour
            components.minute = reminderMinute
            components.weekday = weekday

            let content = UNMutableNotificationContent()
            content.title = language.text(ru: "Atlas Learn", en: "Atlas Learn")
            content.body = language.text(
                ru: "Пора забрать слова дня: \(profile.completedTodayCount)/\(profile.dailyGoal) уже сделано.",
                en: "Time for your daily words: \(profile.completedTodayCount)/\(profile.dailyGoal) done."
            )
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let id = weekday.map { "atlas.reminder.weekday.\($0)" } ?? "atlas.reminder.daily"
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            center.add(request)
        }

        updateReminderStatus()
    }

    private func cancelReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: Self.reminderIdentifiers)
    }

    private func updateReminderStatus() {
        reminderStatus = reminderEnabled
            ? language.text(
                ru: "Готово: \(reminderTimeTitle), \(weekendReminders ? "каждый день" : "по будням").",
                en: "Ready: \(reminderTimeTitle), \(weekendReminders ? "daily" : "weekdays")."
            )
            : language.text(ru: "Напоминания выключены.", en: "Reminders are off.")
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

    private static let reminderIdentifiers = ["atlas.reminder.daily"] + (2...6).map { "atlas.reminder.weekday.\($0)" }
}

private enum ProfileSheet: String, Identifiable {
    case voice

    var id: String { rawValue }
}

private enum ProfileTab: String, CaseIterable, Identifiable {
    case overview
    case learning
    case settings
    case data

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .overview: "person.crop.circle"
        case .learning: "graduationcap"
        case .settings: "slider.horizontal.3"
        case .data: "externaldrive"
        }
    }

    func title(for language: AppLanguage) -> String {
        switch self {
        case .overview:
            language.text(ru: "Обзор", en: "Overview")
        case .learning:
            language.text(ru: "Учеба", en: "Learn")
        case .settings:
            language.text(ru: "Настройки", en: "Settings")
        case .data:
            language.text(ru: "Данные", en: "Data")
        }
    }
}

private struct ReminderPreset: Identifiable {
    let hour: Int
    let minute: Int

    var id: String { "\(hour)-\(minute)" }
    var title: String { String(format: "%02d:%02d", hour, minute) }

    static let all = [
        ReminderPreset(hour: 8, minute: 0),
        ReminderPreset(hour: 12, minute: 0),
        ReminderPreset(hour: 19, minute: 30),
        ReminderPreset(hour: 21, minute: 0),
        ReminderPreset(hour: 22, minute: 30)
    ]
}

private struct ProfileTabPicker: View {
    @Binding var selection: ProfileTab
    let language: AppLanguage

    var body: some View {
        HStack(spacing: 7) {
            ForEach(ProfileTab.allCases) { tab in
                let isSelected = selection == tab

                Button {
                    guard selection != tab else { return }
                    AtlasHaptics.selection()
                    withAnimation(.atlasSpring) {
                        selection = tab
                    }
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 16, weight: .black))
                        Text(tab.title(for: language))
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.58)
                    }
                    .foregroundStyle(isSelected ? .black : .black.opacity(0.55))
                    .frame(maxWidth: .infinity)
                    .frame(height: 55)
                    .background(isSelected ? AtlasColors.mint : .white)
                    .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 17, style: .continuous)
                            .stroke(.black.opacity(isSelected ? 0.82 : 0.22), lineWidth: isSelected ? 2 : 1.4)
                    )
                    .shadow(color: .black.opacity(isSelected ? 0.56 : 0.14), radius: 0, y: isSelected ? 4 : 2)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.white.opacity(0.78))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.black.opacity(0.36), lineWidth: 1.8)
        )
    }
}

private struct ProfileSection<Content: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let content: Content

    init(title: String, subtitle: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .black))
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(AtlasColors.mint.opacity(0.65)))
                    .overlay(Circle().stroke(.black.opacity(0.72), lineWidth: 1.6))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 22, weight: .black, design: .rounded))

                    Text(subtitle)
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(.black.opacity(0.56))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            content
        }
        .padding(15)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(AtlasColors.line, lineWidth: 2.1)
        )
        .shadow(color: AtlasColors.line, radius: 0, y: 5)
    }
}

private struct ProfileSubheader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 13, weight: .black, design: .rounded))
            .foregroundStyle(.black.opacity(0.58))
            .textCase(.uppercase)
    }
}

private struct ProfileStatCard: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Image(systemName: icon)
                .font(.system(size: 19, weight: .black))

            Text(value)
                .font(.system(size: 28, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.76)

            Text(title)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(.black.opacity(0.58))
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.black.opacity(0.72), lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.68), radius: 0, y: 5)
    }
}

private struct ProfileGoalButton: View {
    let amount: Int
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Text("\(amount)")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                Text(title)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(.black.opacity(0.58))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? AtlasColors.mint : AtlasColors.paper.opacity(0.66))
            .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .stroke(.black.opacity(isSelected ? 0.88 : 0.26), lineWidth: isSelected ? 2 : 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct ProfileMiniButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .black))
                Text(title)
                    .font(.system(size: 13, weight: .black, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(AtlasColors.mint.opacity(0.58))
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(.black.opacity(0.58), lineWidth: 1.6)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct ProfileTopicChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .black))
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(isSelected ? .white.opacity(0.72) : AtlasColors.mint.opacity(0.36)))

                Text(title)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Spacer(minLength: 0)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 17, weight: .black))
                    .foregroundStyle(isSelected ? .black : .black.opacity(0.28))
            }
            .padding(11)
            .background(isSelected ? AtlasColors.mint.opacity(0.86) : AtlasColors.paper.opacity(0.58))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.black.opacity(isSelected ? 0.82 : 0.24), lineWidth: isSelected ? 1.9 : 1.4)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct ProfilePracticeStepRow: View {
    let step: PracticeStep
    let language: AppLanguage
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: step.icon)
                    .font(.system(size: 18, weight: .black))
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(isOn ? AtlasColors.mint.opacity(0.75) : .black.opacity(0.06)))

                VStack(alignment: .leading, spacing: 3) {
                    Text(step.title(for: language))
                        .font(.system(size: 16, weight: .black, design: .rounded))
                    Text(step.subtitle(for: language))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.black.opacity(0.56))
                        .lineLimit(2)
                }

                Spacer()

                ProfileSwitchVisual(isOn: isOn)
            }
            .padding(12)
            .background(isOn ? AtlasColors.mint.opacity(0.24) : AtlasColors.paper.opacity(0.45))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.black.opacity(isOn ? 0.42 : 0.18), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct ProfileActionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let value: String?
    var isDestructive = false
    let action: () -> Void

    var body: some View {
        Button {
            AtlasHaptics.tap()
            action()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .black))
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(isDestructive ? AtlasColors.coral.opacity(0.36) : AtlasColors.mint.opacity(0.58)))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 16, weight: .black, design: .rounded))
                    Text(subtitle)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.black.opacity(0.56))
                        .lineLimit(2)
                }

                Spacer()

                if let value {
                    Text(value)
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(.black.opacity(0.56))
                        .lineLimit(1)
                        .minimumScaleFactor(0.68)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(.black.opacity(0.42))
            }
            .padding(12)
            .background(isDestructive ? AtlasColors.coral.opacity(0.13) : AtlasColors.paper.opacity(0.45))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.black.opacity(isDestructive ? 0.32 : 0.18), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct ProfileSettingsToggle: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var isOn: Bool

    var body: some View {
        Button {
            AtlasHaptics.selection()
            withAnimation(.atlasSpring) {
                isOn.toggle()
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .black))
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(isOn ? AtlasColors.mint.opacity(0.72) : .black.opacity(0.06)))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 16, weight: .black, design: .rounded))
                    Text(subtitle)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.black.opacity(0.56))
                        .lineLimit(2)
                }

                Spacer()

                ProfileSwitchVisual(isOn: isOn)
            }
            .padding(12)
            .background(isOn ? AtlasColors.mint.opacity(0.24) : AtlasColors.paper.opacity(0.45))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.black.opacity(isOn ? 0.42 : 0.18), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct ProfileSwitchVisual: View {
    let isOn: Bool

    var body: some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            Capsule()
                .fill(isOn ? .black : .black.opacity(0.16))
                .frame(width: 48, height: 28)

            Circle()
                .fill(.white)
                .frame(width: 22, height: 22)
                .padding(.horizontal, 3)
                .shadow(color: .black.opacity(0.26), radius: 2, y: 1)
        }
        .frame(width: 48, height: 28)
    }
}

private struct ReminderPresetButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? AtlasColors.mint : .white.opacity(0.78))
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(.black.opacity(isSelected ? 0.8 : 0.24), lineWidth: isSelected ? 1.9 : 1.4)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct ProfileInfoRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .black))
                .frame(width: 38, height: 38)
                .background(Circle().fill(AtlasColors.mint.opacity(0.45)))

            Text(title)
                .font(.system(size: 16, weight: .black, design: .rounded))

            Spacer()

            Text(value)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(.black.opacity(0.58))
        }
        .padding(12)
        .background(AtlasColors.paper.opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.black.opacity(0.18), lineWidth: 1.5)
        )
    }
}

private struct ProfileProgressBar: View {
    let progress: Double
    var height: CGFloat = 11

    var body: some View {
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
}

struct VoicePickerView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var profile: AtlasProfile

    private var language: AppLanguage {
        profile.appLanguage
    }

    var body: some View {
        ZStack {
            AtlasColors.paper
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text(language.text(ru: "Голоса", en: "Voices"))
                        .font(.system(size: 34, weight: .black, design: .serif))
                        .foregroundStyle(.black)

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

                Text(language.text(
                    ru: "Выбери голос для озвучки английских слов.",
                    en: "Choose the voice for English word pronunciation."
                ))
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.black.opacity(0.62))

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 14) {
                        ForEach(SpeechVoiceOption.allCases) { voice in
                            VoiceOptionRow(
                                voice: voice,
                                isSelected: profile.selectedSpeechVoice == voice,
                                language: language
                            ) {
                                AtlasHaptics.selection()
                                withAnimation(.atlasSpring) {
                                    profile.voiceID = voice
                                }
                                AtlasSpeech.speak("reticence", voice: voice)
                            }
                        }
                    }
                    .padding(.horizontal, AtlasLayout.scrollShadowPadding)
                    .padding(.top, AtlasLayout.scrollTopInset)
                    .padding(.bottom, 24)
                }
            }
            .padding(.horizontal, AtlasLayout.modalPadding - AtlasLayout.scrollShadowPadding)
            .padding(.top, 20)
        }
        .atlasMotion(profile.selectedSpeechVoice)
    }
}

struct VoiceOptionRow: View {
    let voice: SpeechVoiceOption
    let isSelected: Bool
    let language: AppLanguage
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(AtlasColors.mint.opacity(0.86))
                        .frame(width: 58, height: 58)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(.black, lineWidth: 2)
                        )
                        .rotationEffect(.degrees(-4))

                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(.black)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(voice.title(for: language))
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(.black)

                    Text(voice.subtitle(for: language))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.black.opacity(0.58))
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24, weight: .black))
                    .foregroundStyle(isSelected ? .black : .black.opacity(0.34))
            }
            .padding(15)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 23, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 23, style: .continuous)
                    .stroke(isSelected ? .black : .black.opacity(0.72), lineWidth: isSelected ? 2.6 : 2)
            )
            .shadow(color: .black.opacity(isSelected ? 0.78 : 0.58), radius: 0, y: isSelected ? 6 : 4)
        }
        .buttonStyle(.plain)
    }
}

private func profilePercent(_ value: Double) -> String {
    "\(Int((value * 100).rounded()))%"
}
