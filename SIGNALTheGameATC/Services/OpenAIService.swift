import Foundation

struct OpenAIChatRequest: Encodable {
    struct Message: Encodable {
        let role: String
        let content: String
    }
    let model: String
    let messages: [Message]
    let temperature: Double
}

struct OpenAIChatResponse: Decodable {
    struct Choice: Decodable {
        struct Msg: Decodable {
            let role: String?
            let content: String?
        }
        let message: Msg?
    }
    let choices: [Choice]?
}

enum OpenAIError: LocalizedError {
    case missingAPIKey
    case badStatus(Int, String)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Add an OpenAI API key in Settings."
        case let .badStatus(code, body):
            return "OpenAI error (\(code)): \(body)"
        case .emptyResponse:
            return "No message returned from the model."
        }
    }
}

actor OpenAIService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func complete(
        apiKey: String,
        model: String,
        system: String,
        transcript: [(role: String, content: String)],
        temperature: Double = 0.85
    ) async throws -> String {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw OpenAIError.missingAPIKey
        }
        var messages: [OpenAIChatRequest.Message] = [
            .init(role: "system", content: system)
        ]
        for row in transcript {
            messages.append(.init(role: row.role, content: row.content))
        }
        let body = OpenAIChatRequest(model: model, messages: messages, temperature: temperature)
        let data = try JSONEncoder().encode(body)
        var req = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        req.httpMethod = "POST"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = data

        let (respData, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw OpenAIError.badStatus(-1, "No HTTP response")
        }
        let text = String(data: respData, encoding: .utf8) ?? ""
        guard (200 ... 299).contains(http.statusCode) else {
            throw OpenAIError.badStatus(http.statusCode, text)
        }
        let decoded = try JSONDecoder().decode(OpenAIChatResponse.self, from: respData)
        let out = decoded.choices?.first?.message?.content?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !out.isEmpty else { throw OpenAIError.emptyResponse }
        return out
    }
}
