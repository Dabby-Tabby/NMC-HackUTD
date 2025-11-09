import SwiftUI

/// Lungs that breathe (expand/contract) in sync with BRPM.
/// Similar structure to HeartBeatIcon.
struct LungsBreathIcon: View {
    var brpm: Double = 12            // breaths per minute (live or simulated)
    var color: Color = .teal         // lung fill color
    var size: CGFloat = 64
    var glow: Bool = true            // soft outer glow with the breath
    var airflow: Bool = true         // subtle internal airflow shimmer

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let period = max(0.8, 60.0 / clampedBRPM)     // one inhale+exhale cycle
            let phase = reduceMotion ? 0.0 : (t.truncatingRemainder(dividingBy: period) / period) // 0…1

            // Breathing curve 0…1 (0=exhale, 1=inhale). Slightly longer exhale for realism.
            let breath = reduceMotion ? 0.0 : breathingCurve(phase)

            ZStack {
                // Base lungs fill
                lungsShape
                    .foregroundStyle(color)
                    .overlay(alignment: .center) {
                        // Subtle highlight increases with inhale
                        lungsShape
                            .foregroundStyle(.white.opacity(0.10 + 0.25 * breath))
                            .blendMode(.screen)
                    }
                    .compositingGroup()

                // Internal airflow shimmer (gentle, vertical)
                

                // Optional glow that breathes
                if glow {
                    lungsShape
                        .foregroundStyle(color)
                        .blur(radius: 12 * breath)
                        .opacity(0.45 * breath)
                }
            }
            // Breathing transforms: expand more vertically than horizontally
            .scaleEffect(x: 1.0 + 0.05 * breath, y: 1.0 + 0.10 * breath, anchor: .center)
            .offset(y: -size * 0.015 * breath) // tiny rise on inhale
            .frame(width: size, height: size)
            .accessibilityLabel("Breathing \(Int(clampedBRPM)) breaths per minute")
        }
    }

    // MARK: - Helpers

    private var clampedBRPM: Double { min(max(brpm, 6), 30) }

    /// Asymmetric inhale/exhale: ~40% inhale (faster), ~60% exhale (slower).
    /// Maps phase 0…1 → 0…1 (exhale→inhale), smoothly.
    private func breathingCurve(_ phase: Double) -> Double {
        let inhalePortion = 0.40
        if phase < inhalePortion {
            // Faster ease-in-out inhale
            let p = phase / inhalePortion
            return 0.5 - 0.5 * cos(.pi * p)               // smooth up 0→1
        } else {
            // Slower ease-out exhale
            let p = (phase - inhalePortion) / (1 - inhalePortion)
            let exhale = 0.5 - 0.5 * cos(.pi * (1 - p))   // 1→0 smoothly
            return exhale
        }
    }

    private var lungsShape: some View {
        Image(systemName: "lungs.fill")   // SF Symbol
            .resizable()
            .aspectRatio(contentMode: .fit)
    }
}

#Preview {
    VStack(spacing: 28) {
        LungsBreathIcon(brpm: 10, size: 90)
    }
    .padding()
}
