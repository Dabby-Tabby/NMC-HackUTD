//
//  ChatMemory.swift
//  NMC-HackUTD
//
//  Created by Nick Watts on 11/9/25.
//

import Foundation
import Combine

@MainActor
class ChatMemory: ObservableObject {
    static let shared = ChatMemory()

    @Published var messages: [[String: String]] = []

    private init() {}

    func reset() {
        messages.removeAll()
    }

    func add(role: String, content: String) {
        messages.append(["role": role, "content": content])
    }

    func history() -> [[String: String]] {
        return messages
    }
}
