//
//  OpenAIService.swift
//  Tech.AI
//
//  Networking layer for streaming chat completions from OpenAI via
//  Server-Sent Events (SSE). Knows nothing about SwiftUI.
//

import Foundation

// Abstraction so the view model can be tested with a mock stream
// instead of hitting the real API.
protocol AIStreaming: Sendable {
    func streamAIResponse(history: [[String: String]]) -> AsyncThrowingStream<String, Error>
}

// Errors surfaced by the networking layer.
enum OpenAIError: LocalizedError {
    case badURL
    case badStatus(Int)
    case apiError(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .badURL:
            return "The request URL was invalid."
        case .badStatus(let code):
            return "The server returned an unexpected status code (\(code))."
        case .apiError(let statusCode, let message):
            return "OpenAI returned status code \(statusCode): \(message)"
        }
    }
}

// One parsed Server-Sent Event line.
enum SSEEvent: Equatable {
    case delta(String)   // a chunk of assistant text
    case done            // the "[DONE]" terminator
    case ignore          // keep-alive / non-content line
}

struct OpenAIService: AIStreaming {

    private let endpoint = "https://api.openai.com/v1/chat/completions"

    // Streams assistant text deltas as they arrive from the model.
    func streamAIResponse(history: [[String: String]]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let request = try makeRequest(history: history)
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)

                    guard let http = response as? HTTPURLResponse else {
                        throw OpenAIError.badStatus(-1)
                    }
                    guard (200..<300).contains(http.statusCode) else {
                        let message = try await OpenAIService.readErrorMessage(from: bytes)
                        throw OpenAIError.apiError(
                            statusCode: http.statusCode,
                            message: message ?? "No error details were returned."
                        )
                    }

                    for try await line in bytes.lines {
                        switch OpenAIService.parseSSELine(line) {
                        case .delta(let content):
                            continuation.yield(content)
                        case .done:
                            continuation.finish()
                            return
                        case .ignore:
                            continue
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }   // enables cancel later
        }
    }

    // Builds the POST request with the streaming flag set.
    private func makeRequest(history: [[String: String]]) throws -> URLRequest {
        guard let url = URL(string: endpoint) else {
            throw OpenAIError.badURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(AppConfig.openAIAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "gpt-5.5",
            "messages": history,
            "stream": true
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    // Parses a single SSE line into an event. Extracted as a pure,
    // static function so it can be unit-tested in isolation.
    static func parseSSELine(_ line: String) -> SSEEvent {
        guard line.hasPrefix("data: ") else { return .ignore }
        let payload = line.dropFirst(6)          // strip "data: "
        if payload == "[DONE]" { return .done }

        guard let data = payload.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let delta = choices.first?["delta"] as? [String: Any],
              let content = delta["content"] as? String else {
            return .ignore
        }
        return .delta(content)
    }

    private static func readErrorMessage(from bytes: URLSession.AsyncBytes) async throws -> String? {
        var lines: [String] = []
        for try await line in bytes.lines {
            lines.append(line)
        }

        let body = lines.joined(separator: "\n")
        guard !body.isEmpty else { return nil }

        if let data = body.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let error = json["error"] as? [String: Any],
           let message = error["message"] as? String {
            return message
        }

        return body
    }
}
