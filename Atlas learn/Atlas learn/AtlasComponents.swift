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

enum AtlasLayout {
    static let screenPadding: CGFloat = 26
    static let modalPadding: CGFloat = 20
    static let scrollShadowPadding: CGFloat = 6
}

struct CircleIconButton: View {
    let systemName: String
    var foreground: Color = .white
    var fill: Color = Color.white.opacity(0.02)
    var border: Color = Color.white.opacity(0.14)
    var size: CGFloat = 52
    var action: () -> Void

    var body: some View {
        Button {
            AtlasHaptics.tap()
            action()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: size * 0.43, weight: .medium))
                .foregroundStyle(foreground)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(fill)
                        .shadow(color: .black.opacity(0.24), radius: 12, y: 10)
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
        Button {
            AtlasHaptics.tap()
            action()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(.black)
                .frame(width: 60, height: 60)
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
        Button {
            AtlasHaptics.selection()
            action()
        } label: {
            HStack(spacing: 12) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 19, weight: .semibold))
                        .frame(width: 30, height: 30)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .heavy))
                        .foregroundStyle(.black)

                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.black.opacity(0.62))
                    }
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(isSelected ? AtlasColors.green : .black.opacity(0.28))
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 13)
            .background(isSelected ? AtlasColors.mint.opacity(0.7) : .white)
            .clipShape(RoundedRectangle(cornerRadius: 21, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 21, style: .continuous)
                    .stroke(AtlasColors.line, lineWidth: 2)
            )
            .shadow(color: AtlasColors.line, radius: 0, y: 5)
        }
        .buttonStyle(.plain)
        .atlasMotion(isSelected)
    }
}

struct AtlasSegmentedPicker<Option: Hashable & Identifiable>: View {
    let options: [Option]
    @Binding var selection: Option
    let title: (Option) -> String

    @Namespace private var selectionNamespace

    var body: some View {
        HStack(spacing: 5) {
            ForEach(options) { option in
                let isSelected = option == selection

                Button {
                    guard selection != option else { return }
                    AtlasHaptics.selection()
                    withAnimation(.atlasSpring) {
                        selection = option
                    }
                } label: {
                    Text(title(option))
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(isSelected ? .black : .black.opacity(0.62))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .background {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 17, style: .continuous)
                                    .fill(.white)
                                    .matchedGeometryEffect(id: "atlas-segment", in: selectionNamespace)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 17, style: .continuous)
                                            .stroke(.black.opacity(0.84), lineWidth: 2)
                                    )
                                    .shadow(color: .black.opacity(0.38), radius: 0, y: 3)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(5)
        .background(
            RoundedRectangle(cornerRadius: 21, style: .continuous)
                .fill(AtlasColors.mint.opacity(0.34))
                .shadow(color: .black.opacity(0.34), radius: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 21, style: .continuous)
                .stroke(.black.opacity(0.76), lineWidth: 2.2)
        )
        .atlasMotion(selection)
    }
}

struct CapsuleMetric: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
            Text(title)
                .font(.system(size: 13, weight: .bold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 11)
        .padding(.vertical, 7)
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
                .frame(width: 88, height: 34)
                .rotationEffect(.degrees(-4))
                .offset(x: 4, y: 28)

            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AtlasColors.mint.opacity(0.9))
                .frame(width: 94, height: 68)
                .rotationEffect(.degrees(-9))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(.black, lineWidth: 2.4)
                        .rotationEffect(.degrees(-9))
                )

            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.92))
                .frame(width: 80, height: 58)
                .rotationEffect(.degrees(7))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(.black, lineWidth: 2.2)
                        .rotationEffect(.degrees(7))
                )

            Image(systemName: icon)
                .font(.system(size: 31, weight: .black))
                .foregroundStyle(.black)
        }
        .frame(height: 104)
    }
}
