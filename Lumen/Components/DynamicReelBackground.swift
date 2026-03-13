import SwiftUI

struct DynamicReelBackground: View {
    let category: String
    let difficulty: DifficultyLevel
    let seed: String

    @State private var animate = false
    @State private var glowShift = false

    init(category: String, difficulty: DifficultyLevel, seed: String = "") {
        self.category = category
        self.difficulty = difficulty
        self.seed = seed.isEmpty ? "\(category)-\(difficulty.rawValue)" : seed
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(
                    colors: scenePalette.base,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Depth layer for a more "photo-like" look.
                ForEach(0..<4, id: \.self) { idx in
                    let direction: CGFloat = animate ? -1 : 1
                    RoundedRectangle(cornerRadius: CGFloat(20 + idx * 8))
                        .fill(
                            LinearGradient(
                                colors: [
                                    scenePalette.glowA.opacity(0.22 - Double(idx) * 0.03),
                                    scenePalette.glowB.opacity(0.18 - Double(idx) * 0.03)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(
                            width: geo.size.width * (1.1 + CGFloat(unit(idx + 4)) * 0.35),
                            height: geo.size.height * (0.45 + CGFloat(unit(idx + 10)) * 0.2)
                        )
                        .rotationEffect(.degrees(Double(idx) * 7 - 12))
                        .offset(
                            x: direction * geo.size.width * (0.12 + CGFloat(unit(idx + 14)) * 0.18),
                            y: geo.size.height * (-0.28 + CGFloat(idx) * 0.18)
                        )
                        .blur(radius: 42 + CGFloat(idx * 12))
                }

                // Subtle "trees/buildings" silhouettes.
                HStack(alignment: .bottom, spacing: 0) {
                    ForEach(0..<28, id: \.self) { idx in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.black.opacity(0.17 + unit(idx + 24) * 0.18))
                            .frame(
                                width: geo.size.width * (0.01 + CGFloat(unit(idx + 30)) * 0.02),
                                height: geo.size.height * (0.18 + CGFloat(unit(idx + 40)) * 0.45)
                            )
                            .blur(radius: CGFloat(0.8 + unit(idx + 50) * 1.8))
                            .offset(y: geo.size.height * (0.03 + CGFloat(unit(idx + 60)) * 0.08))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .opacity(0.66)

                RadialGradient(
                    colors: [
                        scenePalette.glowA.opacity(glowShift ? 0.32 : 0.16),
                        scenePalette.glowB.opacity(0.11),
                        .clear
                    ],
                    center: .center
                    .offsetBy(dx: animate ? -0.22 : 0.22, dy: -0.25),
                    startRadius: 20,
                    endRadius: geo.size.width * 0.95
                )
                .ignoresSafeArea()
                .blendMode(.screen)

                TimelineView(.animation(minimumInterval: 1 / 30, paused: false)) { timeline in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    ZStack {
                        ForEach(0..<22, id: \.self) { idx in
                            let phase = Double(idx) * 0.47
                            let x = sin(t * (0.16 + unit(idx + 70) * 0.14) + phase) * geo.size.width * (0.28 + unit(idx + 80) * 0.24)
                            let y = cos(t * (0.12 + unit(idx + 90) * 0.1) + phase * 1.2) * geo.size.height * (0.2 + unit(idx + 100) * 0.25)
                            Circle()
                                .fill(Color.white.opacity(0.03 + unit(idx + 110) * 0.06))
                                .frame(
                                    width: CGFloat(2.5 + unit(idx + 120) * 6.5),
                                    height: CGFloat(2.5 + unit(idx + 120) * 6.5)
                                )
                                .offset(x: x, y: y)
                                .blur(radius: CGFloat(0.8 + unit(idx + 130) * 2.4))
                        }
                    }
                }
                .allowsHitTesting(false)

                // Vignette and grain
                RadialGradient(
                    colors: [.clear, .black.opacity(0.36)],
                    center: .center,
                    startRadius: geo.size.width * 0.2,
                    endRadius: geo.size.width * 0.95
                )
                .ignoresSafeArea()

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.04), .clear, .black.opacity(0.14)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .ignoresSafeArea()
                    .overlay(
                        FilmGrainLayer(seed: seedHash)
                            .opacity(0.07)
                    )
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 12).repeatForever(autoreverses: true)) {
                    animate = true
                }
                withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                    glowShift = true
                }
            }
        }
    }

    private var scenePalette: (base: [Color], glowA: Color, glowB: Color) {
        let lower = category.lowercased()
        if lower.contains("history") || lower.contains("culture") {
            return (
                [Color(red: 0.18, green: 0.13, blue: 0.18), Color(red: 0.31, green: 0.26, blue: 0.30), Color(red: 0.58, green: 0.34, blue: 0.22)],
                Color(red: 0.98, green: 0.70, blue: 0.34),
                Color(red: 0.64, green: 0.45, blue: 0.90)
            )
        }
        if lower.contains("science") || lower.contains("technology") {
            return (
                [Color(red: 0.05, green: 0.11, blue: 0.20), Color(red: 0.06, green: 0.30, blue: 0.44), Color(red: 0.16, green: 0.48, blue: 0.68)],
                Color(red: 0.25, green: 0.86, blue: 0.98),
                Color(red: 0.40, green: 0.53, blue: 0.98)
            )
        }
        if lower.contains("travel") {
            return (
                [Color(red: 0.07, green: 0.16, blue: 0.18), Color(red: 0.09, green: 0.39, blue: 0.39), Color(red: 0.22, green: 0.58, blue: 0.58)],
                Color(red: 0.98, green: 0.76, blue: 0.42),
                Color(red: 0.38, green: 0.84, blue: 0.78)
            )
        }
        switch difficulty {
        case .beginner, .elementary:
            return (
                [Color(red: 0.04, green: 0.12, blue: 0.24), Color(red: 0.08, green: 0.33, blue: 0.48), Color(red: 0.20, green: 0.50, blue: 0.69)],
                Color(red: 0.16, green: 0.84, blue: 0.95),
                Color(red: 0.55, green: 0.50, blue: 0.99)
            )
        case .intermediate, .upperIntermediate:
            return (
                [Color(red: 0.04, green: 0.10, blue: 0.22), Color(red: 0.12, green: 0.22, blue: 0.42), Color(red: 0.28, green: 0.30, blue: 0.62)],
                Color(red: 0.24, green: 0.80, blue: 0.97),
                Color(red: 0.66, green: 0.45, blue: 0.98)
            )
        case .advanced:
            return (
                [Color(red: 0.03, green: 0.08, blue: 0.18), Color(red: 0.10, green: 0.18, blue: 0.34), Color(red: 0.22, green: 0.23, blue: 0.48)],
                Color(red: 0.21, green: 0.66, blue: 0.95),
                Color(red: 0.58, green: 0.40, blue: 0.92)
            )
        }
    }

    private var seedHash: UInt64 {
        var hash: UInt64 = 1469598103934665603
        for byte in seed.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1099511628211
        }
        return hash
    }

    private func unit(_ index: Int) -> Double {
        var x = seedHash ^ UInt64(truncatingIfNeeded: index &* 0x9E3779B9)
        x ^= x >> 12
        x ^= x << 25
        x ^= x >> 27
        let normalized = Double(x & 0xFFFF) / 65535.0
        return normalized
    }
}

private extension UnitPoint {
    func offsetBy(dx: CGFloat, dy: CGFloat) -> UnitPoint {
        UnitPoint(x: x + dx, y: y + dy)
    }
}

private struct FilmGrainLayer: View {
    let seed: UInt64

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 16, paused: false)) { timeline in
            let t = Int(timeline.date.timeIntervalSinceReferenceDate * 10)
            Canvas { context, size in
                let count = 220
                for i in 0..<count {
                    let x = random(index: i * 2 + t)
                    let y = random(index: i * 2 + t + 1)
                    let w = 0.8 + random(index: i + t + 200) * 1.4
                    let rect = CGRect(
                        x: x * size.width,
                        y: y * size.height,
                        width: w,
                        height: w
                    )
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(.white.opacity(0.2 + random(index: i + t + 300) * 0.4))
                    )
                }
            }
        }
    }

    private func random(index: Int) -> CGFloat {
        var x = seed ^ UInt64(truncatingIfNeeded: index &* 0x9E3779B9)
        x ^= x >> 12
        x ^= x << 25
        x ^= x >> 27
        return CGFloat(Double(x & 0xFFFF) / 65535.0)
    }
}
