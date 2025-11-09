//
//  GeminiAPI.swift
//  NMC-HackUTD
//

import Foundation

func sendToGemini(_ userText: String) async throws -> String {
    let apiKey = ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"] ?? ""
    guard !apiKey.isEmpty else {
        throw URLError(.userAuthenticationRequired)
    }

    guard let url = URL(string: "https://openrouter.ai/api/v1/chat/completions") else {
        throw URLError(.badURL)
    }

    let model = "google/gemini-2.5-flash-lite"

    let systemPrompt = """
    You are Nomi, an AI assistant supporting NMC² data center technicians who work in loud, high-heat environments with limited visual communication.

    Your goals:
    - Respond in clear, spoken-friendly messages of about 2–5 sentences.
    - Provide practical and context-aware answers that technicians can follow without visual aids.
    - Be concise but not abrupt—give enough detail to complete a task or understand the issue.
    - Only include a safety warning when there is a genuine physical or electrical hazard.
    - Use step-by-step guidance only when the situation requires it (up to 3 short steps).
    - If more explanation may help, summarize key points first and then ask, “Would you like me to explain further?”
    - Stay focused on hardware, cabling, servers, diagnostics, safety, and workflow—not unrelated topics.
    - Maintain a calm, professional, and helpful tone suitable for spoken playback.

    When a user greets you (e.g. “hi”, “hello”, “good morning”), respond with a short, friendly greeting followed by a one-sentence summary of your role, for example:
    “Hi there, I’m Nomi, your AI assistant for NMC² operations. I’m here to help you communicate hands-free and handle tasks around the data center.”

    Always keep responses natural, spoken-friendly, and brief unless the user explicitly asks for more detail.
    """


    // 🧠 Get shared memory instance
    let memory = ChatMemory.shared

    // Add the new user message
    memory.add(role: "user", content: userText)

    // Build the message list with history (system prompt first)
    var messages: [[String: String]] = [["role": "system", "content": systemPrompt]]
    messages.append(contentsOf: memory.history())

    // Request body
    let body: [String: Any] = [
        "model": model,
        "messages": messages,
        "max_tokens": 150,
        "temperature": 0.7
    ]

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    request.httpBody = try JSONSerialization.data(withJSONObject: body)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
        throw URLError(.badServerResponse)
    }

    guard httpResponse.statusCode == 200 else {
        let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
        print("❌ OpenRouter error (\(httpResponse.statusCode)):", errorMsg)
        throw URLError(.badServerResponse)
    }

    let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
    if let choices = json["choices"] as? [[String: Any]],
       let message = choices.first?["message"] as? [String: Any],
       var content = message["content"] as? String {

        // ✂️ Limit overly long replies (sentence-aware)
        let maxWords = 70
        let words = content.split(separator: " ")
        if words.count > maxWords {
            // Find the cutoff index
            let limitedText = words.prefix(maxWords).joined(separator: " ")

            // Try to cut cleanly at the last sentence-ending punctuation
            if let range = limitedText.range(of: "[.!?](\\s|$)", options: .regularExpression) {
                let cutoffIndex = limitedText.index(after: range.upperBound)
                content = String(limitedText[..<cutoffIndex])
            } else {
                content = limitedText
            }

            // Avoid duplicating the follow-up phrase
            let followUpPrompt = "Would you like me to explain further?"
            if !content.lowercased().contains(followUpPrompt.lowercased()) {
                if !content.trimmingCharacters(in: .whitespacesAndNewlines).hasSuffix(".") {
                    content += "."
                }
                content += " \(followUpPrompt)"
            }
        }


        // 🧠 Save Nomi's reply into history
        memory.add(role: "assistant", content: content)

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    return "No reply"
}
