import SwiftUI

/// Animated lungs that breathe (expand / contract) in sync with breaths per minute (BRPM).
/// Includes optional glow and airflow shimmer for realism.
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
            let phase = reduceMotion ? 0.0 : (t.truncatingRemainder(dividingBy: period) / period)
            let breath = reduceMotion ? 0.0 : breathingCurve(phase) // 0–1 inhale→exhale
            
            ZStack {
                // Base lungs
                lungsShape
                    .foregroundStyle(color)
                    .overlay(alignment: .center) {
                        // Subtle highlight increases with inhale
                        lungsShape
                            .foregroundStyle(.white.opacity(0.08 + 0.25 * breath))
                            .blendMode(.screen)
                    }
                    .compositingGroup()
                
                // Internal airflow shimmer
                if airflow {
                    lungsShape
                        .mask(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    .clear,
                                    .white.opacity(0.4),
                                    .clear
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .offset(y: -size * 0.8 * (reduceMotion ? 0.0 : phase))
                        )
                        .blendMode(.overlay)
                        .opacity(0.4)
                        .blur(radius: 2)
                }
                
                // Outer breathing glow
                if glow {
                    lungsShape
                        .foregroundStyle(color)
                        .blur(radius: 10 + 10 * breath)
                        .opacity(0.45 + 0.25 * breath)
                        .scaleEffect(1.1 + 0.07 * breath)
                }
            }
            // Breathing transform: gentle vertical expansion
            .scaleEffect(x: 1.0 + 0.04 * breath, y: 1.0 + 0.08 * breath, anchor: .center)
            .offset(y: -size * 0.015 * breath)
            .frame(width: size, height: size)
            .accessibilityLabel("Breathing \(Int(clampedBRPM)) breaths per minute")
        }
    }
    
    // MARK: - Helpers
    
    private var clampedBRPM: Double { min(max(brpm, 6), 30) }
    
    /// Asymmetric inhale/exhale for realism (inhale faster, exhale slower)
    private func breathingCurve(_ phase: Double) -> Double {
        let inhalePortion = 0.40
        if phase < inhalePortion {
            let p = phase / inhalePortion
            return 0.5 - 0.5 * cos(.pi * p)  // smooth up 0→1
        } else {
            let p = (phase - inhalePortion) / (1 - inhalePortion)
            let exhale = 0.5 - 0.5 * cos(.pi * (1 - p)) // smooth down 1→0
            return exhale
        }
    }
    
    private var lungsShape: some View {
        Image(systemName: "lungs.fill")
            .resizable()
            .aspectRatio(contentMode: .fit)
    }
}

#Preview {
    VStack(spacing: 28) {
        LungsBreathIcon(brpm: 10, color: Color("BabyBlue"), size: 100)
        LungsBreathIcon(brpm: 16, color: .teal, size: 80, glow: false, airflow: false)
    }
    .padding()
    .background(Color.black)
}
