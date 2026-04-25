import SwiftUI

// MARK: - LumenMark
// Geometric symbol: luminous particle in flow with echo arcs.
// Mirrors the SVG spec from the design system (64×64 grid).

struct LumenMark: View {
    var size: CGFloat = 64
    var color: Color = LumenColors.accent
    var glowEnabled: Bool = false

    var body: some View {
        Canvas { ctx, canvasSize in
            let s = canvasSize.width
            let scale = s / 64

            func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                CGPoint(x: x * scale, y: y * scale)
            }

            // Outer arc (opacity 0.35): M12 32 a20 20 0 0 1 40 0
            let outerArc = Path { p in
                p.move(to: pt(12, 32))
                p.addArc(center: pt(32, 32), radius: 20 * scale,
                         startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
            }
            ctx.stroke(outerArc, with: .color(color.opacity(0.35)),
                       style: StrokeStyle(lineWidth: 2.2 * scale, lineCap: .round))

            // Middle arc (opacity 0.6): M18 32 a14 14 0 0 1 28 0
            let midArc = Path { p in
                p.move(to: pt(18, 32))
                p.addArc(center: pt(32, 32), radius: 14 * scale,
                         startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
            }
            ctx.stroke(midArc, with: .color(color.opacity(0.6)),
                       style: StrokeStyle(lineWidth: 2.2 * scale, lineCap: .round))

            // Inner arc (full opacity): M24 32 a8 8 0 0 1 16 0
            let innerArc = Path { p in
                p.move(to: pt(24, 32))
                p.addArc(center: pt(32, 32), radius: 8 * scale,
                         startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
            }
            ctx.stroke(innerArc, with: .color(color),
                       style: StrokeStyle(lineWidth: 2.2 * scale, lineCap: .round))

            // Particle circle at center
            let particleRect = CGRect(
                x: (32 - 3.2) * scale,
                y: (32 - 3.2) * scale,
                width: 6.4 * scale,
                height: 6.4 * scale
            )
            ctx.fill(Path(ellipseIn: particleRect), with: .color(color))

            // Horizon lines (opacity 0.45): M8 32 h10  M46 32 h10
            let horizons = Path { p in
                p.move(to: pt(8, 32)); p.addLine(to: pt(18, 32))
                p.move(to: pt(46, 32)); p.addLine(to: pt(56, 32))
            }
            ctx.stroke(horizons, with: .color(color.opacity(0.45)),
                       style: StrokeStyle(lineWidth: 1.5 * scale, lineCap: .round))
        }
        .frame(width: size, height: size)
        .if(glowEnabled) { v in
            v.shadow(color: color.opacity(0.5), radius: 6)
              .shadow(color: color.opacity(0.25), radius: 12)
        }
    }
}

// MARK: - LumenWordmark
struct LumenWordmark: View {
    var size: CGFloat = 40
    var color: Color = LumenColors.ink100
    var accent: Color = LumenColors.accent

    var body: some View {
        HStack(spacing: 0) {
            Text("lumen")
                .font(LumenFont.grotesk(size, weight: .light))
                .foregroundColor(color)
                .kerning(size * -0.04)
            Text(".")
                .font(LumenFont.grotesk(size, weight: .regular))
                .foregroundColor(accent)
                .kerning(size * -0.04)
                .offset(x: -1)
        }
        .lineLimit(1)
    }
}

// MARK: - LumenLockup (symbol + wordmark)
struct LumenLockup: View {
    var markSize: CGFloat = 44
    var fontSize: CGFloat = 36
    var color: Color = LumenColors.ink100
    var accent: Color = LumenColors.accent
    var gap: CGFloat = 12
    var glowEnabled: Bool = false

    var body: some View {
        HStack(spacing: gap) {
            LumenMark(size: markSize, color: accent, glowEnabled: glowEnabled)
            LumenWordmark(size: fontSize, color: color, accent: accent)
        }
    }
}

// MARK: - View helper for conditional modifiers
private extension View {
    @ViewBuilder
    func `if`<T: View>(_ condition: Bool, transform: (Self) -> T) -> some View {
        if condition { transform(self) } else { self }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 32) {
        LumenLockup(markSize: 64, fontSize: 52, glowEnabled: true)
        LumenMark(size: 120, color: LumenColors.accent, glowEnabled: true)
        HStack(spacing: 24) {
            ForEach([16, 24, 32, 48, 64] as [CGFloat], id: \.self) { sz in
                LumenMark(size: sz)
            }
        }
    }
    .padding(48)
    .background(LumenColors.ink900)
}
