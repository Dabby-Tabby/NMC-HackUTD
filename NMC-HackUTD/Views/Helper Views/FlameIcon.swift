import SwiftUI

/// Solid-color flame that beats in sync with BPM (no rotating wave).
struct FlameBeatIcon: View {
    var bpm: Double                 // live or simulated BPM
    var color: Color = .orange      // flame fill
    var size: CGFloat = 54
    var glow: Bool = true           // breathing glow with the beat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let period = max(0.3, 60.0 / clampedBPM) // one cycle per beat
            let phase = reduceMotion ? 0.0 : (t.truncatingRemainder(dividingBy: period) / period) // 0…1
            let beat  = reduceMotion ? 0.0 : (0.5 - 0.5 * cos(2 * .pi * phase)) // eased 0…1

            ZStack {
                // Flame fill
                flameShape
                    .foregroundStyle(color)
                    .overlay {
                        // subtle brighten on beat
                        flameShape
                            .foregroundStyle(.white.opacity(0.12 + 0.28 * beat))
                            .blendMode(.screen)
                    }
                    .compositingGroup()

                // Optional glow that breathes with the beat
                if glow {
                    flameShape
                        .foregroundStyle(color)
                        .blur(radius: 10 * beat)
                        .opacity(0.45 * beat)
                }
            }
            .scaleEffect(1.0 + 0.10 * beat) // beat pop
            .frame(width: size, height: size)
            .accessibilityLabel("Flame pulsing at \(Int(clampedBPM)) BPM")
        }
    }

    private var clampedBPM: Double { min(max(bpm, 40), 180) }

    private var flameShape: some View {
        Image(systemName: "flame.fill")
            .resizable()
            .aspectRatio(contentMode: .fit)
    }
}

#Preview {
    VStack(spacing: 24) {
        FlameBeatIcon(bpm: 72, size: 90)
    }
    .padding()
}
