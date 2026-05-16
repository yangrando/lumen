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
                // ── Base gradient ───────────────────────────────────────────
                LinearGradient(
                    colors: scenePalette.base,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // ── Atmospheric depth blobs ─────────────────────────────────
                ForEach(0..<5, id: \.self) { idx in
                    let direction: CGFloat = animate ? -1 : 1
                    Ellipse()
                        .fill(
                            LinearGradient(
                                colors: [
                                    scenePalette.glowA.opacity(0.20 - Double(idx) * 0.02),
                                    scenePalette.glowB.opacity(0.14 - Double(idx) * 0.02)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(
                            width: geo.size.width * CGFloat(1.1 + unit(idx + 4) * 0.5),
                            height: geo.size.height * CGFloat(0.42 + unit(idx + 10) * 0.24)
                        )
                        .rotationEffect(.degrees(Double(idx) * 9 - 18))
                        .offset(
                            x: direction * geo.size.width * CGFloat(0.10 + unit(idx + 14) * 0.22),
                            y: geo.size.height * CGFloat(-0.32 + Double(idx) * 0.16)
                        )
                        .blur(radius: 56 + CGFloat(idx * 14))
                }

                // ── Skyline (Canvas — 36 buildings with window lights) ──────
                Canvas { context, size in
                    let bottomY = size.height
                    for idx in 0..<36 {
                        let bWidth = size.width * CGFloat(0.018 + unit(idx + 30) * 0.034)
                        let bHeight = size.height * CGFloat(0.20 + unit(idx + 40) * 0.52)
                        let xPos = (CGFloat(idx) / 36.0
                            + CGFloat(unit(idx + 220) - 0.5) * 0.016) * size.width

                        // Building body
                        context.fill(
                            Path(CGRect(
                                x: xPos - bWidth / 2,
                                y: bottomY - bHeight,
                                width: bWidth,
                                height: bHeight
                            )),
                            with: .color(Color.black.opacity(0.28 + unit(idx + 50) * 0.28))
                        )

                        // Window lights (warm amber)
                        let windowRows = Int(3 + unit(idx + 60) * 6)
                        let windowCols = max(1, Int(bWidth / 7.0))
                        for row in 0..<windowRows {
                            for col in 0..<windowCols {
                                let litSeed = unit(idx * 19 + row * 7 + col * 3 + 300)
                                guard litSeed > 0.38 else { continue }

                                let colSpacing = bWidth * 0.60 / CGFloat(max(1, windowCols - 1))
                                let wx = xPos - bWidth * 0.30
                                    + CGFloat(col) * colSpacing
                                let wy = bottomY
                                    - bHeight * CGFloat(row + 1) / CGFloat(windowRows + 1)
                                let wSize: CGFloat = 1.6 + CGFloat(unit(idx * 3 + row + 400)) * 1.4
                                let warm = unit(idx * 11 + row * 5 + col + 500)

                                context.fill(
                                    Path(CGRect(
                                        x: wx - wSize / 2,
                                        y: wy - wSize / 2,
                                        width: wSize,
                                        height: wSize
                                    )),
                                    with: .color(Color(
                                        red: 1.0,
                                        green: 0.78 + warm * 0.16,
                                        blue: 0.26 + warm * 0.22
                                    ).opacity(0.30 + unit(idx + row + col + 600) * 0.44))
                                )
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .opacity(0.84)

                // ── City glow — warm haze rising from the skyline ───────────
                RadialGradient(
                    colors: [
                        scenePalette.cityGlow.opacity(glowShift ? 0.34 : 0.22),
                        scenePalette.cityGlow.opacity(0.10),
                        .clear
                    ],
                    center: UnitPoint(x: 0.5, y: 1.10),
                    startRadius: 8,
                    endRadius: geo.size.width * 0.84
                )
                .ignoresSafeArea()
                .blendMode(.screen)

                // ── Primary radial glow (animated) ──────────────────────────
                RadialGradient(
                    colors: [
                        scenePalette.glowA.opacity(glowShift ? 0.30 : 0.14),
                        scenePalette.glowB.opacity(0.10),
                        .clear
                    ],
                    center: UnitPoint(x: 0.5, y: 0.35)
                        .offsetBy(dx: animate ? -0.20 : 0.20, dy: -0.18),
                    startRadius: 20,
                    endRadius: geo.size.width * 0.92
                )
                .ignoresSafeArea()
                .blendMode(.screen)

                // ── Floating particles (reduced to 14 for perf) ─────────────
                TimelineView(.animation(minimumInterval: 1 / 24, paused: false)) { timeline in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    Canvas { context, size in
                        for idx in 0..<14 {
                            let phase = Double(idx) * 0.47
                            let px = sin(t * (0.14 + unit(idx + 70) * 0.13) + phase)
                                * Double(size.width) * (0.28 + unit(idx + 80) * 0.24)
                            let py = cos(t * (0.11 + unit(idx + 90) * 0.09) + phase * 1.2)
                                * Double(size.height) * (0.18 + unit(idx + 100) * 0.22)
                            let diameter = CGFloat(2.0 + unit(idx + 120) * 5.5)
                            let opacity = 0.04 + unit(idx + 110) * 0.07
                            context.fill(
                                Path(ellipseIn: CGRect(
                                    x: size.width / 2 + CGFloat(px) - diameter / 2,
                                    y: size.height / 2 + CGFloat(py) - diameter / 2,
                                    width: diameter,
                                    height: diameter
                                )),
                                with: .color(Color.white.opacity(opacity))
                            )
                        }
                    }
                }
                .allowsHitTesting(false)

                // ── Vignette ────────────────────────────────────────────────
                RadialGradient(
                    colors: [.clear, .black.opacity(0.48)],
                    center: .center,
                    startRadius: geo.size.width * 0.18,
                    endRadius: geo.size.width * 1.0
                )
                .ignoresSafeArea()

                // ── Film grain + light leak ──────────────────────────────────
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.03), .clear, .black.opacity(0.12)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .ignoresSafeArea()
                    .overlay(
                        FilmGrainLayer(seed: seedHash)
                            .opacity(0.065)
                    )
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 14).repeatForever(autoreverses: true)) {
                    animate = true
                }
                withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true)) {
                    glowShift = true
                }
            }
        }
    }

    // MARK: – Scene palettes (base, glowA, glowB, cityGlow)

    private var scenePalette: (base: [Color], glowA: Color, glowB: Color, cityGlow: Color) {
        let lower = category.lowercased()

        if lower.contains("business") || lower.contains("finance") || lower.contains("work") || lower.contains("negotiat") {
            return (
                [Color(red: 0.04, green: 0.08, blue: 0.18), Color(red: 0.08, green: 0.18, blue: 0.36), Color(red: 0.14, green: 0.28, blue: 0.52)],
                Color(red: 0.96, green: 0.80, blue: 0.36),
                Color(red: 0.42, green: 0.62, blue: 0.96),
                Color(red: 0.92, green: 0.60, blue: 0.18)
            )
        }
        if lower.contains("history") || lower.contains("culture") || lower.contains("entertainment") {
            return (
                [Color(red: 0.16, green: 0.10, blue: 0.22), Color(red: 0.28, green: 0.18, blue: 0.34), Color(red: 0.48, green: 0.26, blue: 0.20)],
                Color(red: 0.98, green: 0.68, blue: 0.30),
                Color(red: 0.72, green: 0.42, blue: 0.90),
                Color(red: 0.96, green: 0.56, blue: 0.16)
            )
        }
        if lower.contains("science") || lower.contains("technology") || lower.contains("tech") {
            return (
                [Color(red: 0.04, green: 0.09, blue: 0.20), Color(red: 0.05, green: 0.26, blue: 0.44), Color(red: 0.10, green: 0.40, blue: 0.64)],
                Color(red: 0.22, green: 0.88, blue: 0.98),
                Color(red: 0.38, green: 0.54, blue: 0.98),
                Color(red: 0.16, green: 0.70, blue: 0.92)
            )
        }
        if lower.contains("travel") || lower.contains("tourism") {
            return (
                [Color(red: 0.05, green: 0.14, blue: 0.18), Color(red: 0.08, green: 0.32, blue: 0.38), Color(red: 0.16, green: 0.50, blue: 0.52)],
                Color(red: 0.98, green: 0.80, blue: 0.38),
                Color(red: 0.36, green: 0.88, blue: 0.78),
                Color(red: 0.90, green: 0.72, blue: 0.24)
            )
        }
        if lower.contains("health") || lower.contains("sport") || lower.contains("fitness") {
            return (
                [Color(red: 0.04, green: 0.14, blue: 0.12), Color(red: 0.06, green: 0.28, blue: 0.22), Color(red: 0.12, green: 0.40, blue: 0.30)],
                Color(red: 0.26, green: 0.94, blue: 0.66),
                Color(red: 0.36, green: 0.78, blue: 0.94),
                Color(red: 0.20, green: 0.82, blue: 0.50)
            )
        }
        if lower.contains("art") || lower.contains("design") || lower.contains("fashion") || lower.contains("style") {
            return (
                [Color(red: 0.16, green: 0.08, blue: 0.26), Color(red: 0.28, green: 0.12, blue: 0.42), Color(red: 0.44, green: 0.18, blue: 0.54)],
                Color(red: 0.98, green: 0.50, blue: 0.88),
                Color(red: 0.72, green: 0.36, blue: 0.98),
                Color(red: 0.88, green: 0.40, blue: 0.72)
            )
        }
        if lower.contains("music") || lower.contains("concert") || lower.contains("song") {
            return (
                [Color(red: 0.10, green: 0.06, blue: 0.22), Color(red: 0.20, green: 0.10, blue: 0.38), Color(red: 0.34, green: 0.14, blue: 0.52)],
                Color(red: 0.88, green: 0.44, blue: 0.98),
                Color(red: 0.52, green: 0.36, blue: 0.98),
                Color(red: 0.78, green: 0.32, blue: 0.92)
            )
        }
        if lower.contains("gaming") || lower.contains("game") || lower.contains("esport") {
            return (
                [Color(red: 0.06, green: 0.07, blue: 0.22), Color(red: 0.10, green: 0.14, blue: 0.40), Color(red: 0.16, green: 0.20, blue: 0.58)],
                Color(red: 0.56, green: 0.34, blue: 0.98),
                Color(red: 0.26, green: 0.62, blue: 0.98),
                Color(red: 0.44, green: 0.26, blue: 0.94)
            )
        }
        if lower.contains("food") || lower.contains("cook") || lower.contains("culin") || lower.contains("recipe") {
            return (
                [Color(red: 0.18, green: 0.08, blue: 0.05), Color(red: 0.30, green: 0.14, blue: 0.07), Color(red: 0.44, green: 0.22, blue: 0.08)],
                Color(red: 0.98, green: 0.60, blue: 0.16),
                Color(red: 0.96, green: 0.34, blue: 0.22),
                Color(red: 0.98, green: 0.52, blue: 0.12)
            )
        }

        // Default — by CEFR difficulty
        switch difficulty {
        case .a1, .a2:
            return (
                [Color(red: 0.04, green: 0.12, blue: 0.24), Color(red: 0.08, green: 0.33, blue: 0.48), Color(red: 0.20, green: 0.50, blue: 0.68)],
                Color(red: 0.16, green: 0.84, blue: 0.95),
                Color(red: 0.55, green: 0.50, blue: 0.99),
                Color(red: 0.14, green: 0.72, blue: 0.92)
            )
        case .b1, .b2:
            return (
                [Color(red: 0.04, green: 0.10, blue: 0.22), Color(red: 0.12, green: 0.22, blue: 0.42), Color(red: 0.28, green: 0.30, blue: 0.62)],
                Color(red: 0.24, green: 0.80, blue: 0.97),
                Color(red: 0.66, green: 0.45, blue: 0.98),
                Color(red: 0.20, green: 0.68, blue: 0.92)
            )
        case .c1, .c2:
            return (
                [Color(red: 0.03, green: 0.08, blue: 0.18), Color(red: 0.10, green: 0.18, blue: 0.34), Color(red: 0.22, green: 0.23, blue: 0.48)],
                Color(red: 0.21, green: 0.66, blue: 0.95),
                Color(red: 0.58, green: 0.40, blue: 0.92),
                Color(red: 0.18, green: 0.54, blue: 0.88)
            )
        }
    }

    // MARK: – Deterministic pseudo-random helpers

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
        return Double(x & 0xFFFF) / 65535.0
    }
}

// MARK: – UnitPoint helper

private extension UnitPoint {
    func offsetBy(dx: CGFloat, dy: CGFloat) -> UnitPoint {
        UnitPoint(x: x + dx, y: y + dy)
    }
}

// MARK: – Film grain

private struct FilmGrainLayer: View {
    let seed: UInt64

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 14, paused: false)) { timeline in
            let t = Int(timeline.date.timeIntervalSinceReferenceDate * 10)
            Canvas { context, size in
                for i in 0..<180 {
                    let x = random(index: i * 2 + t)
                    let y = random(index: i * 2 + t + 1)
                    let w = 0.7 + random(index: i + t + 200) * 1.3
                    context.fill(
                        Path(ellipseIn: CGRect(
                            x: x * size.width,
                            y: y * size.height,
                            width: w,
                            height: w
                        )),
                        with: .color(.white.opacity(0.18 + random(index: i + t + 300) * 0.40))
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
