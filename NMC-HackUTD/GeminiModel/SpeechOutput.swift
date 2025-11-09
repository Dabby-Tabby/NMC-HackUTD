import AVFoundation
import Foundation

@MainActor
final class SpeechOutput: NSObject, AVSpeechSynthesizerDelegate, @unchecked Sendable {
    static let shared = SpeechOutput()
    
    private let synthesizer = AVSpeechSynthesizer()
    private var onFinish: (() -> Void)?

    private override init() {
        super.init()
        synthesizer.delegate = self
    }

    /// Speaks text aloud using the system voice.
    func speak(_ text: String, onFinish: (() -> Void)? = nil) {
        self.onFinish = onFinish
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.Samantha")
            ?? AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.45
        utterance.pitchMultiplier = 1.15
        utterance.volume = 1.0
        
        synthesizer.speak(utterance)
    }

    /// Stops any ongoing speech immediately.
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        onFinish?()
    }

    // Delegate method — bounce back to main actor safely
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                       didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.onFinish?()
        }
    }
}
