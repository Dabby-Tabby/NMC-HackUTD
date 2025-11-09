//
//  GeminiAPI.swift
//  NMC-HackUTD
//

import Foundation

func sendToGemini(
    _ userText: String,
    userName: String,
    workOrders: [WorkOrder]
) async throws -> String {
    let apiKey = ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"] ?? ""
    guard !apiKey.isEmpty else { throw URLError(.userAuthenticationRequired) }

    guard let url = URL(string: "https://openrouter.ai/api/v1/chat/completions") else {
        throw URLError(.badURL)
    }

    let model = "google/gemini-2.5-flash-lite"

    // 🔍 Build context from relevant work orders
    let relevantOrders = workOrders.filter { order in
        order.assignedTo?.localizedCaseInsensitiveContains(userName) == true ||
        order.ownerName.localizedCaseInsensitiveContains(userName)
    }

    let contextSummary: String
    if relevantOrders.isEmpty {
        contextSummary = "There are currently no open tasks assigned to \(userName)."
    } else {
        let summaries = relevantOrders.prefix(5).map { order in
            """
            - \(order.title) [Priority: \(order.priority.rawValue.capitalized), Status: \(order.status.rawValue.capitalized)]
              Location: \(order.location)
              Description: \(order.description.replacingOccurrences(of: "\n", with: " "))
            """
        }.joined(separator: "\n")
        contextSummary = "Here are \(relevantOrders.count) open tasks for \(userName):\n\(summaries)"
    }

    // 🧠 Compose system prompt
    let systemPrompt = """
    You are Nomi, an AI assistant supporting NMC² data center technicians who work in loud, high-heat environments with limited visual communication.

    The current user is \(userName).

    Their current task context:
    \(contextSummary)

    Your goals:
    - Respond in clear, spoken-friendly messages of about 2–5 sentences.
    - Provide practical and context-aware answers that technicians can follow without visual aids.
    - When referring to tasks, prioritize the user's own open work orders but provide context and help for other tasks if the user does not own any open work orders or requests to see.
    - Be concise but not abrupt—give enough detail to complete a task or understand the issue.
    - Only include a safety warning when there is a genuine physical or electrical hazard.
    - Use step-by-step guidance only when the situation requires it (up to 3 short steps).
    - If more explanation may help, summarize key points first and then ask, “Would you like me to explain further?”
    - Stay focused on hardware, cabling, servers, diagnostics, safety, and workflow—not unrelated topics.
    - Maintain a calm, professional, and helpful tone suitable for spoken playback.

    "When the user greets you, respond warmly and acknowledge them, but do not introduce yourself again."

    Always keep responses natural, spoken-friendly, and brief unless the user explicitly asks for more detail.
    """
    
    let memory = ChatMemory.shared
    memory.add(role: "user", content: userText)

    var messages: [[String: String]] = [["role": "system", "content": systemPrompt]]
    messages.append(contentsOf: memory.history())

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
    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
        throw URLError(.badServerResponse)
    }

    let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
    if let choices = json["choices"] as? [[String: Any]],
       let message = choices.first?["message"] as? [String: Any],
       let content = message["content"] as? String {
        memory.add(role: "assistant", content: content)
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    return "No reply"
}
