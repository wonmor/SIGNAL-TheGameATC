import SwiftUI

/// Stylized “sectional‑adjacent” radar — not a real Nav Canada chart. Approximate Toronto YYZ / lake geometry for atmosphere only.
struct TorontoRadarView: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: false)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                drawGrid(context: context, size: size)
                drawLake(context: context, size: size)
                drawLandmarks(context: context, size: size)
                drawTracks(context: context, size: size, t: t)
                drawSweep(context: context, size: size, t: t)
                drawGlass(context: context, size: size, t: t)
            }
            .background(
                LinearGradient(
                    colors: [Color(red: 0.02, green: 0.06, blue: 0.04), Color(red: 0.01, green: 0.03, blue: 0.02)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.green.opacity(0.35), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .accessibilityLabel("Toronto approach radar schematic, stylized")
    }

    private func drawGrid(context: GraphicsContext, size: CGSize) {
        let step: CGFloat = 22
        var p = Path()
        stride(from: 0, through: size.width, by: step).forEach { x in
            p.move(to: CGPoint(x: x, y: 0))
            p.addLine(to: CGPoint(x: x, y: size.height))
        }
        stride(from: 0, through: size.height, by: step).forEach { y in
            p.move(to: CGPoint(x: 0, y: y))
            p.addLine(to: CGPoint(x: size.width, y: y))
        }
        context.stroke(p, with: .color(Color.green.opacity(0.12)), lineWidth: 0.7)

        let rings = Path { path in
            for r in stride(from: CGFloat(40), through: min(size.width, size.height) * 0.45, by: 36) {
                path.addEllipse(in: CGRect(x: size.width * 0.52 - r, y: size.height * 0.42 - r, width: r * 2, height: r * 2))
            }
        }
        context.stroke(rings, with: .color(Color.green.opacity(0.10)), lineWidth: 0.6)
    }

    private func drawLake(context: GraphicsContext, size: CGSize) {
        var lake = Path()
        lake.move(to: CGPoint(x: size.width * 0.02, y: size.height * 0.58))
        lake.addQuadCurve(
            to: CGPoint(x: size.width * 0.98, y: size.height * 0.62),
            control: CGPoint(x: size.width * 0.55, y: size.height * 1.02)
        )
        lake.addLine(to: CGPoint(x: size.width * 0.98, y: size.height * 1.02))
        lake.addLine(to: CGPoint(x: size.width * 0.02, y: size.height * 1.02))
        lake.closeSubpath()
        context.fill(lake, with: .color(Color(red: 0.02, green: 0.12, blue: 0.18).opacity(0.85)))
        context.stroke(lake, with: .color(Color.cyan.opacity(0.25)), lineWidth: 0.8)

        let label = Text("LAKE ONTARIO")
            .font(.system(size: 9, weight: .semibold, design: .monospaced))
            .foregroundStyle(Color.cyan.opacity(0.5))
        context.draw(label, at: CGPoint(x: size.width * 0.72, y: size.height * 0.86), anchor: .center)
    }

    private func drawLandmarks(context: GraphicsContext, size: CGSize) {
        drawAirport(code: "CYYZ", at: CGPoint(x: size.width * 0.38, y: size.height * 0.35), context: context)
        drawAirport(code: "CYTZ", at: CGPoint(x: size.width * 0.62, y: size.height * 0.48), context: context)

        let tower = Path { p in
            let c = CGPoint(x: size.width * 0.58, y: size.height * 0.22)
            p.addEllipse(in: CGRect(x: c.x - 4, y: c.y - 4, width: 8, height: 8))
            p.move(to: CGPoint(x: c.x, y: c.y + 4))
            p.addLine(to: CGPoint(x: c.x, y: c.y + 18))
        }
        context.stroke(tower, with: .color(Color.red.opacity(0.55)), lineWidth: 1.2)
        let tlab = Text("CN TWR")
            .font(.system(size: 8, weight: .bold, design: .monospaced))
            .foregroundStyle(Color.red.opacity(0.65))
        context.draw(tlab, at: CGPoint(x: size.width * 0.58, y: size.height * 0.10), anchor: .center)

        let warn = Text("CLASS C / PROX")
            .font(.system(size: 8, weight: .medium, design: .monospaced))
            .foregroundStyle(Color.orange.opacity(0.45))
        context.draw(warn, at: CGPoint(x: size.width * 0.22, y: size.height * 0.14), anchor: .center)
    }

    private func drawAirport(code: String, at point: CGPoint, context: GraphicsContext) {
        var rh = Path()
        rh.move(to: CGPoint(x: point.x - 14, y: point.y))
        rh.addLine(to: CGPoint(x: point.x + 14, y: point.y))
        rh.move(to: CGPoint(x: point.x, y: point.y - 10))
        rh.addLine(to: CGPoint(x: point.x, y: point.y + 10))
        context.stroke(rh, with: .color(Color.green.opacity(0.55)), lineWidth: 1)
        let tx = Text(code)
            .font(.system(size: 9, weight: .semibold, design: .monospaced))
            .foregroundStyle(Color.green.opacity(0.7))
        context.draw(tx, at: CGPoint(x: point.x, y: point.y - 22), anchor: .center)
    }

    private func drawTracks(context: GraphicsContext, size: CGSize, t: TimeInterval) {
        let phase = CGFloat(t.truncatingRemainder(dividingBy: 80) / 80)
        var p = Path()
        let start = CGPoint(x: size.width * (0.1 + phase * 0.05), y: size.height * 0.08)
        let bend = CGPoint(x: size.width * 0.48, y: size.height * 0.32)
        let end = CGPoint(x: size.width * 0.62, y: size.height * (0.52 + sin(t) * 0.02))
        p.move(to: start)
        p.addQuadCurve(to: end, control: bend)
        context.stroke(
            p,
            with: .linearGradient(
                Gradient(colors: [Color.red.opacity(0), Color.red.opacity(0.55), Color.orange.opacity(0.2)]),
                startPoint: start,
                endPoint: end
            ),
            style: StrokeStyle(lineWidth: 2, dash: [6, 10])
        )

        let blip = CGPoint(x: end.x + CGFloat(sin(t * 1.7)) * 4, y: end.y)
        context.fill(
            Path(ellipseIn: CGRect(x: blip.x - 3, y: blip.y - 3, width: 6, height: 6)),
            with: .color(Color.white.opacity(0.85))
        )
        let cs = Text("DELVE123")
            .font(.system(size: 8, weight: .heavy, design: .monospaced))
            .foregroundStyle(Color.white.opacity(0.9))
        context.draw(cs, at: CGPoint(x: blip.x + 28, y: blip.y - 10), anchor: .center)
    }

    private func drawSweep(context: GraphicsContext, size: CGSize, t: TimeInterval) {
        let angle = (t.truncatingRemainder(dividingBy: 6) / 6) * Double.pi * 2
        let c = CGPoint(x: size.width * 0.52, y: size.height * 0.42)
        let len = max(size.width, size.height)
        let end = CGPoint(x: c.x + CGFloat(cos(angle)) * len, y: c.y + CGFloat(sin(angle)) * len)
        var beam = Path()
        beam.move(to: c)
        beam.addLine(to: end)
        context.stroke(beam, with: .color(Color.green.opacity(0.15)), lineWidth: 10)
        context.stroke(beam, with: .color(Color.green.opacity(0.35)), lineWidth: 1)
    }

    private func drawGlass(context: GraphicsContext, size: CGSize, t: TimeInterval) {
        let flicker = 0.03 + 0.02 * CGFloat(sin(t * 7))
        context.fill(
            Rectangle().path(in: CGRect(origin: .zero, size: size)),
            with: .color(Color.black.opacity(flicker))
        )

        let noiseCount = 120
        for i in 0 ..< noiseCount {
            let x = CGFloat((i * 47 + Int(t * 1000)) % Int(size.width))
            let y = CGFloat((i * 91) % Int(size.height))
            let r = CGRect(x: x, y: y, width: 1, height: 1)
            context.fill(Path(ellipseIn: r), with: .color(Color.white.opacity(Double.random(in: 0.01 ... 0.06))))
        }
    }
}

#Preview {
    TorontoRadarView()
        .frame(height: 240)
        .padding()
        .background(Color.black)
}
