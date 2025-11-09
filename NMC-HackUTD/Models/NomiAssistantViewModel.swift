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
    private var silenceTimer: Timer?
    private let silenceTimeout: TimeInterval = 3.0
    
    var liveMessageID: UUID?
    
    // Dependencies
    private let userName: String
    private let workOrderViewModel: WorkOrderViewModel

    // MARK: - Init
    init(userName: String, workOrderViewModel: WorkOrderViewModel) {
        self.userName = userName
        self.workOrderViewModel = workOrderViewModel
        showInitialGreeting()
    }

    private func showInitialGreeting() {
        let activeOrders = workOrderViewModel.activeWorkOrders

        var greeting = "Hello \(userName), my name is Nomi — your AI assistant for NMC² operations. I’m here to help you communicate hands-free and handle tasks around the data center.\n\n"

        if activeOrders.isEmpty {
            greeting += "You currently don’t have any active work orders, but I can help you review past tasks, create new ones, or assist with technical procedures whenever you’re ready."
        } else {
            let count = activeOrders.count
            let taskWord = count == 1 ? "open task" : "open tasks"
            greeting += "I see that you have \(count) \(taskWord) across your work orders. I can help you review progress, check off checklist items, or log notes on your tasks — just ask me what you'd like to do."
        }

        messages.append(ChatMessage(sender: .nomi, text: greeting))
    }


    // MARK: - Send Message
    func sendMessage(_ text: String) {
        let userText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userText.isEmpty else { return }

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
            speechRecognizer.stop()
            isListening = false

            if !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                sendMessage(transcript)
            }

            transcript = ""
            liveMessageID = nil
        } else {
            transcript = ""
            cancellables.removeAll()

            let liveMsg = ChatMessage(sender: .user, text: "")
            messages.append(liveMsg)
            liveMessageID = liveMsg.id

            speechRecognizer.$transcript
                .receive(on: RunLoop.main)
                .sink { [weak self] text in
                    guard let self else { return }
                    self.transcript = text
                    self.resetSilenceTimer()

                    if let id = self.liveMessageID,
                       let index = self.messages.firstIndex(where: { $0.id == id }) {
                        self.messages[index] = ChatMessage(id: id, sender: .user, text: text)
                    }
                }
                .store(in: &cancellables)

            do {
                try speechRecognizer.start()
                isListening = true
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
                withAnimation { self?.isSpeaking = false }
            }
        }
    }

    func stopSpeaking() {
        speechService.stop()
        isSpeaking = false
    }

    private func requestGeminiResponse(for text: String) async throws -> String {
        return try await sendToGemini(
            text,
            userName: userName,
            workOrders: workOrderViewModel.activeWorkOrders
        )
    }

    // MARK: - Silence Detection
    private func resetSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceTimeout, repeats: false) { [weak self] _ in
            guard let self else { return }

            Task { @MainActor in
                if self.isListening {
                    print("🕒 No speech detected for \(self.silenceTimeout)s — stopping listening.")
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
