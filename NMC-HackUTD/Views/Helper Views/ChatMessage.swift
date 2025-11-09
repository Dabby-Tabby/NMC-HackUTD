import Foundation

struct ChatMessage: Identifiable {
    let id = UUID()
    let sender: Sender
    let text: String

    enum Sender {
        case user, nomi
    }
}
