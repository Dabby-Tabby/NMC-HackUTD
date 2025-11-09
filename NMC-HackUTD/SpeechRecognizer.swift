import Foundation
import Speech
import AVFoundation
import Combine

@MainActor
class SpeechRecognizer: ObservableObject {
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private let audioEngine = AVAudioEngine()
    @Published var transcript = ""

    func start() throws {
        // 1️⃣ Configure the audio session before tapping the mic
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        // 2️⃣ Reset transcript
        transcript = ""

        // 3️⃣ Prepare a new recognition request
        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request = request else { throw NSError(domain: "SpeechRecognizer", code: 1) }

        // 4️⃣ Configure audio input node
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.removeTap(onBus: 0) // important if reused
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        // 5️⃣ Start audio engine
        audioEngine.prepare()
        try audioEngine.start()

        // 6️⃣ Start recognition task
        recognizer?.recognitionTask(with: request) { result, error in
            if let result = result {
                self.transcript = result.bestTranscription.formattedString
            } else if let error = error {
                print("Speech recognition error: \(error.localizedDescription)")
            }
        }
    }

    func stop() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()

        // Optionally deactivate session
        try? AVAudioSession.sharedInstance().setActive(false)
    }
}
