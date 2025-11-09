import Foundation

struct ChatMessage: Identifiable {
    let id: UUID
    let sender: Sender
    let text: String

    enum Sender {
        case user, nomi
    }

    // Custom init allows keeping the same ID
    init(id: UUID = UUID(), sender: Sender, text: String) {
        self.id = id
        self.sender = sender
        self.text = text
    }
}
