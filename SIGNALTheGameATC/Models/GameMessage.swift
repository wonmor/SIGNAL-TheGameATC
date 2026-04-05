import Foundation

enum RadioSpeaker: String, Codable, Sendable {
    case atc
    case frequency
    case system
}

struct GameMessage: Identifiable, Equatable, Sendable {
    let id: UUID
    let speaker: RadioSpeaker
    let text: String
    let created: Date

    init(id: UUID = UUID(), speaker: RadioSpeaker, text: String, created: Date = .now) {
        self.id = id
        self.speaker = speaker
        self.text = text
        self.created = created
    }
}
