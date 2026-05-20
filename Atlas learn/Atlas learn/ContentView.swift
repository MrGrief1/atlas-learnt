//
//  ContentView.swift
//  Atlas learn
//
//  Created by Maks on 5/20/26.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @AppStorage("atlas.hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("atlas.profile") private var storedProfile = ""

    @State private var profile = AtlasProfile.default

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                HomeView(
                    profile: $profile,
                    resetOnboarding: resetOnboarding
                )
            } else {
                OnboardingView { completedProfile in
                    profile = completedProfile
                    save(completedProfile)
                    hasCompletedOnboarding = true
                }
            }
        }
        .onAppear {
            profile = loadProfile()
        }
        .dynamicTypeSize(.medium)
        .atlasSoftMotion(hasCompletedOnboarding)
        .atlasSoftMotion(profile)
        .atlasSoftMotion(dynamicTypeSize)
        .onChange(of: profile) { _, newValue in
            save(newValue)
        }
    }

    private func loadProfile() -> AtlasProfile {
        guard
            let data = storedProfile.data(using: .utf8),
            let decoded = try? JSONDecoder().decode(AtlasProfile.self, from: data)
        else {
            return .default
        }

        return decoded
    }

    private func save(_ profile: AtlasProfile) {
        guard
            let data = try? JSONEncoder().encode(profile),
            let json = String(data: data, encoding: .utf8)
        else {
            return
        }

        storedProfile = json
    }

    private func resetOnboarding() {
        profile = .default
        storedProfile = ""
        hasCompletedOnboarding = false
    }
}

#Preview {
    ContentView()
}
