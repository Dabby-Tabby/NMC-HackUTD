import SwiftUI

/// Solid-color heart that BEATS in sync with BPM (no rotating wave).
struct HeartBeatIcon: View {
    var bpm: Double                 // live or simulated BPM
    var color: Color = Color("DowngradeRed")         // heart fill
    var size: CGFloat = 54
    var glow: Bool = true           // breathing glow with the beat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let period = max(0.3, 60.0 / clampedBPM)                // one cycle per beat
            let phase = reduceMotion ? 0.0 : (t.truncatingRemainder(dividingBy: period) / period) // 0…1

            // Primary beat curve 0…1 (eased). Secondary (lub-dub) optional.
            let primary = pulse(phase)
            let beat = reduceMotion ? 0.0 : min(1.0, primary)

            ZStack {
                // Heart fill
                heartShape
                    .foregroundStyle(color)
                    .overlay(alignment: .center) {            // ✅ use foregroundStyle, not fill
                        heartShape
                            .foregroundStyle(.white.opacity(0.05 + 0.1 * beat))
                            .blendMode(.screen)
                    }
                    .compositingGroup()                       // ensures blend before mask if you add one later

                // Optional glow that breathes with the beat
                if glow {
                    heartShape
                        .foregroundStyle(color)
                        .blur(radius: 10 * beat)
                        .opacity(0.1 * beat)
                }
            }
            // Scale pop = the beat
            .scaleEffect(1.0 + 0.02 * beat)
            .frame(width: size, height: size)
            .accessibilityLabel("Heart rate \(Int(clampedBPM)) beats per minute")
        }
    }

    // MARK: - Utilities

    /// Cosine-based pulse: smooth rise/fall once per cycle (phase 0…1 → 0…1)
    private func pulse(_ phase: Double) -> Double {
        0.5 - 0.5 * cos(2 * .pi * phase)
    }

    /// Keep a fractional value in 0…1
    private func frac(_ x: Double) -> Double {
        let f = x.truncatingRemainder(dividingBy: 1.0)
        return f < 0 ? f + 1 : f
    }

    private var clampedBPM: Double { min(max(bpm, 40), 180) }

    private var heartShape: some View {
        Image(systemName: "heart.fill")
            .resizable()
            .aspectRatio(contentMode: .fit)
    }
}

#Preview {
    VStack(spacing: 24) {
        HeartBeatIcon(bpm: 72, size: 90)
    }
    .padding()
}
