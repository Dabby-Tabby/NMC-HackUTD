import SwiftUI
import Combine

struct VoiceChatView: View {
    @StateObject var speech = SpeechRecognizer()
    @State private var response = ""
    @State private var isListening = false

    var body: some View {
        VStack(spacing: 30) {
            Text("🎧 Gemini Assistant")
                .font(.largeTitle.bold())

            Text(speech.transcript.isEmpty ? "Press and speak..." : speech.transcript)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial)
                .cornerRadius(12)

            if !response.isEmpty {
                Text("Gemini: \(response)")
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
            }

            Button {
                if isListening {
                    speech.stop()
                    Task {
                        do {
                            let reply = try await sendToGemini(speech.transcript)
                            response = reply
                            speak(reply)
                        } catch {
                            response = "Error: \(error.localizedDescription)"
                        }
                    }
                } else {
                    try? speech.start()
                }
                isListening.toggle()
            } label: {
                Label(isListening ? "Stop & Send" : "Start Listening",
                      systemImage: isListening ? "stop.circle.fill" : "mic.circle.fill")
                    .font(.title2.bold())
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(isListening ? Color.red : Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .shadow(radius: 5)
            }
        }
        .padding()
        .animation(.spring(), value: isListening)
    }
}
