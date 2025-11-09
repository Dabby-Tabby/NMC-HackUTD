import Foundation
import Combine
import SwiftUI

@MainActor
final class BuddyViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var transcript: String = ""       // 🆕 needed for live speech updates
    @Published var isListening = false
    @Published var isSpeaking = false
    @Published var isLoading = false

    private let speechRecognizer = SpeechRecognizer()
    private let speechService = SpeechOutput.shared

    // MARK: - Toggle Listening
    func toggleListening() {
        if isListening {
            // 🛑 Stop and capture the last transcript
            speechRecognizer.stop()
            transcript = speechRecognizer.transcript
            isListening = false
            sendToNomi()
        } else {
            // 🎙 Start listening and show live transcript
            transcript = ""
            speechRecognizer.$transcript
                .receive(on: RunLoop.main)
                .assign(to: &$transcript) // 👈 auto-sync transcript to @Published var
            try? speechRecognizer.start()
            isListening = true
        }
    }

    // MARK: - Send to Gemini / Nomi AI
    private func sendToNomi() {
        let userText = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userText.isEmpty else { return }

        messages.append(ChatMessage(sender: .user, text: userText))
        isLoading = true

        Task {
            do {
                let reply = try await sendToGemini(userText)
                await MainActor.run {
                    messages.append(ChatMessage(sender: .nomi, text: reply))
                    isLoading = false
                    speak(reply)
                }
            } catch {
                await MainActor.run {
                    messages.append(ChatMessage(sender: .nomi, text: "⚠️ \(error.localizedDescription)"))
                    isLoading = false
                }
            }
        }
    }

    // MARK: - Speech Output
    func speak(_ text: String) {
        isSpeaking = true
        speechService.speak(text) { [weak self] in
            guard let self else { return }
            withAnimation {
                self.isSpeaking = false
            }
        }
    }

    func stopSpeaking() {
        speechService.stop()
        isSpeaking = false
    }
}
