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
    
    var liveMessageID: UUID?
    
    private var silenceTimer: Timer?
    private let silenceTimeout: TimeInterval = 3.0 // ⏱ adjust as needed (seconds)

    // MARK: - Send Message (typed or transcribed)
    func sendMessage(_ text: String) {
        let userText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userText.isEmpty else { return }

        // Remove any temporary live bubble before sending the real one
        if let id = liveMessageID {
            messages.removeAll { $0.id == id }
            liveMessageID = nil
        }

        messages.append(ChatMessage(sender: .user, text: userText))
        isLoading = true

        Task {
            do {
                let reply = try await requestGeminiResponse(for: userText)
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

    // MARK: - Toggle Listening
    func toggleListening() {
        if isListening {
            // 🛑 Stop listening and capture the final transcript
            speechRecognizer.stop()
            isListening = false

            if !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                sendMessage(transcript)
            }

            transcript = ""
            liveMessageID = nil
        } else {
            // 🎙️ Start live speech recognition
            transcript = ""
            cancellables.removeAll()

            // 🟡 Show immediate "Listening..." feedback
            let liveMsg = ChatMessage(sender: .user, text: "Listening...")
            messages.append(liveMsg)
            liveMessageID = liveMsg.id
            isListening = true  // ✅ Mark as listening *before* engine starts

            // Animate UI right away
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.easeIn(duration: 0.2)) {
                    self.isListening = true
                }
            }

            // Set up live transcript updates
            speechRecognizer.$transcript
                .receive(on: RunLoop.main)
                .sink { [weak self] text in
                    guard let self else { return }
                    self.transcript = text
                    self.resetSilenceTimer()

                    // Update live message text
                    if let id = self.liveMessageID,
                       let index = self.messages.firstIndex(where: { $0.id == id }) {
                        self.messages[index] = ChatMessage(id: id, sender: .user, text: text.isEmpty ? "Listening..." : text)
                    }
                }
                .store(in: &cancellables)

            do {
                try speechRecognizer.start()
            } catch {
                print("Speech recognition start error: \(error.localizedDescription)")
                isListening = false
            }
        }
    }

    // MARK: - Speech Output
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

    // MARK: - Gemini API
    private func requestGeminiResponse(for text: String) async throws -> String {
        return try await sendToGemini(text)
    }
    
    // MARK: - Silence Detection
    private func resetSilenceTimer() {
        // Cancel any existing timer
        silenceTimer?.invalidate()

        // Start a new timer
        silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceTimeout, repeats: false) { [weak self] _ in
            guard let self else { return }

            // 🧭 Hop back to MainActor safely
            Task { @MainActor in
                // Check: only stop if still listening
                if self.isListening {
                    print("🕒 No speech detected for \(self.silenceTimeout)s — stopping listening.")
                    self.silenceTimer?.invalidate()
                    self.silenceTimer = nil

                    // Stop listening gracefully
                    self.speechRecognizer.stop()
                    self.isListening = false

                    let finalText = self.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !finalText.isEmpty {
                        self.sendMessage(finalText)
                    }

                    self.transcript = ""
                    self.liveMessageID = nil
                }
            }
        }
    }
}
