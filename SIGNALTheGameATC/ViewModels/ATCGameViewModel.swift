import Foundation

@MainActor
final class ATCGameViewModel: ObservableObject {
    @Published var messages: [GameMessage] = []
    @Published var composerText = ""
    @Published var isBusy = false
    @Published var errorText: String?
    @Published var modelName: String {
        didSet { UserDefaults.standard.set(modelName, forKey: Self.modelKey) }
    }

    private let openAI = OpenAIService()
    private weak var audio: RadioAudioManager?

    private var apiTranscript: [(role: String, content: String)] = []

    private static let modelKey = "signal_openai_model"
    private static let streamKey = "signal_radio_stream_url"

    init(audio: RadioAudioManager) {
        self.audio = audio
        modelName = UserDefaults.standard.string(forKey: Self.modelKey) ?? "gpt-4o-mini"
    }

    func bindAudio(_ radio: RadioAudioManager) {
        audio = radio
        radio.applyStreamURLFromStorage(UserDefaults.standard.string(forKey: Self.streamKey))
    }

    func saveStreamURL(_ s: String) {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        UserDefaults.standard.set(t, forKey: Self.streamKey)
        audio?.applyStreamURLFromStorage(t)
    }

    func loadStreamURL() -> String {
        UserDefaults.standard.string(forKey: Self.streamKey) ?? ""
    }

    func newSimulation(apiKey: String) async {
        messages.removeAll()
        apiTranscript.removeAll()
        errorText = nil
        composerText = ""
        await appendOpening(apiKey: apiKey)
    }

    func sendPlayerTransmission(apiKey: String) async {
        let t = composerText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        composerText = ""
        messages.append(GameMessage(speaker: .atc, text: t))
        apiTranscript.append((role: "user", content: t))
        await respond(apiKey: apiKey)
    }

    private func appendOpening(apiKey: String) async {
        isBusy = true
        defer { isBusy = false }
        apiTranscript.append((role: "user", content: "NEW SIMULATION — begin cold."))
        await fetchAssistant(apiKey: apiKey)
    }

    private func respond(apiKey: String) async {
        isBusy = true
        defer { isBusy = false }
        await fetchAssistant(apiKey: apiKey)
    }

    private func fetchAssistant(apiKey: String) async {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorText = OpenAIError.missingAPIKey.localizedDescription
            return
        }
        errorText = nil
        do {
            let text = try await openAI.complete(
                apiKey: apiKey,
                model: modelName,
                system: ATCSystemPrompt.main,
                transcript: apiTranscript,
                temperature: 0.9
            )
            messages.append(GameMessage(speaker: .frequency, text: text))
            apiTranscript.append((role: "assistant", content: text))
        } catch {
            errorText = error.localizedDescription
        }
    }
}
