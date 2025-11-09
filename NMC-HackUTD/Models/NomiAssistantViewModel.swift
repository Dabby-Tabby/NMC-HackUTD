import Foundation
import Combine
import SwiftUI

@MainActor
final class NomiAssistantViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var transcript: String = ""
    @Published var isListening = false
    @Published var isSpeaking = false
    @Published var isLoading = false

    private let speechRecognizer = SpeechRecognizer()
    private let speechService = SpeechOutput.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Send Message (typed or transcribed)
    func sendMessage(_ text: String) {
        let userText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userText.isEmpty else { return }

        messages.append(ChatMessage(sender: .user, text: userText))
        isLoading = true

        Task {
            do {
                let reply = try await sendToGemini(userText)
                await MainActor.run {
                    messages.append(ChatMessage(sender: .nomi, text: reply))
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    messages.append(ChatMessage(sender: .nomi, text: "⚠️ \(error.localizedDescription)"))
                    isLoading = false
                }
            }
        }
    }

    private func sendFromTranscript() {
        let userText = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userText.isEmpty else { return }
        sendMessage(userText)
        transcript = ""
    }

    func toggleListening() {
        if isListening {
            speechRecognizer.stop()
            isListening = false
            transcript = speechRecognizer.transcript
            sendFromTranscript()
        } else {
            transcript = ""
            speechRecognizer.$transcript
                .receive(on: RunLoop.main)
                .assign(to: \.transcript, on: self)
                .store(in: &cancellables)

            try? speechRecognizer.start()
            isListening = true
        }
    }

    func speak(_ text: String) {
        guard !text.isEmpty else { return }
        isSpeaking = true
        speechService.speak(text) { [weak self] in
            Task { @MainActor in
                withAnimation {
                    self?.isSpeaking = false
                }
            }
        }
    }

    func stopSpeaking() {
        speechService.stop()
        isSpeaking = false
    }

    private func sendToGemini(_ input: String) async throws -> String {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        return "Response to: \(input)"
    }
}
