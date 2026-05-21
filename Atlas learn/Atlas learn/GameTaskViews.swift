//
//  GameTaskViews.swift
//  Atlas learn
//

import SwiftUI

struct GameTaskBadge: View {
    let task: GeneratedGameTask
    let language: AppLanguage

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: task.mode.icon)
                .font(.system(size: 11, weight: .black))
            Text(task.mode.title(for: language))
                .font(.system(size: 11, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .foregroundStyle(.black.opacity(0.7))
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Capsule().fill(task.isBoss ? AtlasColors.coral.opacity(0.34) : AtlasColors.mint.opacity(0.4)))
        .overlay(Capsule().stroke(.black.opacity(0.18), lineWidth: 1))
    }
}
