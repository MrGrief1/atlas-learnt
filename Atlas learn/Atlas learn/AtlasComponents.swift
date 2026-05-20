//
//  AtlasComponents.swift
//  Atlas learn
//

import SwiftUI

enum AtlasColors {
    static let ink = Color(red: 0.12, green: 0.12, blue: 0.12)
    static let deepInk = Color(red: 0.08, green: 0.08, blue: 0.08)
    static let paper = Color(red: 0.93, green: 0.91, blue: 0.86)
    static let card = Color.white
    static let mint = Color(red: 0.63, green: 0.76, blue: 0.76)
    static let coral = Color(red: 0.93, green: 0.56, blue: 0.49)
    static let green = Color(red: 0.35, green: 0.72, blue: 0.39)
    static let line = Color.black.opacity(0.82)
    static let softLine = Color.black.opacity(0.28)
}

struct CircleIconButton: View {
    let systemName: String
    var foreground: Color = .white
    var fill: Color = Color.white.opacity(0.02)
    var border: Color = Color.white.opacity(0.14)
    var size: CGFloat = 58
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size * 0.43, weight: .medium))
                .foregroundStyle(foreground)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(fill)
                        .shadow(color: .black.opacity(0.26), radius: 14, y: 12)
                )
                .overlay(
                    Circle()
                        .stroke(border, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(systemName))
    }
}

struct PaperIconButton: View {
    let systemName: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(.black)
                .frame(width: 74, height: 74)
                .background(Circle().fill(Color.white.opacity(0.58)))
                .overlay(Circle().stroke(.white, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct OutlineButton: View {
    let title: String
    var subtitle: String?
    var isSelected = false
    var icon: String?
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .frame(width: 36, height: 36)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundStyle(.black)

                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.black.opacity(0.62))
                    }
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(isSelected ? AtlasColors.green : .black.opacity(0.28))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(isSelected ? AtlasColors.mint.opacity(0.7) : .white)
            .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 25, style: .continuous)
                    .stroke(AtlasColors.line, lineWidth: 2)
            )
            .shadow(color: AtlasColors.line, radius: 0, y: 6)
        }
        .buttonStyle(.plain)
    }
}

struct CapsuleMetric: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
            Text(title)
                .font(.system(size: 15, weight: .bold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 13)
        .padding(.vertical, 8)
        .background(Capsule().fill(Color.white.opacity(0.08)))
        .overlay(Capsule().stroke(Color.white.opacity(0.13), lineWidth: 1))
    }
}

struct TinyDotsShadow: View {
    var body: some View {
        Canvas { context, size in
            for x in stride(from: 0, through: size.width, by: 9) {
                for y in stride(from: 0, through: size.height, by: 9) {
                    let rect = CGRect(x: x, y: y, width: 2.3, height: 2.3)
                    context.fill(Path(ellipseIn: rect), with: .color(AtlasColors.coral.opacity(0.7)))
                }
            }
        }
    }
}

struct TopicMiniIllustration: View {
    let icon: String

    var body: some View {
        ZStack {
            TinyDotsShadow()
                .frame(width: 106, height: 42)
                .rotationEffect(.degrees(-4))
                .offset(x: 5, y: 34)

            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AtlasColors.mint.opacity(0.9))
                .frame(width: 112, height: 82)
                .rotationEffect(.degrees(-9))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(.black, lineWidth: 2.4)
                        .rotationEffect(.degrees(-9))
                )

            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.92))
                .frame(width: 96, height: 70)
                .rotationEffect(.degrees(7))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(.black, lineWidth: 2.2)
                        .rotationEffect(.degrees(7))
                )

            Image(systemName: icon)
                .font(.system(size: 38, weight: .black))
                .foregroundStyle(.black)
        }
        .frame(height: 126)
    }
}
