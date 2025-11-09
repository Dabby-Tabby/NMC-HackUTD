import Foundation

func sendToGemini(_ userText: String) async throws -> String {
    // Your OpenRouter API key (keep private!)
    let apiKey = ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"] ?? ""

    // OpenRouter endpoint
    guard let url = URL(string: "https://openrouter.ai/api/v1/chat/completions") else {
        throw URLError(.badURL)
    }

    // Model you want to use (check openrouter.ai/models)
    let model = "google/gemini-2.5-flash-lite"


    // Build the message list
    let systemPrompt = """
    You are , an AI assistant built to support data center technicians working in loud, high-heat environments where voice and visual communication are limited.

    Your responsibilities:
    • Help technicians troubleshoot hardware, power, cabling, and server issues.
    • Provide concise, spoken-friendly answers (max 3 sentences unless a procedure requires steps).
    • Use clear, calm, direct language suitable for voice playback — avoid unnecessary filler.
    • If a procedure involves safety risk (power, thermal, lifting), start with a short safety warning.
    • If a question involves workflow, Jira, or parts, give practical next steps or checklists.
    • When describing procedures, give step-by-step instructions.
    • If the technician’s question lacks detail, ask for clarification rather than guessing.
    • You are assisting NMC² data center staff who work around high-performance compute clusters and enterprise racks.
    • Avoid speculation about unrelated topics; focus only on data center operations, safety, or workflow.

    Example behaviors:
    - If asked “Rack 12B’s blade won’t power on,” reply with 2–3 likely causes and checks.
    - If asked “Where can I find spare SFP modules?” explain inventory policy or standard location.
    - If asked “How do I unseat a node safely?” describe ESD precautions and locking tabs.

    Always keep your tone: professional, calm, helpful, and operations-focused.
    """


    let body: [String: Any] = [
        "model": model,
        "messages": [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": userText]
        ]
    ]

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    request.httpBody = try JSONSerialization.data(withJSONObject: body)

    let (data, response) = try await URLSession.shared.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
        let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
        print("❌ OpenRouter error:", errorMessage)
        throw URLError(.badServerResponse)
    }

    // Parse the JSON
    let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
    if let choices = json["choices"] as? [[String: Any]],
       let message = choices.first?["message"] as? [String: Any],
       let content = message["content"] as? String {
        return content
    }

    return "No reply"
}
